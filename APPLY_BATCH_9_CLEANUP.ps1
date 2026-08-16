$ErrorActionPreference = "Stop"

if (-not (Test-Path "pubspec.yaml") -or -not (Test-Path "lib\main.dart")) {
  throw "Run this script from the root of the IsdaLink Flutter project."
}

$paths = @(
  "const",
  "false",
  "ProductDetailsScreen(",
  "SupplierDetailsScreen(",
  "lib/data/sample_data.dart",
  "lib/data/sample_orders.dart",
  "lib/models/analytics_models.dart",
  "lib/models/order_model.dart",
  "lib/screens/analytics/widgets/analytics_footer_note.dart",
  "lib/screens/analytics/widgets/analytics_formatters.dart",
  "lib/screens/analytics/widgets/analytics_header.dart",
  "lib/screens/analytics/widgets/analytics_section_card.dart",
  "lib/screens/analytics/widgets/analytics_state_widgets.dart",
  "lib/screens/analytics/widgets/forecast_evaluation_card.dart",
  "lib/screens/analytics/widgets/forecasting_methods_card.dart",
  "lib/screens/analytics/widgets/restocking_suggestions_card.dart",
  "lib/screens/analytics/widgets/sales_trend_card.dart",
  "lib/screens/analytics/widgets/top_product_insights_card.dart",
  "lib/screens/home/widgets/home_quick_actions.dart",
  "lib/screens/profile/widgets/me_header.dart",
  "lib/screens/profile/widgets/me_loading_body.dart",
  "lib/screens/profile/widgets/me_menu_tile.dart",
  "lib/screens/profile/widgets/profile_status_card.dart",
  "lib/screens/supplier/activation/widgets/supplier_activation_feature_card.dart",
  "lib/screens/supplier/activation/widgets/supplier_activation_info_card.dart",
  "lib/screens/supplier/activation/widgets/supplier_activation_section_card.dart",
  "lib/screens/supplier/activation/widgets/supplier_activation_submit_button.dart",
  "lib/screens/supplier/dashboard/widgets/supplier_dashboard_actions.dart",
  "lib/screens/supplier/dashboard/widgets/supplier_dashboard_header.dart",
  "lib/screens/supplier/dashboard/widgets/supplier_dashboard_section_title.dart",
  "lib/screens/supplier/dashboard/widgets/supplier_dashboard_status_cards.dart",
  "lib/screens/supplier/dashboard/widgets/supplier_stock_card.dart",
  "lib/screens/supplier/dashboard/widgets/supplier_stock_list.dart",
  "lib/screens/vendor/product_details/widgets/product_bottom_order_bar.dart",
  "lib/screens/vendor/product_details/widgets/product_description_card.dart",
  "lib/screens/vendor/product_details/widgets/product_details_header.dart",
  "lib/screens/vendor/product_details/widgets/product_info_pill.dart",
  "lib/screens/vendor/product_details/widgets/product_stock_badge.dart",
  "lib/screens/vendor/product_details/widgets/product_supplier_card.dart",
  "lib/screens/vendor/supplier_map_screen.dart",
  "lib/services/analytics_service.dart",
  "lib/services/supplier_dashboard_service.dart",
  "lib/utils/stock_helpers.dart"
)

$deleted = 0
$alreadyMissing = 0

foreach ($path in $paths) {
  if (Test-Path -LiteralPath $path) {
    Remove-Item -LiteralPath $path -Force
    Write-Host "Deleted: $path"
    $deleted++
  } else {
    $alreadyMissing++
  }
}

$emptyDirectories = @(
  "lib\data",
  "lib\screens\analytics\widgets",
  "lib\screens\profile\widgets",
  "lib\screens\supplier\dashboard\widgets",
  "lib\screens\vendor\product_details\widgets"
)

foreach ($directory in $emptyDirectories) {
  if (Test-Path -LiteralPath $directory) {
    $remaining = Get-ChildItem -LiteralPath $directory -Force
    if ($remaining.Count -eq 0) {
      Remove-Item -LiteralPath $directory -Force
      Write-Host "Removed empty directory: $directory"
    }
  }
}

Write-Host ""
Write-Host "Batch 9 cleanup complete."
Write-Host "Deleted files: $deleted"
Write-Host "Already missing: $alreadyMissing"
Write-Host ""
Write-Host "Next commands:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter analyze"
Write-Host "  git status"
