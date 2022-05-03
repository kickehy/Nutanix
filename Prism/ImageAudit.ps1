<#
.NOTES
    Author: Brad Meyer
    Date:   May 3, 2022

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
    Gathers image configuration across Nutanix clusters and exports it to a report.
.DESCRIPTION
    Gathers image configuration across Nutanix clusters and exports it to a report.

    Fields included in the report:
        Cluster Name
        Image Name
        Description
        Storage Container
        Image Type
        State
        Managed By (PC or Local PE)
        PC Name
        Size(GB)
        UUID
        Created Date
        Updated Date
        VM Disk Id
.PARAMETER pclist
    List of Prism Centrals, comma separated, to run the script against.
    Ex. -pclist pc1.domain.com,pc2.domain.com,10.10.10.10
    Alias: -pcl
.PARAMETER pelist
    List of Prism Element clusters, comma separated, to run the script against.
    Ex. -pelist pe1.domain.com,pe2.domain.com,10.11.11.11
    Alias: -pel
.PARAMETER credman
    This will cause the script to look for credentials to be supplied via Windows Credential Manager.
    The following Generic Credentials are expected:
        NTNX_Prism
.PARAMETER prismusername
    Specifies the username that will be used to authenticate against both Prism Central and Prism Element.
    Must use single quotes when specifying otherwise you may have unexpected results: -prismusername 'username@domain.com'
    Alias: -pu
.PARAMETER prismpwd
    Specifies the password that will be used to authenticate against both Prism Central and Prism Element.
    Must use single quotes when specifying otherwise you may have unexpected results: -prismpwd 'Pa$$w0rd'
    Alias: -pp
.PARAMETER filepath
    Specifies report location for the script.
    Ex. -filepath 'C:\reports'
    Alias: -fp
.EXAMPLE
    ImageAudit.ps1 -pclist pc01.domain.com -pelist 10.10.10.10 -prismusername 'username@domain.com' -prismpwd 'Pa$$w0rd' -filepath 'C:\Reports'

    Pulls image info from Prism Central pc01.domain.com and Prism Element 10.10.10.10 and saves the report to C:\Reports.
.EXAMPLE
    ImageAudit.ps1 -pclist pc01.domain.com -credman -filepath 'C:\Reports'

    Pulls image info from Prism Central pc01.domain.com using credentials stored in Windows Credential manager and saves the report to C:\Reports.
#>

##################################################################################
############################## Region - Params ###################################
param (
    [Parameter(Position=0)]
    [Alias("pcl")]
    [string[]] $pclist,
    [Parameter(Position=1)]
    [Alias("pel")]
    [string[]] $pelist,
    [Parameter(ParameterSetName="CredMan", Mandatory=$true)]
    [switch] $credman,
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
# If no PC or PE list is specified exit the script
if (($null -eq $pclist) -and ($null -eq $pelist)) {
    Write-Error "Please provide a value for -pclist or -pelist"
    Exit
}
############################## End Region - Environment Checks ###################
##################################################################################


##################################################################################
############################## Region - Credentials ##############################
# Pull credentials from Windows Credential Manager if -credman is specified, and verify they exist and are not blank
if ($credman -eq $true) {
    # Set Prism username and password
    $prismcreds = Get-StoredCredential -Target 'NTNX_Prism' -AsCredentialObject
    if ($null -eq $prismpwd) {
        Write-Warning "Prism password is blank/missing. Verify NTNX_Prism exists in Windows Credential Manager as a Generic Credential."
        $credmanmissing = $true
    }
    # If any credentials fail to exist or are blank, throw and error and exit the script
    if ($credmanmissing -eq $true) {
        Write-Error "Credentials not properly imported from Windows Credential Manager. Verify the proper generic credential, vCenter_Creds, exists and is not blank."
        Exit
    }
    # If everything checks out, set the Prism username and password
    $prismusername = $prismcreds.UserName
    $prismpwd = $prismcreds.Password
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
    $pair = $prismusername + ":" + $prismpwd
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
function peImageOwnerList ($peip) {
    # Create the HTTP Basic Authorization header
    $pair = $prismusername + ":" + $prismpwd
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    # Setup the request headers
    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = $basicAuthValue
    }

    # Invoke REST method for image owner list
    $uriPE = "https://" + $peip + ":9440/PrismGateway/services/rest/v1/groups"
    $payload = '{"entity_type":"image_info","group_member_attributes":[{"attribute":"owner_cluster_uuid"},{"attribute":"uuid"}],"query_name":"prism:CPQueryModel"}'
    $resultImageOwner = (Invoke-RestMethod -Uri $uriPE -Headers $headers -Method POST -Body $payload -ContentType 'application/json' -TimeoutSec 60)
    Return $resultImageOwner
}
function peRegisteredPC ($peip) {
    # Create the HTTP Basic Authorization header
    $pair = $prismusername + ":" + $prismpwd
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    # Setup the request headers
    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = $basicAuthValue
    }

    # Invoke REST method for registered PC
    $uriPE = "https://" + $peip + ":9440/PrismGateway/services/rest/v1/multicluster/cluster_external_state"
    $resultRegPC = (Invoke-RestMethod -Uri $uriPE -Headers $headers -Method GET -ContentType 'application/json' -TimeoutSec 60)
    Return $resultRegPC
}
function peImageList ($peip) {
    # Create the HTTP Basic Authorization header
    $pair = $prismusername + ":" + $prismpwd
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    # Setup the request headers
    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = $basicAuthValue
    }

    # Invoke REST method for image list
    $uriPE = "https://" + $peip + ":9440/PrismGateway/services/rest/v2.0/images"
    $resultImages = (Invoke-RestMethod -Uri $uriPE -Headers $headers -Method GET -ContentType 'application/json' -TimeoutSec 60)
    Return $resultImages
}
function peInfo ($peip) {
    # Create the HTTP Basic Authorization header
    $pair = $prismusername + ":" + $prismpwd
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    # Setup the request headers
    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = $basicAuthValue
    }

    # Invoke REST method for PE info
    $uriPE = "https://" + $peip + ":9440/PrismGateway/services/rest/v2.0/cluster"
    $resultPEInfo = (Invoke-RestMethod -Uri $uriPE -Headers $headers -Method GET -ContentType 'application/json' -TimeoutSec 60)
    Return $resultPEInfo
}
function peStrgList ($peip) {
    # Create the HTTP Basic Authorization header
    $pair = $prismusername + ":" + $prismpwd
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    # Setup the request headers
    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = $basicAuthValue
    }

    # Invoke REST method for storage container list
    $uriPE = "https://" + $peip + ":9440/PrismGateway/services/rest/v2.0/storage_containers"
    $resultStrgList = (Invoke-RestMethod -Uri $uriPE -Headers $headers -Method GET -ContentType 'application/json' -TimeoutSec 60)
    Return $resultStrgList
}
function getImageInfo ($pe) {
    Write-Host "Gathering image information for $($pe)" -ForegroundColor Cyan
        # Get cluster info so we can pull the name
        $cluInfo = peInfo $pe
        $cluName = $cluInfo.name
        # Get cluster storage container list for comparison
        $strgList = peStrgList $pe
        # Get registered PC, if there is one
        try {
            $pcReg = peRegisteredPC $pe
            $pcRegUuid = $pcReg.clusterUuid
            $pcRegName = $pcReg.clusterDetails.clusterName
        } catch {
            $pcRegUuid = ""
            $pcRegName = ""
        }
        # Get list of images on the cluster
        $imageList = peImageList $pe
        # Get image owner list, to see if PC owns the image or local PE
        $imageOwnerList = peImageOwnerList $pe
        # Cycle through each image and check to see if it was pushed from PC and build object to write to report
        foreach ($image in $imageList.entities) {
            # Container section
            $iscontainer = $false
            foreach ($container in $strgList.entities) {
                if ($container.storage_container_uuid -eq $image.storage_container_uuid) {
                    $imgStrgName = $container.name
                    $iscontainer = $true
                }
            }
            if ($iscontainer -eq $false) {
                $imgStrgName = ""
            }
            # Most other image settings
            $imgName = $image.name
            $imgDesc = $image.annotation
            $imgType = $image.image_type
            $imgState = $image.image_state
            $imgUuid = $image.uuid
            $imgSize = $image.vm_disk_size/1024/1024/1024
            $imgDiskId = $image.vm_disk_id
            $createUsecs = ($image.created_time_in_usecs).ToString()
            $updatedUsecs = ($image.updated_time_in_usecs).ToString()
            $imgCreateDate = (Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($createUsecs.SubString(0,10)))
            $imgUpdatedDate = (Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($updatedUsecs.SubString(0,10)))
            # Image owner section
            foreach ($imgo in $imageOwnerList.group_results.entity_results) {
                $imgoowner = $imgo.data[0].values.values
                $imgouuid = $imgo.data[1].values.values
                if (($imgUuid -eq $imgouuid) -and ($pcRegUuid -eq $imgoowner)) {
                    $imgManagedBy = "PC"
                    $imgPCname = $pcRegName
                } elseif (($imgUuid -eq $imgouuid) -and ($pcRegUuid -ne $imgoowner)) {
                    $imgManagedBy = "Local PE"
                    $imgPCname = ""
                }
            }
            # Object to write to Excel file
            $imageInfo = [PSCustomObject]@{
                'Cluster Name' = $cluName
                'Image Name' = $imgName
                'Description' = $imgDesc
                'Storage Container' = $imgStrgName
                'Image Type' = $imgType
                'State' = $imgState
                'Managed By' = $imgManagedBy
                'PC Name' = $imgPCname
                'Size(GB)' = $imgSize
                'UUID' = $imgUuid
                'Created Date' = $imgCreateDate
                'Updated Date' = $imgUpdatedDate
                'VM Disk Id' = $imgDiskId
            }
            # Write image info to CSV report
            $imageInfo | Export-Excel -Path "$filepath$ExcelFile" -AutoSize -TableName "Images" -TableStyle Medium15 -Numberformat 'Text' -WorksheetName "Images" -Append
        }
}
############################## End Region - Functions ############################
##################################################################################


##################################################################################
############################## Region - Body #####################################
# Build initial Excel file we'll dump data to
$ExcelFile = "ImagesAudit_$(Get-Date -Format yyyy-MM-dd_HH-mm-ss).xlsx"

# Prism Central section
if ($null -ne $pclist) {
    foreach ($pc in $pclist) {
        # Get cluster list from PC
        Write-Host "Obtaining cluster list from Prism Central: $pc"
        $pcCluList = pcClusterList $pc
        foreach ($peclu in $pcCluList.entities) {
            # We only want clusters and not PC, which is filtered by AOS under service_list
            if ($peclu.status.resources.config.service_list -eq "AOS") {
                # Gather IP of the cluster
                $pe = $peclu.status.resources.network.external_ip
                # Get image info and write to report
                getImageInfo $pe
            }
        }
    }
}
# Prism Element section
if ($null -ne $pelist) {
    foreach ($pe in $pelist) {
        # Get image info and write to report
        getImageInfo $pe
    }
}
Write-Host "Finished gathering image info."
############################## End Region - Body #################################
##################################################################################