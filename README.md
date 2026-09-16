# Graph PowerShell Security Automation

PowerShell runbooks for Microsoft Graph security administration. The scripts use certificate or managed-identity authentication, keep tenant-specific values outside source control, and produce evidence files an engineer can review before making changes.

This project is safe to run as a portfolio lab: sample data is synthetic, scripts default to report-only behavior where changes could affect users, and no tenant identifiers or secrets are included.

## Why this exists

The VAT IT Security Engineer role calls for practical Microsoft 365 security administration, PowerShell automation, identity controls, endpoint governance, and clear operational handover. This repo shows those skills through small runbooks that can be reviewed, tested, and scheduled.

## What is included

| Area | Artifact | Purpose |
| --- | --- | --- |
| Identity review | `scripts/Get-GraphSecuritySnapshot.ps1` | Exports MFA registration, risky user, application consent, and admin role summary data. |
| Conditional access evidence | `scripts/Export-ConditionalAccessSummary.ps1` | Converts conditional access policies into a readable control matrix. |
| Endpoint governance | `scripts/Export-DeviceComplianceSummary.ps1` | Summarises managed device compliance posture by platform and ownership. |
| Guardrail checks | `scripts/Test-GraphPermissionPlan.ps1` | Verifies the configured Graph scopes before a runbook touches a tenant. |
| Review workflow | `.github/workflows/validate.yml` | Runs static checks and validates sample output on every push. |

## VAT IT skill mapping

- Microsoft 365 security administration: Graph PowerShell, Entra ID, Intune, role and policy reporting.
- Scripting and automation: idempotent PowerShell functions, typed parameters, explicit output paths, non-interactive execution.
- Security operations: evidence exports for identity risk, privileged access, device compliance, and control review.
- Governance: report-only defaults, required scope checks, synthetic sample data, and clear operator notes.
- Documentation: runbook instructions, change-safety notes, and testable acceptance criteria.

## Repository layout

```text
scripts/     PowerShell runbooks and reusable helpers
samples/     Synthetic input and expected output examples
tests/       Python validation tests for schema, samples, and script hygiene
docs/        Operator notes and job-skill mapping
```

## Authentication model

The scripts expect one of these patterns:

1. Managed identity from an automation account or hosted runner.
2. Certificate-based app registration with least-privilege Graph application permissions.
3. Interactive delegated login for a lab tenant only.

Recommended application permissions for the reporting scripts:

```text
AuditLog.Read.All
Directory.Read.All
Policy.Read.All
DeviceManagementManagedDevices.Read.All
IdentityRiskyUser.Read.All
RoleManagement.Read.Directory
```

`Test-GraphPermissionPlan.ps1` checks the requested permission plan before other scripts run.

## Quick start

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser

./scripts/Test-GraphPermissionPlan.ps1 -PermissionPlan ./samples/permission-plan.json

./scripts/Get-GraphSecuritySnapshot.ps1 `
  -TenantId '<tenant-id>' `
  -ClientId '<app-id>' `
  -CertificateThumbprint '<thumbprint>' `
  -OutputDirectory ./out
```

For a lab without a tenant, run the local validation suite:

```bash
python3 -m pytest tests
```

## Safety guardrails

- No secrets, tenant IDs, user exports, or client data are committed.
- Scripts write reports first. They do not disable accounts, change policies, or remove devices.
- Destructive operations are deliberately out of scope.
- Samples use synthetic users, policies, and device names.

## Expected outputs

A successful tenant run writes JSON and CSV files under the selected output directory:

```text
security-snapshot.json
conditional-access-summary.csv
device-compliance-summary.csv
permission-check.json
```

The JSON shape is documented in `samples/security-snapshot.sample.json` and validated by the test suite.
