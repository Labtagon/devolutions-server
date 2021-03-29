function Update-DSPamFolder {
    <#
    .SYNOPSIS
    Update a PAM folder with given values.
    .DESCRIPTION
    Update a PAM folder with given parameters. Goes through every parameter and check if 
    key match a key in current folder data. If so, updates current folder data and send 'PUT' web request.
    .EXAMPLE
    $updatedFolderData = @{
        folderID = 'ae7884bd-e8e9-4c17-b03e-7ae61b19797e' #Root folder
        allowCheckoutOwnerAsApprover = 1
        checkoutApprovalMode = 1
        checkoutReasonMode = 1
        checkoutTime = 25
        includeAdminsAsApprovers = 1
        includeManagersAsApprovers = 1
        name = 'ROOTTEST'
    }

    Update-DSPamFolder @updatedFolderData
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$candidFolderID,
        [string]$name,
        [string]$folderID,
        [int]$checkoutApprovalMode,
        [int]$checkoutReasonMode,
        [int]$allowCheckoutOwnerAsApprover,
        [int]$includeAdminsAsApprovers,
        [int]$includeManagersAsApprovers,
        [int]$checkoutTime
    )
    BEGIN {
        Write-Verbose '[Update-DSPamFolder] Begin...'
        $URI = "$Script:DSBaseURI/api/pam/folders/$candidFolderID"

        if ([string]::IsNullOrWhiteSpace($Script:DSSessionToken)) {
            throw "Session does not seem authenticated, call New-DSSession."
        }
    }
    PROCESS {
        try {
            #Getting folder infos
            $params = @{
                Uri    = $URI
                Method = 'GET'
            }
            $res = Invoke-DS -Uri $URI -method 'GET'

            if ($res.Body) {
                $folderInfos = @{}
                foreach ($property in $res.Body.PSObject.Properties) {
                    $folderInfos[$property.Name] = $property.Value
                }
            }
            else {
                Write-Verbose "[Update-DSPamFolder] Folder couldn't be found. Make sure that you are using the correct folder ID and try again."
            }   

            $PSBoundParameters.GetEnumerator() | ForEach-Object {
                if ($folderInfos.ContainsKey($_.Key)) {
                    $isValid = $true

                    switch ($_) {
                        ($_.Key -eq 'allowCheckoutOwnerAsApprover') { 
                            if ($_.Value -notin (0, 1, 2) ) { $isValid = $false }
                        }
                        ($_.Key -eq 'checkoutApprovalMode') { 
                            if ($_.Value -notin (0, 1, 2) ) { $isValid = $false }
                        }
                        ($_.Key -eq 'checkoutReasonMode') { 
                            if ($_.Value -notin (0, 1, 2 , 3) ) { $isValid = $false }
                        }                        
                        ($_.Key -eq 'includeAdminsAsApprovers') {
                            if ($_.Value -notin (0, 1, 2) ) { $isValid = $false }
                        }
                        ($_.Key -eq 'includeManagersAsApprovers') {
                            if ($_.Value -notin (0, 1, 2) ) { $isValid = $false }
                        }        
                    }

                    if ($isValid) {
                        $folderInfos[$_.Key] = $_.Value
                    }
                    else {
                        #Todo: Invalid param
                        Write-Host "Shouldnt see this"
                    }
                }
            }
            
            $params = @{
                Uri    = $URI
                Method = 'PUT'
                Body   = $folderInfos | ConvertTo-Json
            }

            return Invoke-DS @params
        }
        catch { 
            $exc = $_.Exception
            If ([System.Management.Automation.ActionPreference]::Break -ne $DebugPreference) {
                Write-Debug "[Exception] $exc"
            } 
        }
    }
    END {
        If ($?) {
            Write-Verbose '[New-DSPamFolders] Completed Successfully.'
        }
        else {
            Write-Verbose '[New-DSPamFolders] Ended with errors...'
        }
    }
}