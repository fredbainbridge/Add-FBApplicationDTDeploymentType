#region namevalidateset

#endregion NameValidateSet
function Add-FBApplicationDTRequirement {
[CmdletBinding()]
param (
    $siteCode = "PS1",
    $siteServer = "cm01.cm.lab",
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)       
    ]
    $appName = "test"
)

dynamicparam {
    $attributes = new-object System.Management.Automation.ParameterAttribute
    $attributes.ParameterSetName = "__AllParameterSets"
    $attributes.Mandatory = $true
    $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)
    $values =   Get-Content .\NameValidateSet.txt | ForEach-Object {
                    $PSItem.Split(",")[0]
                } 
    $ValidateSet = new-object System.Management.Automation.ValidateSetAttribute($values)
    $attributeCollection.Add($ValidateSet)

    $dynParam1 = new-object -Type System.Management.Automation.RuntimeDefinedParameter("Requirement", [string], $attributeCollection)
    $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add("Requirement", $dynParam1)
    return $paramDictionary 
}
    
begin {
import-module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1' -force #make this work for you
if ((get-psdrive $sitecode -erroraction SilentlyContinue | measure).Count -ne 1) {
    new-psdrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
}
set-location $sitecode`:
#create the hash
$NamedPairs = @{};
Get-Content .\NameValidateSet.txt | ForEach-Object {
    $name = $PSItem.Split(",")[0]
    $operand = $PSItem.Split(",")[1]
    $NamedPairs.Add($name, $operand)
}

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
}