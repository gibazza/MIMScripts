Param
(
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0)]
    [string]$domainName,

    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=1)]
	[string]$username,

	[Parameter(Mandatory=$true,
	ValueFromPipelineByPropertyName=$true,
	Position=1)]
	[string]$displayName 
)

Install-Module LithnetRMA
Import-Module LithnetRMA

Set-ResourceManagementClient -BaseAddress localhost -Credentials (Get-Credential)

$objUser = New-Object System.Security.Principal.NTAccount($domain,$username) 
$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier]) 
 
$bytes = New-Object byte[] $strSID.BinaryLength
$strSID.GetBinaryForm($bytes, 0)

# Create the resource
$o = New-Resource -ObjectType Person
$o.AccountName = $username
$o.Domain = $domainName
$o.DisplayName = $displayName
$o.ObjectSID = $bytes
Save-Resource $o

# Add to administrators set
$set = Get-Resource Set DisplayName Administrators
$set.ExplicitMember.Add($o)
Save-Resource $set