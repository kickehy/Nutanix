<#
.NOTES
    Author: Brad Meyer
    Contributor: Jason Stenack
    Date:   April 5, 2022

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
    Gathers VMware vDS info from vCenter and exports it into an Excel spreadsheet.
.DESCRIPTION
    Gathers VMware vDS info from vCenter and exports it into an Excel spreadsheet. This includes vDS configuration and portgroup configuration.

    vDS Information Gathered:
        vCenter
        Datacenter
        Name
        Manufacturer
        Version
        Uplinks
        Ports
        NIOC Enabled
        NIOC Version
        MTU
        Multicast Filtering Mode
        Link Discovery
        Link Discovery Operation
        LACP Version
        LAG Count
        LAG Name (First only in list)
        LAG Mode (First only in list)
        LAG Load Balance Algorithm
        LAG Uplinks
        LAG Uplink Names
        HC(VLAN/MTU) Enabled
        HC(VLAN/MTU) Interval
        HC(Teaming/Failover) Enabled
        HC(Teaming/Failover) Interval
        Notes
        Overall Status
        Id
        Folder
        Contact Name
        Contact Details
        Host List (if -h is specified)

    Portgroup Information Gathered:
        vCenter
        Datacenter
        vDS
        Name
        VLAN
        Port Binding
        Ports
        Load Balancing Policy
        Network Failure Detection
        Notify Switches
        Failback
        Active Uplinks
        Standby Uplinks
        Unused Uplinks
        Promiscuous Mode
        MAC Address Changes
        Forged Transmits
        Id
.PARAMETER vclist
    List of vCenters, comma separated, to run the script against.
    Ex. -vclist vc1.domain.com,vc2.domain.com,10.10.10.10
    Alias: -vcl
.PARAMETER h
    Specifies whether or not you want to list hosts attached to the vDS in the report. This could be a big field depending on design of the vDS and increase script run time.
.PARAMETER credman
    This will cause the script to look for credentials to be supplied via Windows Credential Manager.
    The following Generic Credential is expected: vCenter_Creds
.PARAMETER vcusername
    Specifies the username that will be used to authenticate against vCenter.
    Must use single quotes when specifying otherwise you may have unexpected results: -vcusername 'username@domain.com'
    Alias: -vcu
.PARAMETER vcpwd
    Specifies the password that will be used to authenticate against vCenter.
    Must use single quotes when specifying otherwise you may have unexpected results: -vcpwd 'Pa$$w0rd'
    Alias: -vcp
.PARAMETER filepath
    Specifies report location for the script.
    Ex. -filepath 'C:\reports'
    Alias: -fp
.EXAMPLE
    VMwarevDSAudit.ps1 -vclist vc01.domain.com,10.10.10.10 -vcusername 'username@domain.com' -vcpwd 'Pa$$w0rd' -filepath 'C:\Reports'

    Pulls vDS and Portgroup info from vCenters vc01.domain.com and 10.10.10.10 and saves the report to C:\Reports. Hosts are not added to the report.
.EXAMPLE
    VMwarevDSAudit.ps1 -vclist vc01.domain.com,vc02.domain.com -h -credman -filepath 'C:\Reports'

    Pulls vDS and Portgroup info from vCenters vc01.domain.com and vc02.domain.com using credentials stored in Windows Credential manager and saves the report to C:\Reports. Hosts are added to the report.
#>

##################################################################################
############################## Region - Params ###################################
param (
    [Parameter(Mandatory=$true,Position=0)]
    [Alias("vcl")]
    [string[]] $vclist,
    [switch] $h,
    [Parameter(ParameterSetName="CredMan", Mandatory=$true)]
    [switch] $credman,
    [Parameter(ParameterSetName="Prompt", Mandatory=$true)]
    [Alias("vcu")]
    [string] $vcusername,
    [Parameter(ParameterSetName="Prompt", Mandatory=$true)]
    [Alias("vcp")]
    [string] $vcpwd,
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
# Checking if the pathway where we want to save everything exists
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
    $vCenterCreds = Get-StoredCredential -Target 'vCenter_Creds'
    $vcpwd = (Get-StoredCredential -Target 'vCenter_Creds' -AsCredentialObject).Password
    if ($vcpwd -eq "") {
        Write-Warning "vCenter password is blank/missing. Verify vCenter_Creds exists in Windows Credential Manager as a Generic Credential."
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
    $vCenterCreds = New-Object System.Management.Automation.PSCredential ($vcusername, $secVCpwd)
}
############################## End Region - Credentials ##########################
##################################################################################


##################################################################################
############################## Region - Body #####################################
# Build initial Excel file where we'll dump data
$ExcelFile = "VMwarevDSAudit_$(Get-Date -Format yyyy-MM-dd_HH-mm-ss).xlsx"

# Set PowerCLI Configuration
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -InvalidCertificateAction:Ignore -Confirm:$false | Out-Null

# Gather vDS info in each vCenter
Foreach ($vCenter in $vclist) {
    $vCenterConnection = $null
    Try {
        Write-Host "Trying to connect to vCenter: $($vCenter)" -ForegroundColor Cyan
        $vCenterConnection = Connect-VIServer $vCenter -Credential $vCenterCreds -ErrorAction Stop
    }
    Catch {
        $vCenterConnection = $false
        Write-Warning "Unable to connect to $vCenter!"    
    }
    # Gather vDS, LACP, and PortGroup info if you're actually connected to vCenter
    If ($vCenterConnection.IsConnected -eq $true) {
        Write-Host "Successfully connected to vCenter: $($vCenter)" -ForegroundColor Cyan
        Write-Host "Gathering vDS and Portgroup info..." -ForegroundColor Cyan
        # Get list of all vDS on the vCenter
        $vsphereVDS = Get-VDSwitch
        If ($vsphereVDS) {
            ForEach ($vds in $vsphereVDS) {
                ######################### Region - vDS Info #########################
                # Gather's host list inside the vDS
                if ($h -eq $true){
                    #Get host list in vDS
                    $esxiList = @()
                    $esxiServers = $vds.ExtensionData.Summary.HostMember
                    if ($esxiServers) {
                        foreach ($esxi in $esxiServers) {
                            $esxiList += (Get-VMHost -Id $esxi).Name
                        }
                    }
                }
                # Verify if Basic or Enhanced LACP
                Switch ($vds.ExtensionData.Config.LacpApiVersion) {
                    'singleLag' { $lacpapiver = 'Basic LACP' }
                    'multipleLag' { $lacpapiver = 'Enhanced LACP' }
                }
                # Verify Multicast Mode
                Switch ($vds.ExtensionData.Config.MulticastFilteringMode) {
                    'legacyFiltering' { $multimode = 'Basic'}
                    'snooping' {$multimode = 'Snooping'}
                    default {$multimode = $vds.ExtensionData.Config.MulticastFilteringMode}
                }
                # Get LAG Info
                $lagcount = 0
                ForEach ($lag in $vds.ExtensionData.Config.LacpGroupConfig) {
                    $lagcount++
                }
                If ($lagcount -gt 0) {
                    $lag = $vds.ExtensionData.Config.LacpGroupConfig[0]
                    $lagname = $lag.Name
                    $lagmode = $lag.Mode
                    Switch ($lag.LoadbalanceAlgorithm) {
                        'destIp' { $lagloadbal = 'Destination IP' }
                        'destIpTcpUdpPort' { $lagloadbal = 'Destination IP and TCP/UDP port number' }
                        'destIpTcpUdpPortVlan' { $lagloadbal = 'Destination IP, TCP/UDP port number and VLAN' }
                        'destIpVlan' { $lagloadbal = 'Destination IP and VLAN' }
                        'destMac' { $lagloadbal = 'Destination MAC address' }
                        'destTcpUdpPort' { $lagloadbal = 'Destination TCP/UDP port number' }
                        'srcDestIp' { $lagloadbal = 'Source and Destination IP' }
                        'srcDestIpTcpUdpPort' { $lagloadbal = 'Source and destination IP and TCP/UDP port number' }
                        'srcDestIpTcpUdpPortVlan' { $lagloadbal = 'Source and destination IP address, TCP/UDP port and VLAN' }
                        'srcDestIpVlan' { $lagloadbal = 'Source and destination IP and VLAN' }
                        'srcDestMac' { $lagloadbal = 'Source and destination MAC address' }
                        'srcDestTcpUdpPort' { $lagloadbal = 'Source and destination TCP/UDP port number' }
                        'srcIp' { $lagloadbal = 'Source IP' }
                        'srcIpTcpUdpPort' { $lagloadbal = 'Source IP and TCP/UDP port number' }
                        'srcIpTcpUdpPortVlan' { $lagloadbal = 'Source IP, TCP/UDP port number and VLAN' }
                        'srcIpVlan' { $lagloadbal = 'Source IP and VLAN' }
                        'srcMac' { $lagloadbal = 'Source MAC address' }
                        'srcPortId' { $lagloadbal = 'Source Virtual Port Id' }
                        'srcTcpUdpPort' { $lagloadbal = 'Source TCP/UDP port number' }
                        'vlan' { $lagloadbal = 'VLAN only' }
                        default { $lagloadbal = $lag.LoadbalanceAlgorithm }
                    }
                    $laguplinks = $lag.UplinkNum
                    $laguplinkname = $lag.UplinkName
                } else {
                    $lagname=$lagmode=$lagloadbal=$laguplinks=$laguplinkname = ""
                }
                # Create line we'll write to the vDS sheet in the Excel file
                if ($h -eq $true) {
                    $vDSSettings = [PSCustomObject]@{
                        'vCenter' = $vCenter
                        'Datacenter' = $vds.Datacenter
                        'Name' = $vds.name
                        'Manufacturer' = $vds.Vendor
                        'Version' = $vds.Version
                        'Uplinks' = $vds.NumUplinkPorts
                        'Ports' = $vds.NumPorts
                        'NIOC Enabled' = $vds.ExtensionData.Config.NetworkResourceManagementEnabled
                        'NIOC Version' = $vds.ExtensionData.Config.NetworkResourceControlVersion
                        'MTU' = $vds.Mtu
                        'Multicast Filtering Mode' = $multimode
                        'Link Discovery' = $vds.LinkDiscoveryProtocol
                        'Link Discovery Operation' = $vds.LinkDiscoveryProtocolOperation
                        'LACP Version' = $lacpapiver
                        'LAG Count' = $lagcount
                        'LAG Name' = $lagname
                        'LAG Mode' = $lagmode
                        'LAG Load Balance Algorithm' = $lagloadbal
                        'LAG Uplinks' = $laguplinks
                        'LAG Uplink Names' = $laguplinkname -join ", "
                        'HC(VLAN/MTU) Enabled'= $vds.ExtensionData.Config.HealthCheckConfig[0].Enable
                        'HC(VLAN/MTU) Interval'= $vds.ExtensionData.Config.HealthCheckConfig[0].Interval
                        'HC(Teaming/Failover) Enabled'= $vds.ExtensionData.Config.HealthCheckConfig[1].Enable
                        'HC(Teaming/Failover) Interval'= $vds.ExtensionData.Config.HealthCheckConfig[1].Interval
                        'Notes' = $vds.Notes
                        'Overall Status' = $vds.ExtensionData.OverallStatus
                        'Id' = $vds.Id
                        'Folder' = $vds.Folder
                        'Contact Name' = $vds.Contactname
                        'Contact Details' = $vds.ContactDetails
                        'Host List' = $esxiList -join ', '
                    }
                } else {
                    $vDSSettings = [PSCustomObject]@{
                        'vCenter' = $vCenter
                        'Datacenter' = $vds.Datacenter
                        'Name' = $vds.name
                        'Manufacturer' = $vds.Vendor
                        'Version' = $vds.Version
                        'Uplinks' = $vds.NumUplinkPorts
                        'Ports' = $vds.NumPorts
                        'NIOC Enabled' = $vds.ExtensionData.Config.NetworkResourceManagementEnabled
                        'NIOC Version' = $vds.ExtensionData.Config.NetworkResourceControlVersion
                        'MTU' = $vds.Mtu
                        'Multicast Filtering Mode' = $multimode
                        'Link Discovery' = $vds.LinkDiscoveryProtocol
                        'Link Discovery Operation' = $vds.LinkDiscoveryProtocolOperation
                        'LACP Version' = $lacpapiver
                        'LAG Count' = $lagcount
                        'LAG Name' = $lagname
                        'LAG Mode' = $lagmode
                        'LAG Load Balance Algorithm' = $lagloadbal
                        'LAG Uplinks' = $laguplinks
                        'LAG Uplink Names' = $laguplinkname -join ", "
                        'HC(VLAN/MTU) Enabled'= $vds.ExtensionData.Config.HealthCheckConfig[0].Enable
                        'HC(VLAN/MTU) Interval'= $vds.ExtensionData.Config.HealthCheckConfig[0].Interval
                        'HC(Teaming/Failover) Enabled'= $vds.ExtensionData.Config.HealthCheckConfig[1].Enable
                        'HC(Teaming/Failover) Interval'= $vds.ExtensionData.Config.HealthCheckConfig[1].Interval
                        'Notes' = $vds.Notes
                        'Overall Status' = $vds.ExtensionData.OverallStatus
                        'Id' = $vds.Id
                        'Folder' = $vds.Folder
                        'Contact Name' = $vds.Contactname
                        'Contact Details' = $vds.ContactDetails
                    }
                }
                # Write vDS settings to Excel file
                $vDSSettings | Export-Excel -Path "$filepath$ExcelFile" -AutoSize -TableName "VMware_vDS" -TableStyle Medium15 -Numberformat 'Text' -WorksheetName "vDS" -Append
                ######################### End Region - vDS Info #########################

                ######################### Region - Portgroup Info #########################
                if ($vds.ExtensionData.Portgroup) {
                    ForEach ($pg in $vds.ExtensionData.Portgroup) {
                        # Get Portgroup Info
                        $portgroup = Get-VDPortgroup -Id ($pg.Type + "-" + $pg.Value)
                        $pglbpol = $portgroup | Get-VDUplinkTeamingPolicy
                        $pgsecpol = $portgroup | Get-VDSecurityPolicy
                        # Verify Load Balancing Policy type
                        Switch ($pglbpol.LoadBalancingPolicy) {
                            'LoadBalanceIP' { $lbpolicy = 'Route based on IP hash' }
                            'LoadBalanceSrcMac' { $lbpolicy = 'Route based on Source MAC hash' }
                            'LoadBalanceSrcId' { $lbpolicy = 'Route based on originating virtual port' }
                            'ExplicitFailover' { $lbpolicy = 'Use explicit failover order' }
                            'LoadBalanceLoadBased' { $lbpolicy = 'Route based on physical NIC load' }
                            default { $lbpolicy = $pglbpol.LoadBalancingPolicy }
                        }
                        # Verify Failover Detection Policy type
                        Switch ($pglbpol.FailoverDetectionPolicy) {
                            'LinkStatus' { $faildet = 'Link Status Only'}
                            'BeaconProbing' { $faildet = 'Beacon Probing'}
                        }
                        # Verify Security Policies types
                        Switch ($pgsecpol.AllowPromiscuous) {
                            'False' { $pgsecpom = 'Reject'}
                            'True' { $pgsecpom = 'Accept'}
                        }
                        Switch ($pgsecpol.MacChanges) {
                            'False' { $pgsecmac = 'Reject'}
                            'True' { $pgsecmac = 'Accept'}
                        }
                        Switch ($pgsecpol.ForgedTransmits) {
                            'False' { $pgsecforg = 'Reject'}
                            'True' { $pgsecforg = 'Accept'}
                        }
                        # Verify VLAN tagged or untagged
                        Switch ($portgroup.VlanConfiguration) {
                            $null { $pgvlan = 'None'}
                            default { $pgvlan = $portgroup.VlanConfiguration}
                        }
                        # Create line we'll write to the Portgroups sheet in the Excel file
                        $PGSettings = [PSCustomObject]@{
                            'vCenter' = $vCenter
                            'Datacenter' = $vds.Datacenter
                            'vDS' = $vds.name
                            'Name' = $portgroup.Name
                            'VLAN' = $pgvlan
                            'Port Binding' = $portgroup.PortBinding
                            'Ports' = $portgroup.NumPorts
                            'Load Balancing Policy' = $lbpolicy
                            'Network Failure Detection' = $faildet
                            'Notify Switches' = $pglbpol.NotifySwitches
                            'Failback' = $pglbpol.EnableFailback
                            'Active Uplinks' = $pglbpol.ActiveUplinkPort -join ', '
                            'Standby Uplinks' = $pglbpol.StandbyUplinkPort -join ', '
                            'Unused Uplinks' = $pglbpol.UnusedUplinkPort -join ', '
                            'Promiscuous Mode' = $pgsecpom
                            'MAC Address Changes' = $pgsecmac
                            'Forged Transmits' = $pgsecforg
                            'Id' = $portgroup.Id
                        }
                        # Write Portgroup settings to Excel file
                        $PGSettings | Export-Excel -Path "$filepath$ExcelFile" -AutoSize -TableName "VMware_vDS_PortGroups" -TableStyle Medium15 -Numberformat 'Text' -WorksheetName "Portgroups" -Append
                    }
                }
                ######################### End Region - Portgroup Info #########################
            }
        }
        # Disconnect vCenter connection
        Disconnect-VIServer $vcenter -Confirm:$false -Verbose
    }
}
############################## End Region - Body #################################
##################################################################################