targetScope = 'resourceGroup'

param logicAppName string
param policyAssignmentPrincipalId string

var logicAppContributorRoleId = '87a39d53-fc1b-424a-814c-f7e04687dc9e'

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppName
}

resource logicAppContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logicApp.id, policyAssignmentPrincipalId, logicAppContributorRoleId)
  scope: logicApp
  properties: {
    principalId: policyAssignmentPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', logicAppContributorRoleId)
  }
}
