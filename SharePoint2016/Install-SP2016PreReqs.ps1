Add-Type -AssemblyName System.IO.Compression.FileSystem
function Start-Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

$SharePoint2016Path = "C:\software\SP2016PreReqs\"
$SharePoint2016InstallPath = "E:\"

if(!(Test-Path -Path $SharePoint2016Path )){
    New-Item -ItemType directory -Path $SharePoint2016Path
}

Start-BitsTransfer -Source https://download.microsoft.com/download/F/E/D/FEDB200F-DE2A-46D8-B661-D019DFE9D470/ENU/x64/sqlncli.msi -Destination $SharePoint2016Path
Start-BitsTransfer -Source https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi -Destination $SharePoint2016Path
#Unizip and extract Synchronization.msi from this zip
Start-BitsTransfer -Source https://download.microsoft.com/download/B/9/D/B9D6E014-C949-4A1E-BA6B-2E0DEBA23E54/SyncSetup_en.x64.zip -Destination $SharePoint2016Path
Start-BitsTransfer -Source https://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe -Destination $SharePoint2016Path
Start-BitsTransfer -Source https://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/AppFabric-KB3092423-x64-ENU.exe -Destination $SharePoint2016Path
Start-BitsTransfer -Source https://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi -Destination $SharePoint2016Path
Start-BitsTransfer -Source https://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/setup_msipc_x64.exe  -Destination $SharePoint2016Path
Start-BitsTransfer -Source https://download.microsoft.com/download/8/F/9/8F93DBBD-896B-4760-AC81-646F61363A6D/WcfDataServices.exe -Destination $SharePoint2016Path
Start-BitsTransfer -Source https://download.microsoft.com/download/2/8/7/2870C339-3C77-49CF-8DDF-AD6189AB8597/NDP453-KB2969351-x86-x64-AllOS-ENU.exe -Destination $SharePoint2016Path
Start-BitsTransfer -Source https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe -Destination $SharePoint2016Path
Start-BitsTransfer -Source https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe -Destination $SharePoint2016Path

Start-Unzip -zip "$($SharePoint2016Path)SyncSetup_en.x64.zip" -outpath $SharePoint2016Path
Move-Item -Path "$($SharePoint2016Path)Microsoft Sync Framework\Synchronization.msi" -Destination $SharePoint2016Path
if($?)
{
    Remove-Item -Force -Recurse -Path "$($SharePoint2016Path)Microsoft Sync Framework"
    Remove-Item -Force -Path "$($SharePoint2016Path)SyncSetup_en.x64.zip"
}

Remove-Item -Force -Recurse -Path "$($SharePoint2016Path)DotNetFx"
Remove-Item -Force -Recurse -Path "$($SharePoint2016Path)Microsoft Sync Framework SDK"
Remove-Item -Force -Recurse -Path "$($SharePoint2016Path)Microsoft Sync Framework Services"
Remove-Item -Force -Recurse -Path "$($SharePoint2016Path)Microsoft Sync Services for ADO"

Start-Process "$($SharePoint2016InstallPath)PrerequisiteInstaller.exe" -ArgumentList "/SQLNCli:$($SharePoint2016Path)sqlncli.msi /IDFX11:$($SharePoint2016Path)MicrosoftIdentityExtensions-64.msi /Sync:$($SharePoint2016Path)Synchronization.msi /AppFabric:$($SharePoint2016Path)WindowsServerAppFabricSetup_x64.exe /MSIPCClient:$($SharePoint2016Path)setup_msipc_x64.exe /WCFDataServices56:$($SharePoint2016Path)WcfDataServices.exe /DotNetFx:$($SharePoint2016Path)NDP453-KB2969351-x86-x64-AllOS-ENU.exe /MSVCRT11:$($SharePoint2016Path)vcredist_x64.exe /MSVCRT14:$($SharePoint2016Path)vc_redist.x64.exe /KB3092423:$($SharePoint2016Path)AppFabric-KB3092423-x64-ENU.exe"