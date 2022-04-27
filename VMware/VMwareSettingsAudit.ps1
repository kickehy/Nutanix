<#
.NOTES
    Author: Brad Meyer
    Contributor: Jason Stenack
    Date:   April 27, 2022

    ###############################################-----LICENSE-----#######################################################
      BSD 3-Clause License

      Copyright (c) 2022, Brad Meyer
      All rights reserved.

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions are met:

      1. Redistributions of source code must retain the above copyright notice, this
           list of conditions and the following disclaimer.

      2. Redistributions in binary form must reproduce the above copyright notice,
          this list of conditions and the following disclaimer in the documentation
          and/or other materials provided with the distribution.

      3. Neither the name of the copyright holder nor the names of its
          contributors may be used to endorse or promote products derived from
          this software without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
      AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
      DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
      FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
      DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
      SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
      CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
      OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    ######################################################################################################################
.SYNOPSIS
    Gathers VMware cluster info on HA, DRS, VM Overrides for CVMs, and a few other settings for Nutanix clusters and exports it into an Excel spreadsheet.
.DESCRIPTION
    Gathers VMware cluster info on HA, DRS, VM Overrides for CVMs, and a few other settings for Nutanix clusters and exports it into an Excel spreadsheet.

    HA Information Gathered:
        Custer Name
        HA Enabled
        Host Monitoring
        Host Failure Response
        Host Isolation Response
        Datastore with PDL
        Datastore with APD
        VM Monitoring
        Admission Control
        Host Failures Cluster Tolerates
        Host Failover Capacity Policy
        Override Calculated Failover Capacity
        (Override) CPU %
        (Override) Memory %
        Performance Degradation VMs Tolerate
        Heartbeat Selection Policy
        Heartbeat Datastores
        Advanced Options
        Proactive HA

    DRS Information Gathered:
        Custer Name
        vSphere DRS Enabled
        Automation Level
        Migration Threshold
        Predictive DRS
        Virtual Machine Automation
        VM Distribution
        Memory Metric for Load Balancing
        CPU Over-Commitment
        DPM
        Advanced Options

    Other Settings Information Gathered:
        Cluster Name
        EVC Mode
        VM Swap File Policy

    VM Overrides Information Gathered:
        Cluster Name
        Cluster Node Total
        VMO Total (this is the number of VM Overrides for CVMs and should equal the Node Total)
        Virtual Machine Name
        vSphere DRS Automation Level
        VM Restart Priority
        Host Isolation Response (Only comes into play if VM Restart Priority is NOT Disabled)
        VM Monitoring
.PARAMETER pclist
    List of Prism Centrals, comma separated, to run the script against.
    Ex. -pclist pc1.domain.com,pc2.domain.com,10.10.10.10
    Alias: -pcl
.PARAMETER credman
    This will cause the script to look for credentials to be supplied via Windows Credential Manager.
    The following Generic Credentials are expected:
        vCenter_Creds
        NTNX_Prism
.PARAMETER vcusername
    Specifies the username that will be used to authenticate against vCenter.
    Must use single quotes when specifying otherwise you may have unexpected results: -vcusername 'username@domain.com'
    Alias: -vcu
.PARAMETER vcpwd
    Specifies the password that will be used to authenticate against vCenter.
    Must use single quotes when specifying otherwise you may have unexpected results: -vcpwd 'Pa$$w0rd'
    Alias: -vcp
.PARAMETER prismusername
    Specifies the username that will be used to authenticate against both Prism Central and Prism Element.
    Must use single quotes when specifying otherwise you may have unexpected results: -prismusername 'username@domain.com'
    Alias: -pu
.PARAMETER prismpwd
    Specifies the password that will be used to authenticate against both Prism Central and Prism Element.
    Must use single quotes when specifying otherwise you may have unexpected results: -vcpwd 'Pa$$w0rd'
    Alias: -pp
.PARAMETER filepath
    Specifies report location for the script.
    Ex. -filepath 'C:\reports'
    Alias: -fp
.EXAMPLE
    VMwareSettingsAudit.ps1 -pclist pc01.domain.com,10.10.10.10 -vcusername 'username@domain.com' -vcpwd 'Pa$$w0rd' -prismusername 'username@domain.com' -prismpwd 'Pa$$w0rd' -filepath 'C:\Reports'

    Pulls VMware settings info from Prism Centrals pc01.domain.com and 10.10.10.10 and saves the report to C:\Reports.
.EXAMPLE
    VMwareSettingsAudit.ps1 -pclist pc01.domain.com,10.10.10.10 -credman -filepath 'C:\Reports'

    Pulls VMware settings info from Prism Centrals pc01.domain.com and 10.10.10.10 using credentials stored in Windows Credential manager and saves the report to C:\Reports.
#>

##################################################################################
############################## Region - Params ###################################
param (
    [Parameter(Mandatory=$true,Position=0)]
    [Alias("pcl")]
    [string[]] $pclist,
    [Parameter(ParameterSetName="CredMan", Mandatory=$true)]
    [switch] $credman,
    [Parameter(ParameterSetName="Prompt", Mandatory=$true)]
    [Alias("vcu")]
    [string] $vcusername,
    [Parameter(ParameterSetName="Prompt", Mandatory=$true)]
    [Alias("vcp")]
    [string] $vcpwd,
    [Parameter(ParameterSetName="Prompt", Mandatory=$true)]
    [Alias("pu")]
    [string] $prismusername,
    [Parameter(ParameterSetName="Prompt", Mandatory=$true)]
    [Alias("pp")]
    [string] $prismpwd,
    [Parameter(Mandatory=$true)]
    [Alias("fp")]
    [string] $filepath
)
############################## End Region - Params ###############################
##################################################################################


##################################################################################
############################## Region - Modules ##################################
# Verify modules required are installed and exit if anything is missing
$missingmodule = 0
if ($null -eq (Get-InstalledModule -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue)) {
    Write-Warning "Required module 'VMware.PowerCLI' is missing. Please install."
    $missingmodule = 1
}
if ($null -eq (Get-InstalledModule -Name "ImportExcel" -ErrorAction SilentlyContinue)) {
    Write-Warning "Required module 'ImportExcel' is missing. Please install."
    $missingmodule = 1
}
if ($credman -eq $true) {
    if ($null -eq (Get-InstalledModule -Name "CredentialManager" -ErrorAction SilentlyContinue)) {
        Write-Warning "Required module 'CredentialManager' is missing. Please install."
        $missingmodule = 1
    }
}
if ($missingmodule -eq 1) {
    Write-Error "Exiting script due to missing modules..."
    Exit
}
# Import required modules if all modules are installed
Import-Module VMware.PowerCLI | Out-Null
Import-Module ImportExcel
if ($credman -eq $true) {
    Import-Module CredentialManager
}
############################## End Region - Modules ##############################
##################################################################################


##################################################################################
############################## Region - Environment Checks #######################
# Checking if the path where we want to save everything exists
if ((Test-Path -Path $filepath) -eq $false) {
    Write-Error "Excel report location path does not exist for: $filepath"
    Exit
}
# Add a \ onto the end of the file path if it's missing
if ($filepath -notmatch '\\$') {
    $filepath += '\'
}
############################## End Region - Environment Checks ###################
##################################################################################


##################################################################################
############################## Region - Credentials ##############################
# Pull credentials from Windows Credential Manager if -credman is specified, and verify they exist and are not blank
if ($credman -eq $true) {
    # Set vCenter username and password
    $vcentercreds = Get-StoredCredential -Target 'vCenter_Creds'
    $vcpwd = (Get-StoredCredential -Target 'vCenter_Creds' -AsCredentialObject).Password
    if ($vcpwd -eq "") {
        Write-Warning "vCenter password is blank/missing. Verify vCenter_Creds exists in Windows Credential Manager as a Generic Credential."
        $credmanmissing = $true
    }
    # Set Prism username and password
    $prismcreds = Get-StoredCredential -Target 'NTNX_Prism' -AsCredentialObject
    if ($null -eq $prismcreds.Password) {
        Write-Warning "Prism password is blank/missing. Verify NTNX_Prism exists in Windows Credential Manager as a Generic Credential."
        $credmanmissing = $true
    }
    # If any credentials fail to exist or are blank, throw and error and exit the script
    if ($credmanmissing -eq $true) {
        Write-Error "Credentials not properly imported from Windows Credential Manager. Verify the proper generic credential, vCenter_Creds, exists and is not blank."
        Exit
    }
} else {
    # Create vCenter credential object
    $secVCpwd = ConvertTo-SecureString $vcpwd -AsPlainText -Force
    $vcentercreds = New-Object System.Management.Automation.PSCredential ($vcusername, $secVCpwd)
}
############################## End Region - Credentials ##########################
##################################################################################


##################################################################################
############################## Region - Skip Cert Check ##########################
# Have to skip the certificate request since we're using self-signed certs. This is for PS 5 and below.
#   Simply use -SkipCertificateCheck in the Invoke-RestMethod API call for PS 6 or later.
Add-Type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
############################## End Region - Skip Cert Check ######################
##################################################################################


##################################################################################
############################## Region - Functions ################################
function pcClusterList ($pcip) {
    # Create the HTTP Basic Authorization header
    $pair = $prismcreds.UserName + ":" + $prismcreds.Password
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    # Setup the request headers
    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = $basicAuthValue
    }

    # Invoke REST method for cluster list
    $uriPC = "https://" + $pcip + ":9440/api/nutanix/v3/clusters/list"
    $payload = '{"kind":"cluster","offset":0,"length":1}'
    $resultPC = (Invoke-RestMethod -Uri $uriPC -Headers $headers -Method POST -Body $payload -ContentType 'application/json' -TimeoutSec 60)
    Return $resultPC
}
function peHostList ($peip) {
    # Create the HTTP Basic Authorization header
    $pair = $prismcreds.UserName + ":" + $prismcreds.Password
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    # Setup the request headers
    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = $basicAuthValue
    }

    # Invoke REST method for hosts
    $uriPE = "https://" + $peip + ":9440/api/nutanix/v2.0/hosts"
    $resultHosts = (Invoke-RestMethod -Uri $uriPE -Headers $headers -Method GET -ContentType 'application/json' -TimeoutSec 60)
    Return $resultHosts
}
function vmwareHA ($cluInfo) {
    # Get advanced settings for later on
    $HAAdvancedSettings = $cluInfo | Get-AdvancedSetting | Where-Object { $_.Type -eq 'ClusterHA' }
    # Failures and Responses
    $TextInfo = (Get-Culture).TextInfo
    $HAClusterResponses = [PSCustomObject]@{
        'Name' = $cluInfo.Name
        'HA Enabled' = $cluInfo.HAEnabled
        'Host Monitoring' = $TextInfo.ToTitleCase($cluInfo.ExtensionData.Configuration.DasConfig.HostMonitoring)
    }
    $HAMemberProps = @{
        'InputObject' = $HAClusterResponses
        'MemberType' = 'NoteProperty'
    }
    if ($cluInfo.ExtensionData.Configuration.DasConfig.DefaultVmSettings.RestartPriority -eq 'Disabled') {
        Add-Member @HAMemberProps -Name 'Host Failure Response' -Value 'Disabled'
    } else {
        Add-Member @HAMemberProps -Name 'Host Failure Response' -Value 'Restart VMs'
    }
    Switch ($cluInfo.HAIsolationResponse) {
        'DoNothing' { Add-Member @HAMemberProps -Name 'Host Isolation Response' -Value 'Disabled' }
        'Shutdown' { Add-Member @HAMemberProps -Name 'Host Isolation Response' -Value 'Shutdown and restart VMs' }
        'PowerOff' { Add-Member @HAMemberProps -Name 'Host Isolation Response' -Value 'Power off and restart VMs' }
    }
    Switch ($cluInfo.ExtensionData.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL) {
        'disabled' { Add-Member @HAMemberProps -Name 'Datastore with PDL' -Value 'Disabled' }
        'warning' { Add-Member @HAMemberProps -Name 'Datastore with PDL' -Value 'Issue events' }
        'restartAggressive' { Add-Member @HAMemberProps -Name 'Datastore with PDL' -Value 'Power off and restart VMs' }
    }
    Switch ($cluInfo.ExtensionData.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD) {
        'disabled' { Add-Member @HAMemberProps -Name 'Datastore with APD' -Value 'Disabled' }
        'warning' { Add-Member @HAMemberProps -Name 'Datastore with APD' -Value 'Issue events' }
        'restartConservative' { Add-Member @HAMemberProps -Name 'Datastore with APD' -Value 'Power off and restart VMs (conservative)' }
        'restartAggressive' { Add-Member @HAMemberProps -Name 'Datastore with APD' -Value 'Power off and restart VMs (aggressive)' }
    }
    Switch ($cluInfo.ExtensionData.Configuration.DasConfig.VmMonitoring) {
        'vmMonitoringDisabled' { Add-Member @HAMemberProps -Name 'VM Monitoring' -Value 'Disabled' }
        'vmMonitoringOnly' { Add-Member @HAMemberProps -Name 'VM Monitoring' -Value 'VM monitoring only' }
        'vmAndAppMonitoring' { Add-Member @HAMemberProps -Name 'VM Monitoring' -Value 'VM and application monitoring' }
    }
    # Admission Control
    Switch ($cluInfo.HAAdmissionControlEnabled) {
        $true { Add-Member @HAMemberProps -Name 'Admission Control' -Value 'Enabled' }
        $false { Add-Member @HAMemberProps -Name 'Admission Control' -Value 'Disabled' }
    }
    Add-Member @HAMemberProps -Name 'Host Failures Cluster Tolerates' -Value $cluInfo.ExtensionData.Configuration.DasConfig.AdmissionControlPolicy.FailOverLevel
    Switch ($cluInfo.ExtensionData.Configuration.DasConfig.AdmissionControlPolicy.GetType().Name) {
        'ClusterFailoverHostAdmissionControlPolicy' { Add-Member @HAMemberProps -Name 'Host Failover Capacity Policy' -Value 'Dedicated failover hosts' }
        'ClusterFailoverResourcesAdmissionControlPolicy' { Add-Member @HAMemberProps -Name 'Host Failover Capacity Policy' -Value 'Cluster resource percentage' }
        'ClusterFailoverLevelAdmissionControlPolicy' { Add-Member @HAMemberProps -Name 'Host Failover Capacity Policy' -Value 'Slot policy' }
    }
    Switch ($cluInfo.ExtensionData.Configuration.DasConfig.AdmissionControlPolicy.AutoComputePercentages) {
        $true { Add-Member @HAMemberProps -Name 'Override Calculated Failover Capacity' -Value 'No' }
        $false { Add-Member @HAMemberProps -Name 'Override Calculated Failover Capacity' -Value 'Yes' }
    }
    Add-Member @HAMemberProps -Name '(Override) CPU %' -Value $cluInfo.ExtensionData.Configuration.DasConfig.AdmissionControlPolicy.CpuFailoverResourcesPercent
    Add-Member @HAMemberProps -Name '(Override) Memory %' -Value $cluInfo.ExtensionData.Configuration.DasConfig.AdmissionControlPolicy.MemoryFailoverResourcesPercent
    Add-Member @HAMemberProps -Name 'Performance Degradation VMs Tolerate' -Value "$($cluInfo.ExtensionData.Configuration.DasConfig.AdmissionControlPolicy.ResourceReductionToToleratePercent)%"
    # Heartbeat Datastores
    Switch ($cluInfo.ExtensionData.Configuration.DasConfig.HBDatastoreCandidatePolicy) {
        'allFeasibleDsWithUserPreference' { Add-Member @HAMemberProps -Name 'Heartbeat Selection Policy' -Value 'Use datastores from the specified list and complement automatically if needed' }
        'allFeasibleDs' { Add-Member @HAMemberProps -Name 'Heartbeat Selection Policy' -Value 'Automatically select datastores accessible from the host' }
        'userSelectedDs' { Add-Member @HAMemberProps -Name 'Heartbeat Selection Policy' -Value 'Use datastores only from the specified list' }
        default { Add-Member @HAMemberProps -Name 'Heartbeat Selection Policy' -Value $ClusterDasConfig.HBDatastoreCandidatePolicy }
    }
    try {
        $hbdatastore = ((Get-View -Id $cluInfo.ExtensionData.Configuration.DasConfig.HeartbeatDatastore -property Name).Name -join '|')
    } catch {
        $hbdatastore = 'None specified'
    }
    Add-Member @HAMemberProps -Name 'Heartbeat Datastores' -Value $hbdatastore
    # Advanced Options
    if ($HAAdvancedSettings) {
        $HAAdvancedOptions = ""
        foreach ($HAAdvancedSetting in $HAAdvancedSettings) {
            $HAAdvancedOption = $HAAdvancedSetting.Name + ":" + $HAAdvancedSetting.Value + " | "
            $HAAdvancedOptions += $HAAdvancedOption
        }
        Add-Member @HAMemberProps -Name 'Advanced Options' -Value $HAAdvancedOptions.TrimEnd(" | ")
    } else {
        Add-Member @HAMemberProps -Name 'Advanced Options' -Value ''
    }
    # Proactive HA
    Switch ($cluInfo.ExtensionData.ConfigurationEx.InfraUpdateHaConfig.Enabled) {
        $true { Add-Member @HAMemberProps -Name 'Proactive HA' -Value 'Enabled' }
        $false { Add-Member @HAMemberProps -Name 'Proactive HA' -Value 'Disabled' }
    }
    # Add output to HA sheet in Excel file
    $HAClusterResponses | Export-Excel -Path "$filepath$ExcelFile" -AutoSize -TableName "VMwareBP_HA" -TableStyle Medium15 -Numberformat 'Text' -WorksheetName "HA" -Append
}
function vmwareDRS ($cluInfo) {
    # Get advanced settings for later on
    $DrsAdvancedSettings = $cluInfo | Get-AdvancedSetting | Where-Object { $_.Type -eq 'ClusterDRS' }
    # DRS Automation Section
    $DrsCluster = [PSCustomObject]@{
        'Name' = $cluInfo.Name
        'vSphere DRS' = Switch ($cluInfo.DrsEnabled) {
            $true { 'Enabled' }
            $false { 'Disabled' }
        }
    }
    $DRSMemberProps = @{
        'InputObject' = $DrsCluster
        'MemberType' = 'NoteProperty'
    }
    Switch ($cluInfo.DrsAutomationLevel) {
        'Manual' { Add-Member @DRSMemberProps -Name 'Automation Level' -Value 'Manual' }
        'PartiallyAutomated' { Add-Member @DRSMemberProps -Name 'Automation Level' -Value 'Partially Automated' }
        'FullyAutomated' { Add-Member @DRSMemberProps -Name 'Automation Level' -Value 'Fully Automated' }
    }
    Add-Member @DRSMemberProps -Name 'Migration Threshold' -Value $cluInfo.ExtensionData.Configuration.DrsConfig.VmotionRate
    Switch ($cluInfo.ExtensionData.ConfigurationEx.ProactiveDrsConfig.Enabled) {
        $false { Add-Member @DRSMemberProps -Name 'Predictive DRS' -Value 'Disabled' }
        $true { Add-Member @DRSMemberProps -Name 'Predictive DRS' -Value 'Enabled' }
    }
    Switch ($cluInfo.ExtensionData.ConfigurationEx.DrsConfig.EnableVmBehaviorOverrides) {
        $true { Add-Member @DRSMemberProps -Name 'Virtual Machine Automation' -Value 'Enabled' }
        $false { Add-Member @DRSMemberProps -Name 'Virtual Machine Automation' -Value 'Disabled' }
    }
    # Additional Options
    if ($DrsAdvancedSettings) {
        Switch (($DrsAdvancedSettings | Where-Object { $_.name -eq 'TryBalanceVmsPerHost' }).Value) {
            '1' { Add-Member @DRSMemberProps -Name 'VM Distribution' -Value 'Enabled' }
            $null { Add-Member @DRSMemberProps -Name 'VM Distribution' -Value 'Disabled' }
        }
        Switch (($DrsAdvancedSettings | Where-Object { $_.name -eq 'PercentIdleMBInMemDemand' }).Value) {
            '100' { Add-Member @DRSMemberProps -Name 'Memory Metric for Load Balancing' -Value 'Enabled' }
            $null { Add-Member @DRSMemberProps -Name 'Memory Metric for Load Balancing' -Value 'Disabled' }
        }
        if (($DrsAdvancedSettings | Where-Object { $_.name -eq 'MaxVcpusPerCore' }).Value) {
            Add-Member @DRSMemberProps -Name 'CPU Over-Commitment' -Value 'Enabled'
        } else {
            Add-Member @DRSMemberProps -Name 'CPU Over-Commitment' -Value 'Disabled'
        }
    } else {
        Add-Member @DRSMemberProps -Name 'VM Distribution' -Value '--'
        Add-Member @DRSMemberProps -Name 'Memory Metric for Load Balancing' -Value '--'
        Add-Member @DRSMemberProps -Name 'CPU Over-Commitment' -Value '--'
    }
    # Power Management
    Switch ($cluInfo.ExtensionData.ConfigurationEx.DpmConfigInfo.Enabled) {
        $true { Add-Member @DRSMemberProps -Name 'DPM' -Value 'Enabled' }
        $false { Add-Member @DRSMemberProps -Name 'DPM' -Value 'Disabled' }
    }
    # Advanced Options
    if ($DrsAdvancedSettings) {
        $DrsAdvancedOptions = ""
        foreach ($DrsAdvancedSetting in $DrsAdvancedSettings) {
            $DrsAdvancedOption = $DrsAdvancedSetting.Name + ":" + $DrsAdvancedSetting.Value + " | "
            $DrsAdvancedOptions += $DrsAdvancedOption
        }
        Add-Member @DRSMemberProps -Name 'Advanced Options' -Value $DrsAdvancedOptions.TrimEnd(" | ")
    } else {
        Add-Member @DRSMemberProps -Name 'Advanced Options' -Value ''
    }
    # Write DRS settings to Excel file
    $DrsCluster | Export-Excel -Path "$filepath$ExcelFile" -AutoSize -TableName "VMwareBP_DRS" -TableStyle Medium15 -Numberformat 'Text' -WorksheetName "DRS" -Append
}
function vmwareVMOverrides ($cluInfo, $hostCount) {
    $DrsVmOverrides = $cluInfo.ExtensionData.Configuration.DrsVmConfig
    $DasVmOverrides = $cluInfo.ExtensionData.Configuration.DasVmConfig
    $vmoCount = 0
    # Build list of VM IDs into an array (have to search both DRS and DAS settings)
    $vmoList  = @()
    foreach ($dasitem in $DasVmOverrides) {
        $vmoList = $vmoList + "$($dasitem.Key.Type)-$($dasitem.Key.Value)"
    }
    foreach ($drsitem in $DrsVmOverrides) {
        $vmoName = "$($drsitem.Key.Type)-$($drsitem.Key.Value)"
        $i = 0
        foreach ($vmoid in $vmoList) {
            if ($vmoName -eq $vmoid) {
                $i = 1
            }
        }
        if ($i -eq 0) {
            $vmoList = $vmoList + "$($drsitem.Key.Type)-$($drsitem.Key.Value)"
        }
    }
    # Get Override information for each VM as long as it contains -CVM in the name
    foreach ($vmo in $vmoList) {
        $vmname = Get-VM -Id "$vmo"
        if ($vmname.Name -match "-CVM") {
            $vmoCount++
            $VmOverride = [PSCustomObject]@{
                'Cluster Name' = $cluInfo.Name
                'Node Total' = $hostCount
                'VMO Total' = $vmoCount
                'Virtual Machine' = $vmname.Name
            }
            $VMOMemberProps = @{
                'InputObject' = $VmOverride
                'MemberType' = 'NoteProperty'
            }
            # DRS VM Overrides
            foreach ($vmodrs in $DrsVmOverrides) {
                if ("$($vmodrs.Key.Type)-$($vmodrs.Key.Value)" -eq "$vmo") {
                    if ($vmodrs.Enabled -eq $false) {
                        Add-Member @VMOMemberProps -Name 'vSphere DRS Automation Level' -Value 'Disabled'
                    } else {
                        Switch ($vmodrs.Behavior) {
                            'manual' { Add-Member @VMOMemberProps -Name 'vSphere DRS Automation Level' -Value 'Manual' }
                            'partiallyAutomated' { Add-Member @VMOMemberProps -Name 'vSphere DRS Automation Level' -Value 'Partially Automated' }
                            'fullyAutomated' { Add-Member @VMOMemberProps -Name 'vSphere DRS Automation Level' -Value 'Fully Automated' }
                        }
                    }
                }
            }
            # HA VM Overrides
            $dasflag = 0
            foreach ($vmodas in $DasVmOverrides) {
                if ("$($vmodas.Key.Type)-$($vmodas.Key.Value)" -eq "$vmo") {
                    $dasflag = 1
                    Switch ($vmodas.DasSettings.RestartPriority) {
                        $null { Add-Member @VMOMemberProps -Name 'VM Restart Priority' -Value '--' }
                        'lowest' { Add-Member @VMOMemberProps -Name 'VM Restart Priority' -Value 'Lowest' }
                        'low' { Add-Member @VMOMemberProps -Name 'VM Restart Priority' -Value 'Low' }
                        'medium' { Add-Member @VMOMemberProps -Name 'VM Restart Priority' -Value 'Medium' }
                        'high' { Add-Member @VMOMemberProps -Name 'VM Restart Priority' -Value 'High' }
                        'highest' { Add-Member @VMOMemberProps -Name 'VM Restart Priority' -Value 'Highest' }
                        'disabled' { Add-Member @VMOMemberProps -Name 'VM Restart Priority' -Value 'Disabled' }
                        'clusterRestartPriority' { Add-Member @VMOMemberProps -Name 'VM Restart Priority' -Value 'Cluster default' }
                    }
                    Switch ($vmodas.DasSettings.IsolationResponse) {
                        $null { Add-Member @VMOMemberProps -Name 'Host Isolation Response' -Value '--' }
                        'none' { Add-Member @VMOMemberProps -Name 'Host Isolation Response' -Value 'Disabled' }
                        'powerOff' { Add-Member @VMOMemberProps -Name 'Host Isolation Response' -Value 'Power off and restart VMs' }
                        'shutdown' { Add-Member @VMOMemberProps -Name 'Host Isolation Response' -Value 'Shutdown and restart VMs' }
                        'clusterIsolationResponse' { Add-Member @VMOMemberProps -Name 'Host Isolation Response' -Value 'Cluster default' }
                    }
                    # VM Monitoring Section
                    Switch ($vmodas.DasSettings.VmToolsMonitoringSettings.VmMonitoring) {
                        $null { Add-Member @VMOMemberProps -Name 'VM Monitoring' -Value '--' }
                        'vmMonitoringDisabled' { Add-Member @VMOMemberProps -Name 'VM Monitoring' -Value 'Disabled' }
                        'vmMonitoringOnly' { Add-Member @VMOMemberProps -Name 'VM Monitoring' -Value 'VM Monitoring Only' }
                        'vmAndAppMonitoring' { Add-Member @VMOMemberProps -Name 'VM Monitoring' -Value 'VM and App Monitoring' }
                    }
                }
            }
            # This is in case the VM is in DRS overrides but not DAS
            if ($dasflag -eq 0) {
                Add-Member @VMOMemberProps -Name 'VM Restart Priority' -Value '--'
                Add-Member @VMOMemberProps -Name 'Host Isolation Response' -Value '--'
                Add-Member @VMOMemberProps -Name 'VM Monitoring' -Value '--'
            }
            # Write VM Override settings to Excel file
            $VmOverride | Export-Excel -Path "$filepath$ExcelFile" -AutoSize -TableName "VMwareBP_VMO" -TableStyle Medium15 -Numberformat 'Text' -WorksheetName "VM_Overrides" -Append
        }
    }
}
function vmwareOtherSettings ($cluInfo){
    # Other Cluster Settings
    $OtherSettings = [PSCustomObject]@{
        'Name' = $cluInfo.Name
    }
    $OSMemberProps = @{
        'InputObject' = $OtherSettings
        'MemberType' = 'NoteProperty'
    }
    Switch ($cluInfo.EVCMode) {
        $null { Add-Member @OSMemberProps -Name 'EVC Mode' -Value 'Disabled' }
        default { Add-Member @OSMemberProps -Name 'EVC Mode' -Value $cluInfo.EVCMode }
    }
    Switch ($cluInfo.VMSwapfilePolicy) {
        'WithVM' { Add-Member @OSMemberProps -Name 'VM Swap File Policy' -Value 'With VM' }
        'InHostDatastore' { Add-Member @OSMemberProps -Name 'VM Swap File Policy' -Value 'In Host Datastore' }
        default { Add-Member @OSMemberProps -Name 'VM Swap File Policy' -Value $cluInfo.VMSwapfilePolicy }
    }
    # Write cluster Other Settings to Excel file
    $OtherSettings | Export-Excel -Path "$filepath$ExcelFile" -AutoSize -TableName "VMwareBP_Other" -TableStyle Medium15 -Numberformat 'Text' -WorksheetName "Other_Settings" -Append
}
function peVMwareAudit ($peName, $peIp, $peVcenter) {
    # Get host list and create one CVM name from that list
    $hostList = peHostList $peIp
    $hostCount = 0
    if ($null -eq $hostList.entities[0].block_serial) {
        $CVMname = "NTNX-" + $hostList.entities[0].serial + "-A-CVM"
    } else {
        $CVMname = "NTNX-" + $hostList.entities[0].block_serial + "-A-CVM"
    }
    # Get the total amount of hosts for the VM Overrides section
    foreach ($ntnxhost in $hostList.entities) {
        $hostCount++
    }
    # Connect to vCenter
    $vCenterConnection = $null
    Try {
        Write-Host "Trying to connect to vCenter: $($peVcenter)" -ForegroundColor Cyan
        $vCenterConnection = Connect-VIServer $peVcenter -Credential $vCenterCreds -ErrorAction Stop
    }
    Catch {
        $vCenterConnection = $false
        Write-Warning "Unable to connect to $peVcenter!"    
    }
    If ($vCenterConnection.IsConnected -eq $true) {
        Write-Host "Successfully connected to vCenter: $($peVcenter)" -ForegroundColor Cyan
        Write-Host "Gathering settings info..." -ForegroundColor Cyan
        # Gather VMware Info for audit
        $vsphereCluster = Get-VM $CVMname | Get-Cluster
        vmwareHA $vsphereCluster
        vmwareDRS $vsphereCluster
        vmwareOtherSettings $vsphereCluster
        vmwareVMOverrides $vsphereCluster $hostCount
        # Disconnect from vCenter
        Disconnect-VIServer $peVcenter -Confirm:$false -Verbose
    }
}
############################## End Region - Functions ############################
##################################################################################


##################################################################################
############################## Region - Body #####################################
# Build initial Excel file we'll dump data to
$ExcelFile = "VMwareSettingsAudit_$(Get-Date -Format yyyy-MM-dd_HH-mm-ss).xlsx"

# Set PowerCLI Configuration
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -InvalidCertificateAction:Ignore -Confirm:$false | Out-Null

# Connect to PC and get the cluster list
ForEach ($pc in $pcList) {
    $peList = pcClusterList $pc
     # For every PE that is VMware, collect VMware info
    ForEach ($pe in $peList.entities) {
        If (($pe.status.resources.config.service_list -ieq "AOS") -and ($pe.status.resources.nodes.hypervisor_server_list[0].type -ieq "VMWARE")) {
            $peName = $pe.status.name
            $peIp = $pe.status.resources.network.external_ip
            $peVcenter = $pe.status.resources.config.management_server_list[0].ip
            # Run VMware audit for PE
            Write-Host "Gathering data on $($pe.status.name)"
            peVMwareAudit $peName $peIp $peVcenter
        }
    }
}
############################## End Region - Body #################################
##################################################################################