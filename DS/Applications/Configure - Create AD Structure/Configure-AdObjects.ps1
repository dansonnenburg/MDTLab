Function New-cADOU {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][Alias('OU')][String[]]$Name,
        [parameter(Mandatory=$true,Position=2,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][String]$RootDomain
    )
    BEGIN {}
    PROCESS {
        ForEach ($item in $Name) {
            $objADSI = [ADSI]"LDAP://$RootDomain"
            $objOU = $objADSI.create("organizationalUnit", $item)
            $objOU.setInfo()
        }
    }
    END {}
}
Function New-cADUser {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][Alias('SAMAccountName')][String[]]$Name,
        [parameter(Mandatory=$true,Position=2,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][String]$Password,
        [parameter(Mandatory=$true,Position=3,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][ADSI]$OU,
        [parameter(Position=4,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][String]$Description
    )
    BEGIN {}
    PROCESS {
        ForEach ($item in $Name) {
            $new = $OU.Create("User", "CN=$item")
            $new.put("SAMAccountName", "$item")
            $new.setinfo()
            $new.put("Description", "$Description")
            $new.SetPassword("$Password")
            $new.Put("userAccountControl", 66048)
            $new.setinfo()
        }
    }
    END {}
}
Function New-cADGroup {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][Alias('SAMAccountName')][String[]]$Name,
        [parameter(Mandatory=$true,Position=2,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][ADSI]$OU,
        [parameter(Position=3,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][String]$Description
    )
    BEGIN {}
    PROCESS {
        ForEach ($item in $Name) {
            $Group = $OU.Create('Group',"CN=$item")
            $Group.SetInfo()
            $Group.put("Description", "$Description")
            $Group.SetInfo()
        }
    }
    END {}
}
$OUs = Import-Csv -Delimiter "," -Path ".\AD_OUs.csv"
$OUs | New-cADOU

$Users = Import-Csv -Delimiter "," -Path ".\AD_Users.csv"
$Users | New-cADUser

$Groups = Import-Csv -Delimiter "," -Path ".\AD_Groups.csv"
$Groups | New-cADGroup