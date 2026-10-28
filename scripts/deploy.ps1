[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ManagementGroupId,

    [Parameter(Mandatory)]
    [string] $CentralSubscriptionId,

    [Parameter(Mandatory)]
    [string] $NotificationEmailAddresses,

    [string] $CcEmailAddresses = '',
    [string] $Location = 'eastus',
    [string] $CentralResourceGroupName = 'rg-mdc-recommendation-email',
    [string] $LogicAppName = 'la-mdc-recommendation-email',
    [string] $Office365ConnectionName = 'office365-mdc-recommendations',
    [switch] $Preview
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$templateFile = Join-Path $repoRoot 'azuredeploy.bicep'
$deploymentName = "mdc-recommendation-email-$((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))"

az account show --output none

$arguments = @(
    'deployment', 'mg',
    $(if ($Preview) { 'what-if' } else { 'create' }),
    '--management-group-id', $ManagementGroupId,
    '--name', $deploymentName,
    '--location', $Location,
    '--template-file', $templateFile,
    '--parameters',
    "centralSubscriptionId=$CentralSubscriptionId",
    "notificationEmailAddresses=$NotificationEmailAddresses",
    "ccEmailAddresses=$CcEmailAddresses",
    "location=$Location",
    "centralResourceGroupName=$CentralResourceGroupName",
    "logicAppName=$LogicAppName",
    "office365ConnectionName=$Office365ConnectionName"
)

& az @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Azure deployment command failed with exit code $LASTEXITCODE."
}
