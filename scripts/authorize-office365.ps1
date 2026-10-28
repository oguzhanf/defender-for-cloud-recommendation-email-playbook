[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $SubscriptionId,

    [string] $ResourceGroupName = 'rg-mdc-recommendation-email',
    [string] $ConnectionName = 'office365-mdc-recommendations'
)

$ErrorActionPreference = 'Stop'

az account set --subscription $SubscriptionId
$account = az account show --output json | ConvertFrom-Json
$resourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/connections/$ConnectionName"

$connection = az resource show --ids $resourceId --api-version 2016-06-01 --output json | ConvertFrom-Json
if (-not $connection) {
    throw "Office 365 connection '$ConnectionName' was not found."
}

$portalUrl = "https://portal.azure.com/#@$($account.tenantId)/resource$resourceId/overview"
Write-Host "Opening the Office 365 API connection in the Azure portal."
Write-Host "Select 'Edit API connection', select 'Authorize', sign in, and save."
Start-Process $portalUrl
