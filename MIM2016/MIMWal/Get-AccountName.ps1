PARAM(
    [parameter(Mandatory=$true,  Position=0)] [string] $givenName,
    [parameter(Mandatory=$true,  Position=1)] [string] $sn,
    [parameter(Mandatory=$true,  Position=2)] [string] $serviceFQDN
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
            `$resultMIM = Search-Resources -XPath /$searchObjectType[$searchAttribute='$searchValue'] -MaxResults 1
            `$resultMIM
        "
        Write-Verbose $commandString.ToString()
        $command = [scriptblock]::Create($commandString)
        $rtnValue = Invoke-Command -ComputerName localhost -ScriptBlock $command -SessionOption $option
        if (-not ($null -eq $rtnValue)) {Write-Verbose $rtnValue}
        Return ($null -eq $rtnValue)
    }
}

Function Get-AccountName
{
    PARAM(
        [parameter(Mandatory=$true,  Position=0)] [string] $accountName,
        [parameter(Mandatory=$true,  Position=1)] [string] $accountNameAppend,
        [parameter(Mandatory=$false,  Position=2)] [int] $length=18
        )
    END
    {
        $accountName = $accountName + $accountNameAppend
        if ($accountName.Length -ge $length)
        {
            $accountName = $accountName.Substring(0,$length)
        }

        if((Test-UniqueMIMAttribute -searchObjectType "Person" -searchAttribute "AccountName" -searchValue $accountName) -and 
        (Test-UniqueADAttribute -searchAttribute "samAccountName" -searchValue $accountName))
        {
            $accountName
            exit
        }
    }
}


$Global:serviceURi = $null
Set-Variable -Name serviceURi -Scope Global -Value $($serviceFQDN)
[string]$accountName = [string]::Empty 
[string]$invalidChars = "[\[!#$%&*+/=?^`{}\]]"
$givenName = $givenName.ToLower() -replace $invalidChars,''
$sn = $sn.ToLower() -replace $invalidChars,''
if ($givenName.Contains("-"))
{
    $givenName = $givenName.Split("-")[0]
}
if ($sn.Contains("-"))
{
    $givenName = $givenName + $sn.Split("-")[0].Substring(0,1)
    $sn = $sn.Split("-")[1]
}
Write-Verbose "Firstname: $givenName"
Write-Verbose "Surname: $sn"
$accountName = $givenName
Write-Verbose "Initial accountname: $accountName"

foreach($j in [char[]]$sn) {
    $append =$append + $j
    Get-AccountName -accountName $accountName -accountNameAppend $append
}

foreach($j in 0..99) {
    Get-AccountName -accountName $accountName -accountNameAppend $j -length 20
}

Write-Verbose "The end of the script"