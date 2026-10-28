targetScope = 'managementGroup'

param location string
param policyAssignmentName string
param automationName string
param automationResourceGroupName string
param logicAppResourceId string
param logicAppPrincipalId string

var workflowAutomationPolicyDefinitionId = '/providers/Microsoft.Authorization/policyDefinitions/73d6ab6c-2475-4850-afd6-43795f3492ef'
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var securityReaderRoleId = '39bc4728-0917-49c7-9d2c-d95423bc2eb4'

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: policyAssignmentName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: 'Deploys Defender for Cloud recommendation workflow automation to every current and future subscription in this management group.'
    displayName: 'Email all active Defender for Cloud recommendations'
    enforcementMode: 'Default'
    policyDefinitionId: workflowAutomationPolicyDefinitionId
    parameters: {
      automationName: {
        value: automationName
      }
      createResourceGroup: {
        value: true
      }
      logicAppResourceId: {
        value: logicAppResourceId
      }
      logicAppTrigger: {
        value: 'Manual (Incoming HTTP request)'
      }
      recommendationNames: {
        value: []
      }
      recommendationSeverities: {
        value: [
          'High'
          'Medium'
          'Low'
        ]
      }
      recommendationStates: {
        value: [
          'Unhealthy'
        ]
      }
      resourceGroupLocation: {
        value: location
      }
      resourceGroupName: {
        value: automationResourceGroupName
      }
    }
    nonComplianceMessages: [
      {
        message: 'This subscription must contain the Defender for Cloud recommendation email workflow automation.'
      }
    ]
  }
}

resource policyContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, policyAssignment.id, contributorRoleId)
  properties: {
    principalId: policyAssignment.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
  }
}

resource logicAppReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, logicAppPrincipalId, readerRoleId)
  properties: {
    principalId: logicAppPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
  }
}

resource logicAppSecurityReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, logicAppPrincipalId, securityReaderRoleId)
  properties: {
    principalId: logicAppPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', securityReaderRoleId)
  }
}

output policyAssignmentId string = policyAssignment.id
output policyAssignmentPrincipalId string = policyAssignment.identity.principalId
