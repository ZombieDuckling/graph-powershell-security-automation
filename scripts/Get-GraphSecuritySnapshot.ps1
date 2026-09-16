[CmdletBinding(DefaultParameterSetName = 'Certificate')]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$ClientId,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$CertificateThumbprint,

    [Parameter(ParameterSetName = 'ManagedIdentity')]
    [switch]$ManagedIdentity,

    [Parameter(Mandatory)]
    [string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Connect-GraphForRunbook {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$CertificateThumbprint,
        [bool]$UseManagedIdentity
    )

    if ($UseManagedIdentity) {
        Connect-MgGraph -Identity -NoWelcome
        return
    }

    Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome
}

function New-SnapshotDirectory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

New-SnapshotDirectory -Path $OutputDirectory
Connect-GraphForRunbook -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -UseManagedIdentity:$ManagedIdentity.IsPresent

$users = Get-MgUser -All -Property Id,UserPrincipalName,DisplayName,AccountEnabled
$authMethods = foreach ($user in $users) {
    $methods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction SilentlyContinue
    [pscustomobject]@{
        UserPrincipalName = $user.UserPrincipalName
        MethodCount = @($methods).Count
    }
}

$riskyUsers = Get-MgRiskyUser -All -ErrorAction SilentlyContinue | Select-Object UserPrincipalName,RiskLevel,RiskState
$roles = Get-MgRoleManagementDirectoryRoleAssignment -All -ExpandProperty RoleDefinition |
    Group-Object { $_.RoleDefinition.DisplayName } |
    ForEach-Object { [pscustomobject]@{ roleName = $_.Name; assignedCount = $_.Count } }
$appConsents = Get-MgOauth2PermissionGrant -All -ErrorAction SilentlyContinue |
    Where-Object { $_.Scope -match 'Directory\.Read\.All|RoleManagement\.Read|Policy\.Read' } |
    Select-Object ClientId,ConsentType,Scope
$devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction SilentlyContinue

$snapshot = [ordered]@{
    tenant = $TenantId
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    source = 'Microsoft Graph PowerShell'
    identity = [ordered]@{
        totalUsers = @($users).Count
        mfaRegisteredUsers = @($authMethods | Where-Object { $_.MethodCount -gt 0 }).Count
        riskyUsers = @($riskyUsers)
    }
    privilegedRoles = @($roles)
    applications = [ordered]@{
        highPrivilegeAppConsents = @($appConsents)
    }
    devices = [ordered]@{
        managedDeviceCount = @($devices).Count
        nonCompliantCount = @($devices | Where-Object { $_.ComplianceState -ne 'compliant' }).Count
    }
}

$snapshotPath = Join-Path $OutputDirectory 'security-snapshot.json'
$snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding UTF8
Write-Output $snapshotPath
