
#Add-SP2016WebApp.ps1 -hostHeader idmportal.mimvm.com `
    #-url "http://idmportal.mimvm.com" `
    #-appPoolAccount "mimvm\SVC_mimspapppool" `
    #-ownerAccount "mimvm\mimadmin"
Param
(
    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true,
        Position=0)]
    [string]$webAppName = "MIM Portal",

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true,
        Position=1)]
    [int]$webAppPort = 80,

    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=2)]
    [string]$hostHeader,

    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=3)] 
    [string]$url,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true,
        Position=4)]
    [string]$appPoolName = "MIMPortalAppPool",

    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=5)]
    [string]$appPoolAccount,

    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=6)]
    [string]$ownerAccount
)

$ver = $host | Select-Object version
if ($ver.Version.Major -gt 1) {$host.Runspace.ThreadOptions = "ReuseThread"} 
if ($null -eq (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue))
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

$appPoolCreds = Get-Credential -UserName $appPoolAccount -Message "Enter password for $appPoolAccount"
Get-SPManagedAccount $appPoolAccount
if (-not $?)
{
    New-SPManagedAccount -Credential $appPoolCreds
}

New-SPWebApplication -Name $webAppName -Port $webAppPort -HostHeader $hostHeader -URL $url -ApplicationPool "MIMPortalAppPool" -ApplicationPoolAccount (Get-SPManagedAccount $appPoolAccount) -AuthenticationMethod “Kerberos”
$w = Get-SPWebApplication $url
New-SPSite $w.url -OwnerAlias $ownerAccount -Name $webAppName -Template "STS#0"
$contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService;
$contentService.ViewStateOnServer = $false;
$contentService.Update();
Get-SPTimerJob hourly-all-sptimerservice-health-analysis-job | disable-SPTimerJob
iisreset