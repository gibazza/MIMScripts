<#
.Synopsis
    Executes a POST to a RESTAPI
.DESCRIPTION
    Takes headers and body parameters as a hastable and exectues a POST call against the passed URI
.EXAMPLE
    Invoke-RESTPOST -headers @{"Authorization" = "Basic xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=="} -uri https://someserver.com/api/update -body @{"email" = "a@b.com";"firstname" = "Adam"}
.EXAMPLE
    Invoke-RESTPOST $headers $url $params
   
#>
[CmdletBinding()]
[OutputType([int])]
    
PARAM(
    [parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName=$true,
        Position = 0)] 
    [System.Collections.Hashtable] $headers,

    [parameter(Mandatory = $true, 
        ValueFromPipelineByPropertyName=$true,
        Position = 1)] 
    [string] $uri,

    [parameter(Mandatory = $true, 
        ValueFromPipelineByPropertyName=$true,
        Position = 2)] 
    [System.Collections.Hashtable] $body
)

Set-Variable -Name contentType -Scope Script -Value "application/json" -Option Constant
[string] $jSONBody | Out-Null
[bool] $validJSON | Out-Null

try {
    $jSONBody = ConvertTo-Json $body -ErrorAction Stop
    $validJson = $true;
}
catch {
    $validJson = $false;
}

if ($validJson) {
    try {
        $result = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Body $jSONBody -UseBasicParsing -ContentType $contentType | ConvertFrom-Json    
    }
    catch {
        $result = $_.Exception.Response.StatusCode.Value__
    }
    if (!$null -eq $result.result) {
        return 200
    }
    else {
        return $result
    }
}
else {
    Throw "Body does not contain valid JSON."
}