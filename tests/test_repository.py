import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_security_snapshot_sample_shape():
    data = json.loads((ROOT / "samples/security-snapshot.sample.json").read_text())
    assert data["source"] == "synthetic-sample"
    assert data["identity"]["totalUsers"] >= data["identity"]["mfaRegisteredUsers"]
    assert isinstance(data["privilegedRoles"], list)
    assert "highPrivilegeAppConsents" in data["applications"]
    assert data["devices"]["managedDeviceCount"] >= data["devices"]["nonCompliantCount"]


def test_permission_plan_has_required_scopes():
    plan = json.loads((ROOT / "samples/permission-plan.json").read_text())
    required = set(plan["requiredApplicationPermissions"])
    expected = {
        "AuditLog.Read.All",
        "Directory.Read.All",
        "Policy.Read.All",
        "DeviceManagementManagedDevices.Read.All",
        "IdentityRiskyUser.Read.All",
        "RoleManagement.Read.Directory",
    }
    assert expected.issubset(required)


def test_csv_samples_have_expected_headers():
    with (ROOT / "samples/conditional-access-summary.sample.csv").open(newline="") as handle:
        reader = csv.DictReader(handle)
        assert reader.fieldnames == ["policyName", "state", "users", "apps", "grantControls", "sessionControls"]
        assert len(list(reader)) >= 2
    with (ROOT / "samples/device-compliance-summary.sample.csv").open(newline="") as handle:
        reader = csv.DictReader(handle)
        assert reader.fieldnames == ["platform", "ownership", "managedCount", "compliantCount", "nonCompliantCount", "lastSyncOlderThan7Days"]
        rows = list(reader)
        assert sum(int(row["managedCount"]) for row in rows) > 0


def test_scripts_are_read_only_and_strict():
    scripts = list((ROOT / "scripts").glob("*.ps1"))
    assert scripts
    forbidden = ["Remove-Mg", "Update-Mg", "New-Mg", "Set-Mg", "Disable-", "Revoke-"]
    for script in scripts:
        text = script.read_text()
        assert "Set-StrictMode -Version Latest" in text
        assert "Connect-MgGraph" in text or script.name == "Test-GraphPermissionPlan.ps1"
        for token in forbidden:
            assert token not in text, f"{script.name} contains mutating command marker {token}"


def test_validate_workflow_uses_read_only_permissions():
    workflow = (ROOT / ".github/workflows/validate.yml").read_text()
    assert "permissions:\n  contents: read" in workflow
    assert "contents: write" not in workflow
    assert "cancel-in-progress: true" in workflow
    assert "pytest>=8.3,<9" in workflow


def test_no_private_or_secret_placeholders():
    blocked = ["pass" + "word", "client" + "_secret", "gho" + "_", "tenant" + ".onmicrosoft.com"]
    for path in ROOT.rglob("*"):
        if path.is_file() and ".git" not in path.parts and "__pycache__" not in path.parts:
            text = path.read_text(errors="ignore").lower()
            for token in blocked:
                assert token not in text, f"{path} contains blocked token {token}"
