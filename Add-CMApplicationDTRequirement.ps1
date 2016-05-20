<#
This will append one more OS Requirements to an existing app deployment.
Possible RuleIDs
Windows/All_x86_Windows_XP                                                                                                  
Windows/x64_Windows_XP_Professional_SP2                                                                                     
Windows/x86_Windows_XP_Professional_Service_Pack_3                                                                          
Windows/All_x64_Windows_Vista                                                                                               
Windows/All_x86_Windows_Vista                                                                                               
Windows/x64_Windows_Vista_SP2                                                                                               
Windows/x86_Windows_Vista_SP2                                                                                               
Windows/All_x64_Windows_7_Client                                                                                            
Windows/All_x86_Windows_7_Client                                                                                            
Windows/x64_Windows_7_Client                                                                                                
Windows/x64_Windows_7_SP1                                                                                                   
Windows/x86_Windows_7_Client                                                                                                
Windows/x86_Windows_7_SP1                                                                                                   
Windows/All_ARM_Windows_8_Client                                                                                            
Windows/All_x64_Windows_8_Client                                                                                            
Windows/All_x86_Windows_8_Client                                                                                            
Windows/All_ARM_Windows_8.1_Client                                                                                          
Windows/All_x64_Windows_8.1_Client                                                                                          
Windows/All_x86_Windows_8.1_Client                                                                                          
Windows/All_x64_Windows_10_and_higher_Clients                                                                               
Windows/All_x86_Windows_10_and_higher_Clients                                                                               
Windows/All_x64_Windows_Server_2003_Non_R2                                                                                  
Windows/All_x64_Windows_Server_2003_R2                                                                                      
Windows/All_x86_Windows_Server_2003_Non_R2                                                                                  
Windows/All_x86_Windows_Server_2003_R2                                                                                      
Windows/x64_Windows_Server_2003_R2_SP2                                                                                      
Windows/x64_Windows_Server_2003_SP2                                                                                         
Windows/x86_Windows_Server_2003_R2_SP2                                                                                      
Windows/x86_Windows_Server_2003_SP2                                                                                         
Windows/All_x64_Windows_Server_2008                                                                                         
Windows/All_x64_Windows_Server_2008_R2                                                                                      
Windows/All_x86_Windows_Server_2008                                                                                         
Windows/x64_Windows_Server_2008_R2                                                                                          
Windows/x64_Windows_Server_2008_R2_CORE                                                                                     
Windows/x64_Windows_Server_2008_R2_SP1                                                                                      
Windows/x64_Windows_Server_2008_R2_SP1_Core                                                                                 
Windows/x64_Windows_Server_2008_SP2                                                                                         
Windows/x64_Windows_Server_2008_SP2_Core                                                                                    
Windows/x86_Windows_Server_2008_SP2                                                                                         
Windows/All_x64_Windows_Server_8                                                                                            
Windows/All_x64_Windows_Server_2012_R2                                                                                      
Windows/All_Embedded_Windows_XP                                                                                             
Windows/All_x64_Windows_Embedded_8.1_Industry                                                                               
Windows/All_x64_Windows_Embedded_8_Industry                                                                                 
Windows/All_x64_Windows_Embedded_8_Standard                                                                                 
Windows/All_x86_Windows_Embedded_8.1_Industry                                                                               
Windows/All_x86_Windows_Embedded_8_Industry                                                                                 
Windows/All_x86_Windows_Embedded_8_Standard                                                                                 
Windows/x64_Embedded_Windows_7                                                                                              
Windows/x86_Embedded_Windows_7  
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
    $requirementName = "All Windows 8.1 (32-bit)"
    #make intellisense work here for all options.
    #$requirementoperand = "Windows/All_x86_Windows_8.1_Client" 
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