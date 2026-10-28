targetScope = 'managementGroup'

param remediationName string
param policyAssignmentId string

resource remediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: remediationName
  properties: {
    failureThreshold: {
      percentage: json('0.1')
    }
    parallelDeployments: 10
    policyAssignmentId: policyAssignmentId
    resourceCount: 50000
    resourceDiscoveryMode: 'ReEvaluateCompliance'
  }
}
