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
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ManagedIdentity) {
    Connect-MgGraph -Identity -NoWelcome
} else {
    Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome
}

$policies = Get-MgIdentityConditionalAccessPolicy -All
$rows = foreach ($policy in $policies) {
    [pscustomobject]@{
        policyName = $policy.DisplayName
        state = $policy.State
        users = (($policy.Conditions.Users.IncludeUsers + $policy.Conditions.Users.IncludeGroups + $policy.Conditions.Users.IncludeRoles) -join ';')
        apps = ($policy.Conditions.Applications.IncludeApplications -join ';')
        grantControls = ($policy.GrantControls.BuiltInControls -join ';')
        sessionControls = (($policy.SessionControls.PSObject.Properties.Name | Where-Object { $policy.SessionControls.$_ }) -join ';')
    }
}

$rows | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Output $OutputPath
