# Acceptance test

## 1. Confirm deployment

1. In the central subscription, confirm the resource group contains:
   - Logic App `la-mdc-recommendation-email`
   - Office 365 connection `office365-mdc-recommendations`
   - Storage account with private container `recommendation-state`
2. Confirm the Office 365 connection status is **Connected**.
3. At the selected management group, confirm the policy assignment **Email all active Defender for Cloud recommendations** exists.
4. In at least one governed subscription, confirm:
   - Resource group `rg-mdc-workflow-automation` exists.
   - Automation `mdc-rec-email` exists and is enabled.
   - Its source is `Assessments`.
   - Its Logic App action points to the central workflow.

## 2. Synthetic notification

Run:

```powershell
.\scripts\test-notification.ps1 `
  -SubscriptionId <central-subscription-id> `
  -ResourceGroupName rg-mdc-recommendation-email `
  -LogicAppName la-mdc-recommendation-email `
  -AffectedResourceId /subscriptions/<governed-subscription-id>/resourceGroups/<rg>/providers/<type>/<name>
```

Expected:

- The script receives HTTP `202`.
- The Logic App run succeeds.
- The configured recipients receive one email.
- The email contains recommendation, resource, change-analysis, and Secure Score sections.
- A JSON event file is attached.
- A marker blob is created.

Run the same command again. Expected:

- The request is accepted.
- The second workflow run terminates successfully without sending another email because the marker already exists.

## 3. Live Defender event

Use a nonproduction resource and introduce a reversible configuration that a currently enabled Defender recommendation evaluates as unhealthy. The exact test depends on enabled plans and policies.

Expected:

- Defender shows the resource as unhealthy for the recommendation.
- The per-subscription automation eventually invokes the central Logic App.
- One email arrives after the Defender evaluation cycle.

Restore the secure configuration after the test.

## 4. Secure Score checks

- Verify the subscription score in the message matches Defender for Cloud's classic Secure Score view, allowing for normal API and control recalculation delay.
- Verify the management-group figure is labelled weighted and can differ from a simple average.
- Verify the email says notification delivery changes the score by zero.
- For preview, custom, or unscored recommendations, verify no numeric impact is claimed.

## 5. Failure-path checks

- Disconnect the Office 365 connection in a test deployment: the workflow should fail visibly at the email action.
- Temporarily remove Storage Blob Data Contributor in a test deployment: the email should still be attempted and should flag that the deduplication marker wasn't created.
- Use a non-Azure recommendation payload: the email should still contain the event details, while Azure resource and score enrichment remains unavailable.
