[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$workflowPath = Join-Path $repoRoot 'logicapp\workflow.json'
$formPath = Join-Path $repoRoot 'uiFormDefinition.json'
$bicepPath = Join-Path $repoRoot 'azuredeploy.bicep'
$armPath = Join-Path $repoRoot 'azuredeploy.json'

Get-Content -Raw $workflowPath | ConvertFrom-Json | Out-Null
Write-Host 'PASS workflow.json parses as JSON'

$form = Get-Content -Raw $formPath | ConvertFrom-Json
if ($form.view.outputs.kind -ne 'ManagementGroup') {
    throw 'uiFormDefinition.json must deploy at management-group scope.'
}
if ($form.view.outputs.parameters.centralSubscriptionId -ne "[steps('scope').centralSubscription.subscriptionId]") {
    throw 'uiFormDefinition.json must map the selected subscription to centralSubscriptionId.'
}

$formTypes = @($form.view.properties.steps.elements.type)
foreach ($requiredFormType in @(
    'Microsoft.Common.ManagementGroupSelector',
    'Microsoft.Common.SubscriptionSelector',
    'Microsoft.Common.LocationSelector'
)) {
    if ($requiredFormType -notin $formTypes) {
        throw "uiFormDefinition.json is missing '$requiredFormType'."
    }
}
Write-Host 'PASS portal form contains native Azure scope pickers'

az bicep build --file $bicepPath --outfile $armPath
if ($LASTEXITCODE -ne 0) {
    throw 'Bicep compilation failed.'
}
Write-Host 'PASS Bicep compilation'

$template = Get-Content -Raw $armPath | ConvertFrom-Json
if ($template.'$schema' -ne 'https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#') {
    throw 'azuredeploy.json is not a management-group-scope template.'
}

$serialized = $template | ConvertTo-Json -Depth 100
foreach ($requiredValue in @(
    '73d6ab6c-2475-4850-afd6-43795f3492ef',
    'Microsoft.Logic/workflows',
    'Microsoft.Authorization/policyAssignments',
    'Microsoft.PolicyInsights/remediations',
    'recommendation-state'
)) {
    if (-not $serialized.Contains($requiredValue)) {
        throw "Compiled template is missing required value '$requiredValue'."
    }
}

Write-Host 'PASS compiled management-group template contains required resources'
