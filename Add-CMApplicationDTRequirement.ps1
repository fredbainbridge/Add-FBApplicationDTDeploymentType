<#
This will append one more OS Requirements to an existing app deployment.
#>

[CmdletBinding()]
param (
    $siteCode = "PS1",
    $siteServer = "cm01.cm.lab",
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    $appName = "test",
    $requirement = "Windows/All_x86_Windows_8.1_Client"
)

begin {
import-module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1' -force #make this work for you
if ((get-psdrive $sitecode -erroraction SilentlyContinue | measure).Count -ne 1) {
    new-psdrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
}
set-location $sitecode`:
}

process {
$Appdt = Get-CMApplication -Name $appName 
$xml = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($appdt.SDMPackageXML,$True)
$numDTS = $xml.DeploymentTypes.count
$dts = $xml.DeploymentTypes
foreach ($dt in $dts)
{
    foreach($requirement in $dt.Requirements)
    {
        if($requirement.Expression.gettype().name -eq 'OperatingSystemExpression') 
        {
            write-host "found an OS Requirement, appending value to it"
            $requirement.Expression.Operands.Add("Windows/All_x86_Windows_8.1_Client")
            $requirement.Name = $requirement.Name + ", All Windows 8.1 (32-bit)" 
        }
    }
}

$UpdatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($XML, $True) 
$appdt.SDMPackageXML = $UpdatedXML 
Set-CMApplication -InputObject $appDT

}

end
{
set-location $env:SystemDrive
}