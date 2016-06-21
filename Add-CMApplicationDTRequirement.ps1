#region namevalidateset

#endregion NameValidateSet
function Add-FBApplicationDTRequirement {
<#
.SYNOPSIS
Add an additional OS deployment to an existing OS requirement for a Deployment Type
.DESCRIPTION
This is especially useful if you have a lot of applications that have existing OS requirements attached to deployment
types and you want to add another.  i.e. Windows 10 just came.  There must already be an OS requirement for the deployment 
type for this to work.
This needs to be run on a system that has the ConfigMgr console installed and it assumes it is installed here - 
  'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
  Modify the begin statement to change this.
This will attempt to add the OS requirement only if it finds an existing OS requirement.
This will attempt to add the OS requirement to each deployment type it finds.
.EXAMPLE
Add-FBApplicationDTRequirement -appName "Microsoft Office 2016 x86" -siteCode "lab" -siteserver "cm01.cm.lab" -Requirement "All Windows 10 (64-bit)"
.EXAMPLE
$appNames | Add-FBApplicationDTRequirement -siteCode "lab" -siteserver "cm01.cm.lab" -Requirement "All Windows 10 (64-bit)"
.PARAMETER appName
This is the name of the configmgr application that has the deployment types that you want to add the OS requirement to. This accepts input from pipeline.
.PARAMETER siteCode
This the ConfigMgr site code you are working with. Defaults to LAB
.PARAMETER siteServer
This the site server you are going to working with.  WMI calls are made to this server.  It is most likely your primary site server.
#>
[CmdletBinding()]
param (
    [Parameter(
        Position=0,
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)       
    ]
    $appName,
    $siteCode = "LAB",
    $siteServer = "cm01.cm.lab"   
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
    #write-host $ValidateSet.ValidValues
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
Write-Verbose "Operand $operand"
Write-Verbose "Requirement $namedRequirement"
foreach ($dt in $dts)
{
    foreach($requirement in $dt.Requirements)
    {
        if($requirement.Expression.gettype().name -eq 'OperatingSystemExpression') 
        {
            write-verbose "found an OS Requirement, appending value to it"
            
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
 set-location c:
}
}