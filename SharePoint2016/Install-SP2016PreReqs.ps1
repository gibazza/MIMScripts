Param(
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $SP2016PreReqsPath,

    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $SP2016InstallPath
)

function Start-Unzip
{
    param([string]$zipfile, [string]$outpath)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function Test-Dir
{
    Param(
        [Parameter(Mandatory = $true)]
        [String] $DirectoryToTest,

        [Parameter(Mandatory = $false)]
        [bool] $DirectoryCreate = $false
        )

    if (-not (Test-Path -LiteralPath $DirectoryToTest) -and
    $DirectoryCreate) {
    
        try {
            New-Item -Path $DirectoryToTest -ItemType Directory -ErrorAction Stop | Out-Null #-Force
        }
        catch {
            Write-Error -Message "Unable to create directory '$DirectoryToTest'. Error was: $_" -ErrorAction Stop
            return $false
        }
        return $True

    }
    else {
        return $True
    }
}

function Start-PreReqsTansfer {
    param (
        [Parameter(Mandatory = $true)]
        [String] $urlPath,
        [Parameter(Mandatory = $true)]
        [String] $filename
    )
    $url = $($urlPath.Trim()+$filename.Trim())
    "Start-BitsTransfer -Source $($url) -Destination $($SP2016PreReqsPath)"
    Start-BitsTransfer -Source $($url) -Destination $SP2016PreReqsPath
    
}
$PreReqs = @{
    'sqlncli.msi' = 'https://download.microsoft.com/download/F/E/D/FEDB200F-DE2A-46D8-B661-D019DFE9D470/ENU/x64/';
    'msodbcsql.msi' = 'https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/';
    'SyncSetup_en.x64.zip ' = 'https://download.microsoft.com/download/B/9/D/B9D6E014-C949-4A1E-BA6B-2E0DEBA23E54/';
    'WindowsServerAppFabricSetup_x64.exe ' = 'https://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/';
    'AppFabric-KB3092423-x64-ENU.exe' = 'https://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/';
    'MicrosoftIdentityExtensions-64.msi' = 'https://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/';
    'setup_msipc_x64.exe' = 'https://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/';
    'NDP453-KB2969351-x86-x64-AllOS-ENU.exe' = 'https://download.microsoft.com/download/2/8/7/2870C339-3C77-49CF-8DDF-AD6189AB8597/';
    'vcredist_x64.exe' = 'https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/';
    'vc_redist.x64.exe' = 'https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/';
    'WcfDataServices.exe' = 'https://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/'
}

if ((Test-Dir -DirectoryToTest $SP2016PreReqsPath -DirectoryCreate $true) -and
    (Test-Dir -DirectoryToTest $SP2016InstallPath -DirectoryCreate $false))
{
    $PreReqs.Keys | ForEach-Object {
        Start-PreReqsTansfer -filename $_ -url $PreReqs[$_]
    }


    if (-not ($SP2016PreReqsPath -match '\\$'))
    {
        $SP2016PreReqsPath += '\'
    }

    if (-not ($SP2016InstallPath -match '\\$'))
    {
        $SP2016InstallPath += '\'
    }

    Start-Unzip -zip "$($SP2016PreReqsPath)SyncSetup_en.x64.zip" -outpath $SP2016PreReqsPath
    Move-Item -Path "$($SP2016PreReqsPath)Microsoft Sync Framework\Synchronization.msi" -Destination $SP2016PreReqsPath
    if ($?) {
        Remove-Item -Force -Recurse -Path "$($SP2016PreReqsPath)Microsoft Sync Framework"
        Remove-Item -Force -Path "$($SP2016PreReqsPath)SyncSetup_en.x64.zip"
    }

    Remove-Item -Force -Recurse -Path "$($SP2016PreReqsPath)DotNetFx"
    Remove-Item -Force -Recurse -Path "$($SP2016PreReqsPath)Microsoft Sync Framework SDK"
    Remove-Item -Force -Recurse -Path "$($SP2016PreReqsPath)Microsoft Sync Framework Services"
    Remove-Item -Force -Recurse -Path "$($SP2016PreReqsPath)Microsoft Sync Services for ADO"

    Start-Process "$($SP2016InstallPath)PrerequisiteInstaller.exe" -ArgumentList "/SQLNCli:$($SP2016PreReqsPath)sqlncli.msi /IDFX11:$($SP2016PreReqsPath)MicrosoftIdentityExtensions-64.msi /Sync:$($SP2016PreReqsPath)Synchronization.msi /AppFabric:$($SP2016PreReqsPath)WindowsServerAppFabricSetup_x64.exe /MSIPCClient:$($SP2016PreReqsPath)setup_msipc_x64.exe /WCFDataServices56:$($SP2016PreReqsPath)WcfDataServices.exe /DotNetFx:$($SP2016PreReqsPath)NDP453-KB2969351-x86-x64-AllOS-ENU.exe /MSVCRT11:$($SP2016PreReqsPath)vcredist_x64.exe /MSVCRT14:$($SP2016PreReqsPath)vc_redist.x64.exe /KB3092423:$($SP2016PreReqsPath)AppFabric-KB3092423-x64-ENU.exe /ODBC:$($SP2016PreReqsPath)msodbcsql.msi"
}