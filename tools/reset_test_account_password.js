const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const fs = require('fs');

const args = process.argv.slice(2);
const email = (args.find(x => x.startsWith('--email=')) || '').slice(8).toLowerCase();
const allowed = ['suppliertest@gmail.com', 'vendortesting@gmail.com'];

async function main() {
  if (!allowed.includes(email)) {
    throw new Error('Email is not an approved test account.');
  }

  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const projectId = process.env.GOOGLE_CLOUD_PROJECT;

  if (!keyPath || !fs.existsSync(keyPath)) {
    throw new Error('Firebase credentials file not found.');
  }

  const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));

  if (projectId !== 'isdalink-b6744' ||
      serviceAccount.project_id !== projectId) {
    throw new Error('Firebase project mismatch.');
  }

  initializeApp({
    credential: cert(serviceAccount),
    projectId
  });

  const user = await getAuth().getUserByEmail(email);
  console.log('Found test account:', email);
  console.log('UID:', user.uid);

  if (!args.includes('--commit') ||
      !args.includes('--confirm=RESET-TEST-PASSWORD')) {
    console.log('Dry run only. Password unchanged.');
    return;
  }

  const password = process.env.ISDALINK_NEW_TEST_PASSWORD;

  if (!password || password.length < 6) {
    throw new Error('Missing or invalid new test password.');
  }

  await getAuth().updateUser(user.uid, { password });
  console.log('SUCCESS: Password updated for', email);
}

main().catch(error => {
  console.error('ERROR:', error.message);
  process.exitCode = 1;
});
