# Modified by Daniel Sonnenburg
param (
    $ISO
)

function New-HyperVSwitch {
    # Create virtual switch if it doesn't exist
    if (Get-VMSwitch | where {$_.Name -eq $VMNetwork}){
        Write-Output "$VMNetwork VMSwitch already exists!"
    } else {
        New-VMSwitch $VMNetwork -SwitchType Internal
        New-NetIPAddress –IPAddress 192.168.1.1 -PrefixLength 24 -InterfaceAlias "vEthernet (NAT)" 
        New-NetNat –Name NATNetwork –InternalIPInterfaceAddressPrefix 192.168.1.0/24
    }
}

function New-LabKitVM{
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $true)][string]$VMName,
        [Parameter(Mandatory = $true)]$VMMemory,
        [Parameter(Mandatory = $true)]$VMDiskSize,
        [Parameter(Mandatory = $true)][string]$VMISO,
        [Parameter()][string]$VMLocation = 'C:\ProgramData\Microsoft\Windows\Hyper-V',        
        [Parameter()][string]$VMNetwork = 'NAT'
    )
    New-HyperVSwitch
    if (Get-VM | where {$_.Name -eq $VMName}){
        Write-Output "$VMName already exists!"
    } else {
        New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD -Verbose
        #If there is an old drive present, delete it.
        Remove-Item -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"
        New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize -Verbose
        Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -Verbose
        Set-VMProcessor -VMName $VMName -Count 2
        Set-VMDvdDrive -VMName $VMName -Path $VMISO -Verbose
        set-vm -Name $VMName -AutomaticStopAction ShutDown
    }
}

New-LabKitVM -VMName 'CM01' -VMMemory 6144MB -VMDiskSize 300GB -VMISO $ISO
New-LabKitVM -VMName 'CM02' -VMMemory 6144MB -VMDiskSize 300GB -VMISO $ISO
New-LabKitVM -VMName 'DC01' -VMMemory 2048MB -VMDiskSize 60GB -VMISO $ISO
New-LabKitVM -VMName 'MDT01' -VMMemory 4096MB -VMDiskSize 300GB -VMISO $ISO
New-LabKitVM -VMName 'MDT02' -VMMemory 4096MB -VMDiskSize 300GB -VMISO $ISO
New-LabKitVM -VMName 'WSUS01' -VMMemory 2048MB -VMDiskSize 300GB -VMISO $ISO
New-LabKitVM -VMName 'PC01' -VMMemory 1024MB -VMDiskSize 60GB -VMISO $ISO
New-LabKitVM -VMName 'PC02' -VMMemory 1024MB -VMDiskSize 60GB -VMISO $ISO
New-LabKitVM -VMName 'PC03' -VMMemory 1024MB -VMDiskSize 60GB -VMISO $ISO