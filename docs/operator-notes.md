# Operator notes

## Run posture

Start with reporting scripts. Review exported files before adding any remediation workflow. Keep the evidence directory outside source control and rotate it through normal retention rules.

## Least-privilege setup

Use an app registration with only the permissions listed in `samples/permission-plan.json`. Grant admin consent only in a lab or approved tenant. Certificate authentication is preferred for scheduled execution.

## Change control

These scripts are written for read-only assessment. If a team extends them to modify policies, add a separate approval gate, export the current policy first, and write a rollback file.

## Evidence handling

Identity, risk, device, and app-consent reports can contain personal data. Store generated reports in a restricted location and do not commit them.
