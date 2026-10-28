[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $SubscriptionId,

    [Parameter(Mandatory)]
    [string] $AffectedResourceId,

    [string] $ResourceGroupName = 'rg-mdc-recommendation-email',
    [string] $LogicAppName = 'la-mdc-recommendation-email',
    [string] $SamplePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'samples\recommendation-event.json')
)

$ErrorActionPreference = 'Stop'
az account set --subscription $SubscriptionId

$logicAppId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Logic/workflows/$LogicAppName"
$callbackUrl = az rest `
    --method post `
    --url "https://management.azure.com$logicAppId/triggers/manual/listCallbackUrl?api-version=2019-05-01" `
    --query value `
    --output tsv

if (-not $callbackUrl) {
    throw 'Could not retrieve the Logic App callback URL.'
}

$affectedSubscriptionId = if ($AffectedResourceId -match '^/subscriptions/([^/]+)') {
    $Matches[1]
}
else {
    throw 'AffectedResourceId must be a fully qualified Azure resource ID.'
}

$payload = Get-Content -Raw $SamplePath
$payload = $payload.Replace('__SUBSCRIPTION_ID__', $affectedSubscriptionId).Replace('__RESOURCE_ID__', $AffectedResourceId)

$response = Invoke-WebRequest `
    -Method Post `
    -Uri $callbackUrl `
    -ContentType 'application/json' `
    -Body $payload

Write-Host "Logic App accepted the sample event with HTTP $($response.StatusCode)."
