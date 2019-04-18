PARAM(
    [parameter(Mandatory = $true, Position = 0)] [System.Collections.Hashtable] $headers,
    [parameter(Mandatory = $true, Position = 1)] [string] $uri,
    [parameter(Mandatory = $true, Position = 2)] [string] $jsonBody
)

Set-Variable -Name contentType -Scope Global -Value "application/json" -Option Constant
#Set-Variable -Name pSUtility -Scope Global -Value "Microsoft.PowerShell.Management"
[string] $powershellRepresentation
[bool] $validJson

try {
    $powershellRepresentation = ConvertFrom-Json $jsonBody -ErrorAction Stop;
    $validJson = $true;
} catch {
    $validJson = $false;
}

if ($validJson) {
    try {
        $result = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Body ($params|ConvertTo-Json) -UseBasicParsing -ContentType $contentType | ConvertFrom-Json    
    }
    catch {
        $result = $_.Exception.Response.StatusCode.Value__
    }
    if (!$null -eq $result.result){
        return 200
    }
    else {
        return $result
    }
}
else {
    
}
