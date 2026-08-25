"use strict";

const {setGlobalOptions} = require("firebase-functions/v2");
const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {
  FieldValue,
  getFirestore,
} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

setGlobalOptions({
  region: "asia-southeast1",
  maxInstances: 10,
});

const firestore = getFirestore();
const messaging = getMessaging();

const invalidTokenCodes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

function textValue(value, fallback = "") {
  if (value === null || value === undefined) {
    return fallback;
  }

  const text = String(value).trim();
  return text.length > 0 ? text : fallback;
}

function safeDocumentPart(value) {
  return textValue(value, "event")
      .replace(/[^a-zA-Z0-9_-]/g, "_")
      .slice(0, 240);
}

function timestampChanged(beforeValue, afterValue) {
  if (!afterValue) {
    return false;
  }

  if (!beforeValue) {
    return true;
  }

  if (typeof beforeValue.isEqual === "function") {
    return !beforeValue.isEqual(afterValue);
  }

  return String(beforeValue) !== String(afterValue);
}

function pushData(notificationId, data, extraData = {}) {
  const output = {
    notificationId,
  };

  const supportedFields = [
    "type",
    "status",
    "orderId",
    "stockId",
    "requestId",
    "applicationId",
    "subjectId",
    "stockStatus",
    "severity",
  ];

  for (const field of supportedFields) {
    const value = textValue(data[field]);

    if (value.length > 0) {
      output[field] = value;
    }
  }

  for (const [field, value] of Object.entries(extraData)) {
    const text = textValue(value);

    if (text.length > 0) {
      output[field] = text;
    }
  }

  return output;
}

function notificationRoute(type) {
  switch (type) {
    case "new_order":
      return "supplier_orders";
    case "order_status":
      return "vendor_orders";
    case "stock_alert":
      return "supplier_stock";
    case "admin_supplier_application":
      return "admin_supplier_applications";
    case "admin_supplier_change_request":
      return "admin_supplier_change_requests";
    case "supplier_profile_change":
      return "supplier_profile";
    case "supplier_application_status":
      return "supplier_application";
    default:
      return "home";
  }
}

function notificationGroup(type, data) {
  switch (type) {
    case "new_order":
      return "new_orders";
    case "order_status":
      return "order_updates";
    case "stock_alert":
      return "stock_alerts";
    case "admin_supplier_application":
      return "supplier_applications";
    case "admin_supplier_change_request":
      return "supplier_change_requests";
    case "supplier_profile_change":
    case "supplier_application_status":
      return "account_updates";
    default:
      return safeDocumentPart(
          textValue(data.subjectId, textValue(data.orderId, type)),
      );
  }
}

function groupedTitle(type, countLabel, fallback) {
  switch (type) {
    case "new_order":
      return `${countLabel} New COD Orders`;
    case "order_status":
      return `${countLabel} Order Updates`;
    case "stock_alert":
      return `${countLabel} Stock Alerts`;
    case "admin_supplier_application":
      return `${countLabel} Supplier Applications`;
    case "admin_supplier_change_request":
      return `${countLabel} Supplier Change Requests`;
    case "supplier_profile_change":
    case "supplier_application_status":
      return `${countLabel} Account Updates`;
    default:
      return fallback;
  }
}

async function notificationPresentation({
  recipientId,
  data,
}) {
  const type = textValue(data.type, "general").toLowerCase();
  const originalTitle = textValue(data.title, "IsdaLink");
  const originalBody = textValue(
      data.message,
      "You have a new IsdaLink notification.",
  );
  const recipientNotifications = await firestore
      .collection("notifications")
      .where("userId", "==", recipientId)
      .get();
  const unreadCount = recipientNotifications.docs.reduce((count, document) => {
    const notification = document.data();
    const notificationType = textValue(notification.type).toLowerCase();

    return notification.isRead !== true && notificationType === type
      ? count + 1
      : count;
  }, 0);
  const safeUnreadCount = Math.max(1, unreadCount);
  const grouped = safeUnreadCount > 1;
  const countLabel = safeUnreadCount > 9 ? "9+" : String(safeUnreadCount);
  const group = notificationGroup(type, data);
  const tag = safeDocumentPart(`isdalink_${recipientId}_${group}`);

  return {
    title: grouped
      ? groupedTitle(type, countLabel, originalTitle)
      : originalTitle,
    body: grouped
      ? `Latest: ${originalBody} Tap to review all.`
      : originalBody,
    route: notificationRoute(type),
    group,
    tag,
    collapseKey: tag.slice(0, 64),
    unreadCount: safeUnreadCount,
    grouped,
  };
}

async function markPushResult(reference, fields) {
  await reference.set(
      {
        ...fields,
        pushedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
  );
}

exports.sendPushNotification = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
      const snapshot = event.data;

      if (!snapshot) {
        return;
      }

      const notificationReference = snapshot.ref;
      const notificationId = event.params.notificationId;
      const eventId = textValue(event.id, notificationId);

      const claimed = await firestore.runTransaction(async (transaction) => {
        const currentSnapshot = await transaction.get(notificationReference);
        const currentData = currentSnapshot.data();

        if (!currentData || textValue(currentData.pushEventId).length > 0) {
          return false;
        }

        transaction.update(notificationReference, {
          pushEventId: eventId,
          pushStatus: "processing",
          pushStartedAt: FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (!claimed) {
        return;
      }

      const data = snapshot.data();
      const recipientId = textValue(
          data.userId,
          textValue(data.vendorId, textValue(data.supplierId)),
      );

      if (recipientId.length === 0) {
        await markPushResult(notificationReference, {
          pushStatus: "missing_recipient",
          pushSuccessCount: 0,
          pushFailureCount: 0,
        });
        return;
      }

      const tokenSnapshot = await firestore
          .collection("users")
          .doc(recipientId)
          .collection("pushTokens")
          .where("enabled", "==", true)
          .get();

      const tokenReferences = new Map();

      for (const tokenDocument of tokenSnapshot.docs) {
        const token = textValue(tokenDocument.data().token);

        if (token.length > 0) {
          tokenReferences.set(token, tokenDocument.ref);
        }
      }

      const tokens = [...tokenReferences.keys()];

      if (tokens.length === 0) {
        await markPushResult(notificationReference, {
          pushStatus: "no_registered_device",
          pushSuccessCount: 0,
          pushFailureCount: 0,
        });
        return;
      }

      const presentation = await notificationPresentation({
        recipientId,
        data,
      });
      let successCount = 0;
      let failureCount = 0;
      const invalidReferences = [];

      for (let start = 0; start < tokens.length; start += 500) {
        const tokenBatch = tokens.slice(start, start + 500);

        try {
          const response = await messaging.sendEachForMulticast({
            tokens: tokenBatch,
            notification: {
              title: presentation.title,
              body: presentation.body,
            },
            data: pushData(notificationId, data, {
              recipientId,
              route: presentation.route,
              group: presentation.group,
              unreadCount: presentation.unreadCount,
              grouped: presentation.grouped,
            }),
            android: {
              priority: "high",
              collapseKey: presentation.collapseKey,
              notification: {
                sound: "default",
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
                channelId: "isdalink_alerts",
                icon: "ic_stat_isdalink",
                color: "#0875D1",
                tag: presentation.tag,
                notificationCount: Math.min(
                    presentation.unreadCount,
                    99,
                ),
              },
            },
          });

          successCount += response.successCount;
          failureCount += response.failureCount;

          response.responses.forEach((result, index) => {
            const errorCode = result.error?.code;

            if (!result.success && invalidTokenCodes.has(errorCode)) {
              const reference = tokenReferences.get(tokenBatch[index]);

              if (reference) {
                invalidReferences.push(reference);
              }
            }
          });
        } catch (error) {
          failureCount += tokenBatch.length;
          console.error(
              `FCM batch failed for notification ${notificationId}`,
              error,
          );
        }
      }

      for (let start = 0; start < invalidReferences.length; start += 500) {
        const deleteBatch = firestore.batch();

        for (const reference of invalidReferences.slice(start, start + 500)) {
          deleteBatch.delete(reference);
        }

        await deleteBatch.commit();
      }

      const pushStatus = failureCount === 0
        ? "sent"
        : successCount > 0
          ? "partially_sent"
          : "failed";

      await markPushResult(notificationReference, {
        pushStatus,
        pushSuccessCount: successCount,
        pushFailureCount: failureCount,
      });
    },
);

async function createAdminNotifications({
  eventId,
  title,
  message,
  type,
  subjectId,
  status,
}) {
  const adminSnapshot = await firestore
      .collection("users")
      .where("role", "==", "admin")
      .get();

  const eventPart = safeDocumentPart(eventId);

  await Promise.all(adminSnapshot.docs.map(async (adminDocument) => {
    const notificationReference = firestore
        .collection("notifications")
        .doc(`${eventPart}_${safeDocumentPart(adminDocument.id)}`);

    await firestore.runTransaction(async (transaction) => {
      const existing = await transaction.get(notificationReference);

      if (existing.exists) {
        return;
      }

      transaction.set(notificationReference, {
          userId: adminDocument.id,
          title,
          message,
          type,
          subjectId,
          status,
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
      });
    });
  }));
}

exports.notifyAdminsOfSupplierApplication = onDocumentWritten(
    "supplierProfiles/{supplierId}",
    async (event) => {
      const beforeSnapshot = event.data?.before;
      const afterSnapshot = event.data?.after;

      if (!afterSnapshot?.exists) {
        return;
      }

      const beforeData = beforeSnapshot?.exists
        ? beforeSnapshot.data()
        : {};
      const afterData = afterSnapshot.data();
      const afterStatus = textValue(afterData.status).toLowerCase();
      const beforeStatus = textValue(beforeData.status).toLowerCase();
      const isNewSubmission = beforeStatus !== "pending" ||
        timestampChanged(beforeData.submittedAt, afterData.submittedAt);

      if (afterStatus !== "pending" || !isNewSubmission) {
        return;
      }

      const supplierName = textValue(
          afterData.storeName,
          textValue(afterData.supplierName, "A vendor"),
      );

      await createAdminNotifications({
        eventId: event.id,
        title: "New Supplier Application",
        message: `${supplierName} submitted a supplier application for review.`,
        type: "admin_supplier_application",
        subjectId: event.params.supplierId,
        status: "pending",
      });
    },
);

exports.notifyAdminsOfSupplierChangeRequest = onDocumentWritten(
    "supplierChangeRequests/{supplierId}",
    async (event) => {
      const beforeSnapshot = event.data?.before;
      const afterSnapshot = event.data?.after;

      if (!afterSnapshot?.exists) {
        return;
      }

      const beforeData = beforeSnapshot?.exists
        ? beforeSnapshot.data()
        : {};
      const afterData = afterSnapshot.data();
      const afterStatus = textValue(afterData.status).toLowerCase();
      const beforeStatus = textValue(beforeData.status).toLowerCase();
      const isNewSubmission = beforeStatus !== "pending" ||
        timestampChanged(beforeData.submittedAt, afterData.submittedAt);

      if (afterStatus !== "pending" || !isNewSubmission) {
        return;
      }

      const supplierName = textValue(
          afterData.supplierName,
          "A supplier",
      );

      await createAdminNotifications({
        eventId: event.id,
        title: "New Supplier Change Request",
        message:
          `${supplierName} requested changes to verified business information.`,
        type: "admin_supplier_change_request",
        subjectId: event.params.supplierId,
        status: "pending",
      });
    },
);
