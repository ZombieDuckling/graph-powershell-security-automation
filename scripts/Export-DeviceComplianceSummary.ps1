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

$cutoff = (Get-Date).AddDays(-7)
$devices = Get-MgDeviceManagementManagedDevice -All
$summary = $devices |
    Group-Object OperatingSystem,ManagedDeviceOwnerType |
    ForEach-Object {
        $items = @($_.Group)
        [pscustomobject]@{
            platform = $items[0].OperatingSystem
            ownership = $items[0].ManagedDeviceOwnerType
            managedCount = $items.Count
            compliantCount = @($items | Where-Object { $_.ComplianceState -eq 'compliant' }).Count
            nonCompliantCount = @($items | Where-Object { $_.ComplianceState -ne 'compliant' }).Count
            lastSyncOlderThan7Days = @($items | Where-Object { $_.LastSyncDateTime -lt $cutoff }).Count
        }
    }

$summary | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Output $OutputPath
