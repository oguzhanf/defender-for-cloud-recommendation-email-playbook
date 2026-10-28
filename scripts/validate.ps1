[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$workflowPath = Join-Path $repoRoot 'logicapp\workflow.json'
$bicepPath = Join-Path $repoRoot 'azuredeploy.bicep'
$armPath = Join-Path $repoRoot 'azuredeploy.json'

Get-Content -Raw $workflowPath | ConvertFrom-Json | Out-Null
Write-Host 'PASS workflow.json parses as JSON'

az bicep build --file $bicepPath --outfile $armPath
if ($LASTEXITCODE -ne 0) {
    throw 'Bicep compilation failed.'
}
Write-Host 'PASS Bicep compilation'

$template = Get-Content -Raw $armPath | ConvertFrom-Json
if ($template.'$schema' -ne 'https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#') {
    throw 'azuredeploy.json is not a tenant-scope template.'
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

Write-Host 'PASS compiled tenant template contains required resources'
