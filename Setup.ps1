Param (
    $DriveLetter = 'D:',
    $LabKit = (Join-Path $DriveLetter "MDTLab"),
    $DeploymentShare = (Join-Path $LabKit "DS")
)
#Configure some additional variables
$ISODir = Join-Path $Labkit "ISO"

# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Error: You must run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
	Write-Warning "Aborting script..."
    Break
}
# Verify that MDT is installed
if (!((Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "Microsoft Deployment Toolkit*"}).Displayname).count) {
    #Download Microsoft Deployment Toolkit
    Start-BitsTransfer -Source https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi `
        -Destination .\MicrosoftDeploymentToolkit_x64.msi

    #Install Microsoft Deployment Toolkit
    Start-Process msiexec.exe -Wait -ArgumentList '/I .\MicrosoftDeploymentToolkit_x64.msi /qb'
}

# Verify that Windows ADK 10 is installed 
if (!((Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "Windows Assessment and Deployment Kit - Windows 10"}).Displayname).count) {
    #Download ADK
    Start-BitsTransfer -Source http://download.microsoft.com/download/0/1/C/01CC78AA-B53B-4884-B7EA-74F2878AA79F/adk/adksetup.exe `
        -Destination .\adksetup.exe
    #Download Windows PE add-on for the ADK
    Start-BitsTransfer -Source http://download.microsoft.com/download/D/7/E/D7E22261-D0B3-4ED6-8151-5E002C7F823D/adkwinpeaddons/adkwinpesetup.exe `
        -Destination .\adkwinpesetup.exe

    #Install ADK
    Start-Process adksetup.exe -Wait -ArgumentList '/Features OptionId.DeploymentTools OptionId.UserStateMigrationTool OptionId.ImagingAndConfigurationDesigner /norestart /quiet /ceip off'
    #Install WinPE add-on for ADK
    Start-Process adkwinpesetup.exe -Wait -ArgumentList '/features + /q'
}

# Verify that the deployment share doesn't exist
If (Get-SmbShare | Where-Object { $_.Name -eq "MDTLab$"}){
    Remove-SmbShare –Name 'MDTLab$' -Force
}
if (Test-Path -Path "$DeploymentShare") {Write-Warning "$DeploymentShare already exist, please cleanup and try again. Aborting...";Break}
if (Test-Path -Path "$ISODir") {Write-Warning "$ISODir already exists, please cleanup and try again. Aborting...";Break}

# Validation, verify that the PSDrive doesnt exist already
if (Test-Path -Path "DS001:") {Write-Warning "DS001: PSDrive already exist, please cleanup and try again. Aborting...";Break}

# CreateDeployment Share
$MDTServer = (get-wmiobject win32_computersystem).Name

Add-PSSnapIn Microsoft.BDD.PSSnapIn -ErrorAction SilentlyContinue 
New-Item -Path $DeploymentShare -ItemType Directory
New-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "$DeploymentShare"-Description "Lab ConfigMgr" -NetworkPath "\\$MDTServer\MDTLab$" | Add-MDTPersistentDrive
New-SmbShare –Name MDTLab$ –Path "$DeploymentShare" –ChangeAccess EVERYONE

New-Item -Path $ISODir\Content\Deploy -ItemType Directory
New-Item -Path "DS001:\Media" -enable "True" -Name "MEDIA001" -Comments "" -Root "$ISODir" -SelectionProfile "Everything" -SupportX86 "False" -SupportX64 "True" -GenerateISO "True" -ISOName "MDTLab.iso"
New-PSDrive -Name "MEDIA001" -PSProvider "MDTProvider" -Root "$ISODir\Content\Deploy" -Description "Lab ConfigMgr Media" -Force

# Configure MEDIA001 Settings (disable MDAC) - Not needed in the Lab Kit
Set-ItemProperty -Path MEDIA001: -Name Boot.x86.FeaturePacks -Value ""
Set-ItemProperty -Path MEDIA001: -Name Boot.x64.FeaturePacks -Value ""

# Copy customized files to Lab Deployment Share
Copy-Item -Path ".\DS\" -Destination "$LabKit" -Recurse -Force

#Copy CustomSettings files for ISO image
Copy-Item -Path ".\ISO\" -Destination "$LabKit" -Recurse -Force