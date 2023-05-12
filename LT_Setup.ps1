function winget_remove {
    param (
        [string]$PackageID
    )
    Write-Verbose -Message "Removing $PackageID"
    winget remove --id "$PackageID"
}

function winget_install {
    param (
        [string]$PackageID
    )
    Write-Verbose -Message "Installing $PackageID"
    winget install --id "$PackageID" --accept-source-agreements --accept-package-agreements --include-unknown
}

$VerbosePreference = "Continue"

set-ExecutionPolicy -Scope CurrentUser Unrestricted


###       Disable Mouse Acceleration       ###
Write-Verbose -Message "Disabling enhanced pointer precision."
$RegConnect = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"CurrentUser","$env:COMPUTERNAME")
$RegMouse = $RegConnect.OpenSubKey("Control Panel\Mouse",$true)
$acc_enabled = $RegMouse.GetValue("MouseSpeed")
if ( $acc_enabled -eq 1 ) {
    # mouse acc is enabled -> disable mouse acc
    $RegMouse.SetValue("MouseSpeed","0")
    $RegMouse.SetValue("MouseThreshold1","0")
    $RegMouse.SetValue("MouseThreshold2","0") }
$RegMouse.Close()
$RegConnect.Close()
$code='[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, int[] pvParam, uint fWinIni);'
Add-Type $code -name Win32 -NameSpace System
[System.Win32]::SystemParametersInfo(4,0,0,2) | Out-Null


### Show File Extensions and Taskbar Icons ###
# http://superuser.com/questions/666891/script-to-set-hide-file-extensions
Push-Location
Set-Location HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
Set-ItemProperty . HideFileExt "0"
Pop-Location
Write-Verbose -Message "Updating registry key to always show all taskbar items..."
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
If ( !(Test-Path $registryPath) ) {New-Item -Path $registryPath -Force; }
New-ItemProperty -Path $registryPath -Name "EnableAutoTray" -PropertyType DWORD -Value 0 -Force


###       Set Dark Theme and Wallpaper      ###
# set "app" system mode to "dark"
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0 -Type Dword -Force; 
# set "OS" system mode to "dark"
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0 -Type Dword -Force;
# download and set wallpaper
$wallPath = Join-Path $env:userprofile '\Pictures\ThinkPadThai.png'
Invoke-WebRequest -Uri "https://i.redd.it/ch2v368i8bta1.png" -UseBasicParsing -OutFile $wallPath
$code = @' 
using System.Runtime.InteropServices; 
namespace Win32{ 
    
     public class Wallpaper{ 
        [DllImport("user32.dll", CharSet=CharSet.Auto)] 
         static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ; 
         
         public static void SetWallpaper(string thePath){ 
            SystemParametersInfo(20,0,thePath,3); 
         }
    }
 } 
'@
add-type $code
[Win32.Wallpaper]::SetWallpaper($wallPath)
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallPaper -Value $wallPath -Force
rundll32.exe user32.dll, UpdatePerUserSystemParameters 1
# set accent color per wallpaper
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name ColorPrevalence -Value 1 -Type Dword -Force;


###    Hide Search, Cortana, Task View     ###
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name TraySearchBoxVisible -Value 0 -Type Dword -Force;
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0 -Type Dword -Force;
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name TraySearchBoxVisibleOnAnyMonitor -Value 0 -Type Dword -Force;
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowCortanaButton -Value 0 -Type Dword -Force;
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0 -Type Dword -Force;

Stop-Process -processName: Explorer -force


###              Update Windows            ###
# https://woshub.com/pswindowsupdate-module/#h2_2
Install-Module PSWindowsUpdate
Get-WUInstall


###      Perhaps stronger than WinGet      ###
# https://learn.microsoft.com/en-us/powershell/gallery/powershellget/install-powershellget
Install-Module PowerShellGet -Force -AllowClobber
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
. $profile # not sure if this step is necessary
Install-Module winget-install -Force


###  Finally, quick Windows Defender scan  ###
Write-Verbose -Message "Running Windows Defender quick scan"
Start-MpScan -AsJob -ScanType QuickScan


$winget_packages = @(
    "Microsoft.DotNet.DesktopRuntime.3_1",
    "Microsoft.DotNet.DesktopRuntime.5",
    "Microsoft.DotNet.DesktopRuntime.6",
    "Microsoft.DotNet.DesktopRuntime.7",
    "Microsoft.PowerToys",,
    #"chrisant996.Clink",
    "Balena.Etcher",
    "Google.Chrome",
    "Google.Drive",
    "Opera.Opera",
    "Lexikos.AutoHotkey",
    "Zwift.Zwift",
    "Git.Git",
    "Mojang.MinecraftLauncher",
    "Microsoft.OneDrive",
    "Ditto.Ditto",
    "Discord.Discord",
    "BitTorrent",
    "TechPowerUp.GPU-Z",
    "CPUID.CPU-Z",
    "Valve.Steam",
    "Spotify.Spotify",
    "RiotGames.LeagueOfLegends.NA"
)

foreach ($item in $winget_packages) {
   winget_install -Package "$item"
   }

$PSGallery_install = @(
    "PSWritePDF" # Little project to create, read, modify, split, merge PDF files
)

$winget_remove = @(
    "Microsoft.YourPhone_8wekyb3d8bbwe",
    "Microsoft.ZuneMusic_8wekyb3d8bbwe",
    "Microsoft.ZuneVideo_8wekyb3d8bbwe",
    "microsoft.windowscommunicationsapps_8wekyb3d8bbwe",
    "Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe",
    "Microsoft.WindowsMaps_8wekyb3d8bbwe",
    "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe",
    "Microsoft.Wallet_8wekyb3d8bbwe",
    "Microsoft.SkypeApp_kzf8qxf38zg5c",
    "Microsoft.People_8wekyb3d8bbwe",
    "Microsoft.MixedReality.Portal_8wekyb3d8bbwe",
    "Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe",
    "Microsoft.Microsoft3DViewer_8wekyb3d8bbwe",
    "Microsoft.MSPaint_8wekyb3d8bbwe",
    "Microsoft.Getstarted_8wekyb3d8bbwe",
    "Microsoft.GetHelp_8wekyb3d8bbwe"
    "Microsoft.549981C3F5F10_8wekyb3d8bbwe", # Cortana
    "Microsoft.BingWeather_8wekyb3d8bbwe",
    "Disney.37853FC22B2CE_6rarf9sa4v8jt"
)

foreach ($item in $winget_remove) {
    winget_remove -PackageID "$item"
    }
