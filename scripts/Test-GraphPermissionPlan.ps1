[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$PermissionPlan,

    [string[]]$GrantedPermissions = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$plan = Get-Content -Path $PermissionPlan -Raw | ConvertFrom-Json
$required = @($plan.requiredApplicationPermissions)
$missing = @($required | Where-Object { $_ -notin $GrantedPermissions })

$result = [ordered]@{
    graphProfile = $plan.graphProfile
    requiredCount = $required.Count
    grantedCount = $GrantedPermissions.Count
    missingPermissions = $missing
    ready = ($missing.Count -eq 0)
}

$result | ConvertTo-Json -Depth 5
