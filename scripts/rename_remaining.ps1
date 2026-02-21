$renames = @(
  @('E:\s\scriber\mobile-app\lib\features\admin\data\v2_admin_repository.dart', 'tree_admin_repository.dart'),
  @('E:\s\scriber\mobile-app\lib\features\admin\presentation\pages\v2_tree_browser_page.dart', 'tree_browser_page.dart'),
  @('E:\s\scriber\mobile-app\lib\features\admin\presentation\providers\v2_admin_providers.dart', 'tree_admin_providers.dart'),
  @('E:\s\scriber\mobile-app\lib\features\ai\data\services\ai_v2_data_formatter.dart', 'ai_data_formatter.dart'),
  @('E:\s\scriber\mobile-app\lib\features\ai\domain\services\ai_v2_client.dart', 'ai_client.dart'),
  @('E:\s\scriber\mobile-app\lib\features\ai\presentation\providers\ai_v2_providers.dart', 'ai_inspection_providers.dart'),
  @('E:\s\scriber\mobile-app\lib\features\ai\presentation\widgets\ai_v2_consistency_sheet.dart', 'ai_consistency_sheet.dart'),
  @('E:\s\scriber\mobile-app\lib\features\ai\presentation\widgets\ai_v2_risk_sheet.dart', 'ai_risk_sheet.dart'),
  @('E:\s\scriber\mobile-app\assets\property_inspection\inspection_v2_tree.json', 'inspection_tree.json'),
  @('E:\s\scriber\mobile-app\assets\property_inspection\inspection_v2_tree.json.backup', 'inspection_tree.json.backup'),
  @('E:\s\scriber\mobile-app\assets\property_inspection\inspection_v2_tree.manual_gap_backup', 'inspection_tree.manual_gap_backup'),
  @('E:\s\scriber\mobile-app\assets\property_inspection\inspection_v2_tree_backup_pre_parity.json', 'inspection_tree_backup_pre_parity.json'),
  @('E:\s\scriber\mobile-app\assets\property_valuation\valuation_v2_tree.json', 'valuation_tree.json'),
  @('E:\s\scriber\mobile-app\test\features\report_export\domain\models\v2_report_document_test.dart', 'report_document_test.dart'),
  @('E:\s\scriber\mobile-app\test\features\ai\presentation\providers\ai_v2_providers_test.dart', 'ai_inspection_providers_test.dart')
)

foreach ($r in $renames) {
  $old = $r[0]
  $newName = $r[1]
  if (Test-Path $old) {
    try {
      Rename-Item -Path $old -NewName $newName -Force -ErrorAction Stop
      $leaf = Split-Path $old -Leaf
      Write-Output "RENAMED: $leaf -> $newName"
    } catch {
      $leaf = Split-Path $old -Leaf
      $msg = $_.Exception.Message
      Write-Output "FAILED: $leaf -> $msg"
    }
  } else {
    Write-Output "SKIP: $old not found"
  }
}
