PARAM(
    [parameter(Mandatory=$true,  Position=0)] [string] $givenName,
    [parameter(Mandatory=$true,  Position=1)] [string] $sn,
    [parameter(Mandatory=$true,  Position=2)] [string] $upnSuffix,
    [parameter(Mandatory=$true,  Position=3)] [string] $serviceFQDN
    )

<#
   	.SYNOPSIS 
   	Returns $true if a passed attribute and value is unique in the AD Forest by querying Global Catalogue

   	.DESCRIPTION
   	

   	.OUTPUTS
   	
   
   	.EXAMPLE
	UniqueADAttribute -searchAttribute 'mail' -searchAttribute 'bob.bobster@corp.local'
   	
#>

Function Test-UniqueADAttribute
{
    PARAM(
        [parameter(Mandatory=$true,  Position=0)] [string] $searchAttribute,
        [parameter(Mandatory=$true,  Position=1)] [string] $searchValue
        )
    END
    {
        $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 
        $root = [ADSI]"GC://$($dom.Name)"                                                                                                                    
        $search = New-Object System.DirectoryServices.DirectorySearcher($root,"(&(objectcategory=*)($searchAttribute=$searchValue))")
        $search.PropertiesToLoad.Add($searchAttribute) | Out-Null
        [Array]$resultLDAP = $search.FindOne()
        Switch ($resultLDAP.Count)
        {
            0 {Return $True}
            $null {Return $True}
            DEFAULT {Return $False}
        }
    }
}

Function Test-UniqueMIMAttribute
{
    PARAM(
        [parameter(Mandatory=$true, Position=0)] [string] $searchObjectType,
        [parameter(Mandatory=$true, Position=1)] [string] $searchAttribute,
        [parameter(Mandatory=$true, Position=2)] [string] $searchValue
        )
    END
    {
        $commandString = "
            if (`$null -eq (Get-Module -Name 'LithnetRMA' -ErrorAction SilentlyContinue))
            {
                Import-Module LithnetRMA
            }
            Set-ResourceManagementClient -BaseAddress 'http://$($Global:serviceURi):5725'
            `$resultMIM = Search-Resources -XPath `"/$searchObjectType[$searchAttribute='$searchValue']`" -MaxResults 1
            `$resultMIM
        "
        Write-Verbose $commandString.ToString()
        $command = [scriptblock]::Create($commandString)
        $rtnValue = Invoke-Command -ComputerName localhost -ScriptBlock $command -SessionOption $option
        if (-not ($null -eq $rtnValue)) {Write-Verbose $rtnValue}
        Return ($null -eq $rtnValue)
    }
}

Function Get-UPN
{
    PARAM(
        [parameter(Mandatory=$true,  Position=0)] [string] $firstName,
        [parameter(Mandatory=$true,  Position=1)] [string] $surname,
        [parameter(Mandatory=$true,  Position=3)] [string] $upSuffix,
        [parameter(Mandatory=$false,  Position=2)] [string] $uPNAppend = [string]::Empty
        )
    END
    {
        $UPN = "$firstName.$surname$uPNAppend@$upSuffix"

        if((Test-UniqueMIMAttribute -searchObjectType "Person" -searchAttribute "Email" -searchValue $UPN) -and 
        (Test-UniqueADAttribute -searchAttribute "mail" -searchValue $UPN))
        {
            $UPN
            exit
        }
    }
}

$Global:serviceURi = $null
Set-Variable -Name serviceURi -Scope Global -Value $($serviceFQDN)
[string]$invalidChars = "[\[!#$%&*+/=?^`{}\]]"
$givenName = $givenName.ToLower() -replace $invalidChars,''
$sn = $sn.ToLower() -replace $invalidChars,''
Write-Verbose "MIM Service URI: $Global:serviceURi"
Write-Verbose "Firstname: $givenName"
Write-Verbose "Surname: $sn"

Get-UPN -firstName $givenName -surname $sn -upSuffix $upnSuffix

foreach($j in 0..99) {
    Get-UPN -firstName $givenName -surname $sn -uPNAppend $j -upSuffix $upnSuffix
}

Write-Verbose "The end of the script"