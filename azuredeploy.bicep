targetScope = 'tenant'

@description('Management group whose current and future subscriptions receive the Defender for Cloud workflow automation. Use the tenant root management group to cover the full tenant.')
param managementGroupId string

@description('Subscription that hosts the central Logic App, Office 365 connection, and deduplication storage.')
param centralSubscriptionId string

@description('Azure region for the central resources and per-subscription automation resource groups.')
param location string = 'eastus'

@description('Resource group created in the central subscription.')
param centralResourceGroupName string = 'rg-mdc-recommendation-email'

@description('Central Consumption Logic App name.')
param logicAppName string = 'la-mdc-recommendation-email'

@description('Office 365 Outlook API connection name. This OAuth connection must be authorized once after deployment.')
param office365ConnectionName string = 'office365-mdc-recommendations'

@description('Semicolon-separated email recipients.')
@minLength(3)
param notificationEmailAddresses string

@description('Optional semicolon-separated CC recipients.')
param ccEmailAddresses string = ''

@description('Prefix placed at the start of every notification subject.')
param emailSubjectPrefix string = '[Defender for Cloud]'

@description('How far back the Logic App queries Azure Resource Graph Change Analysis for potentially related ARM changes.')
@minValue(1)
@maxValue(168)
param resourceChangeLookbackHours int = 24

@description('Days to retain deduplication markers. Repeated evaluation events for the same resource, recommendation, and state are suppressed during this period.')
@minValue(1)
@maxValue(365)
param deduplicationRetentionDays int = 30

@description('Resource group created in every governed subscription for the Defender for Cloud automation resource.')
param automationResourceGroupName string = 'rg-mdc-workflow-automation'

@description('Name of the Microsoft.Security/automations resource created in every governed subscription.')
@minLength(3)
@maxLength(24)
param automationName string = 'mdc-rec-email'

@description('Name of the management-group policy assignment.')
@minLength(3)
@maxLength(24)
param policyAssignmentName string = 'mdc-rec-email'

@description('Create an Azure Policy remediation task for subscriptions that already exist under the management group.')
param deployRemediation bool = true

@description('Tags applied to central resources.')
param tags object = {
  workload: 'defender-for-cloud-recommendation-notifications'
  managedBy: 'bicep'
}

module central 'infra/modules/central-subscription.bicep' = {
  name: 'central-${uniqueString(centralSubscriptionId, centralResourceGroupName)}'
  scope: subscription(centralSubscriptionId)
  params: {
    resourceGroupName: centralResourceGroupName
    location: location
    logicAppName: logicAppName
    office365ConnectionName: office365ConnectionName
    notificationEmailAddresses: notificationEmailAddresses
    ccEmailAddresses: ccEmailAddresses
    emailSubjectPrefix: emailSubjectPrefix
    managementGroupId: managementGroupId
    resourceChangeLookbackHours: resourceChangeLookbackHours
    deduplicationRetentionDays: deduplicationRetentionDays
    tags: tags
  }
}

module managementGroupPolicy 'infra/modules/management-group-policy.bicep' = {
  name: 'policy-${uniqueString(managementGroupId, policyAssignmentName)}'
  scope: managementGroup(managementGroupId)
  params: {
    location: location
    policyAssignmentName: policyAssignmentName
    automationName: automationName
    automationResourceGroupName: automationResourceGroupName
    logicAppResourceId: central.outputs.logicAppResourceId
    logicAppPrincipalId: central.outputs.logicAppPrincipalId
  }
}

module logicAppPolicyAccess 'infra/modules/logic-app-policy-access.bicep' = {
  name: 'policy-access-${uniqueString(centralSubscriptionId, logicAppName)}'
  scope: resourceGroup(centralSubscriptionId, centralResourceGroupName)
  params: {
    logicAppName: logicAppName
    policyAssignmentPrincipalId: managementGroupPolicy.outputs.policyAssignmentPrincipalId
  }
}

module remediation 'infra/modules/remediation.bicep' = if (deployRemediation) {
  name: 'remediation-${uniqueString(deployment().name, managementGroupId)}'
  scope: managementGroup(managementGroupId)
  params: {
    remediationName: take('mdc-rec-${uniqueString(deployment().name, managementGroupId)}', 64)
    policyAssignmentId: managementGroupPolicy.outputs.policyAssignmentId
  }
  dependsOn: [
    logicAppPolicyAccess
  ]
}

output centralResourceGroupId string = central.outputs.resourceGroupId
output logicAppResourceId string = central.outputs.logicAppResourceId
output office365ConnectionResourceId string = central.outputs.office365ConnectionResourceId
output policyAssignmentId string = managementGroupPolicy.outputs.policyAssignmentId
output authorizationRequired string = 'Authorize the Office 365 connection before testing. See README.md.'
