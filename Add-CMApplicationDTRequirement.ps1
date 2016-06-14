#region namevalidateset

#endregion NameValidateSet
function Add-FBApplicationDTRequirement {
[CmdletBinding()]
param (
    $siteCode = "LAB",
    $siteServer = "cm01.cm.lab",
    [Parameter(
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)       
    ]
    $appName = "Microsoft CMTrace"
)

dynamicparam {
    $attributes = new-object System.Management.Automation.ParameterAttribute
    $attributes.ParameterSetName = "__AllParameterSets"
    $attributes.Mandatory = $true
    $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)
    $values =   Get-Content .\NameValidateSet.txt | ForEach-Object {
                    "$($PSItem.Split(",")[0])" 
                } 
    $ValidateSet = new-object System.Management.Automation.ValidateSetAttribute($values)
    write-host $ValidateSet.ValidValues
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

#create the hash
$NamedPairs = @{};
Get-Content .\NameValidateSet.txt | ForEach-Object {
    $name = $PSItem.Split(",")[0]
    $operand = $PSItem.Split(",")[1]
    $NamedPairs.Add($name, $operand)
}

set-location $sitecode`:

}

process {
$Appdt = Get-CMApplication -Name $appName 
$xml = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($appdt.SDMPackageXML,$True)

$numDTS = $xml.DeploymentTypes.count
$dts = $xml.DeploymentTypes

$operand = $NamedPairs[$dynParam1.Value].trim()
$namedRequirement = $dynParam1.Value
foreach ($dt in $dts)
{
    foreach($requirement in $dt.Requirements)
    {
        if($requirement.Expression.gettype().name -eq 'OperatingSystemExpression') 
        {
            write-host "found an OS Requirement, appending value to it"
            $requirement.Expression.Operands.Add("$operand")
            $requirement.Name = $requirement.Name + ", $namedRequirement" 
        }
    }
}
$UpdatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($XML, $True) 
$appdt.SDMPackageXML = $UpdatedXML 
Set-CMApplication -InputObject $appDT

}

end
{

}
}