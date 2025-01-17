function Update-DSPamCheckoutPolicy {
    <#
        .SYNOPSIS
        Update a checkout policy.
        .DESCRIPTION
        Update a checkout policy using supplied parameters. Ommited parameters are ignored. If one or more parameter is
        out of range, it is ignored and a message is sent to host.
        .EXAMPLE
        $newPolicyInfos = @{
            candidPolicyID = "ad375b93-9fb7-4f37-a8c7-e20bf382f68d"
            name = "private accounts"
            isDefault = $false
        }

        > Update-DSPamCheckoutPolicy @newPolicyInfos 
        
        .EXAMPLE
        $newPolicyInfos = @{
            candidPolicyID = "ad375b93-9fb7-4f37-a8c7-e20bf382f68d"
            checkoutApprovalMode = 10
            checkoutTime = -1
        }

        > Update-DSPamCheckoutPolicy @newPolicyInfos 

        -> Checkout time cannot be less or equal to 0. Change is ignored.
        -> Checkout approval mode value should be between 0 and 2 (Inclusivly). Change is ignored.
    #>
    [CmdletBinding()]
    param (
        #Policy ID
        [ValidateNotNullOrEmpty()]
        [guid]$candidPolicyID,
        #Policy's new name
        [string]$name,
        #Policy's new checkout approval mode (None/Mandatory)
        [int]$checkoutApprovalMode,
        #Policy's new checkout reason mode (None/Mandatory/Optional)
        [int]$checkoutReasonMode,
        #Policy owner can self-checkout
        [int]$allowCheckoutOwnerAsApprover,
        #Administrators can approve checkout
        [int]$includeAdminsAsApprovers,
        #PAM managers can approve checkout
        [int]$includeManagersAsApprovers,
        #Default checkout time
        [int]$checkoutTime,
        #Is default checkout policy for all entries
        [bool]$isDefault
    )
    BEGIN {
        Write-Verbose '[Update-DSPamFolder] Beginning...'

        if ([string]::IsNullOrWhiteSpace($Global:DSSessionToken)) {
            throw "Session does not seem authenticated, call New-DSSession."
        }
    }
    PROCESS {
        try {
            $URI = "$Script:DSBaseURI/api/pam/checkout-policies/$candidPolicyID"

            #Getting policy infos
            $params = @{
                Uri    = $URI
                Method = 'GET'
            }
            $res = Invoke-DS @params

            if ($res.Body) {
                $policyInfos = @{}
                foreach ($property in $res.Body.PSObject.Properties) {
                    $policyInfos[$property.Name] = $property.Value
                }

                $PSBoundParameters.GetEnumerator() | ForEach-Object {
                    if ($policyInfos.ContainsKey($_.Key)) {
                        $isValid = $true
    
                        switch ($_) {
                            { $_.Key -eq 'allowCheckoutOwnerAsApprover' } { 
                                if ($_.Value -notin (0, 1, 2) ) { 
                                    $isValid = $false 
                                    Write-Host "Allow checkout owner as approver value should be between 0 and 2 (Inclusivly)." -ForegroundColor Red
                                }
                            }
                            { $_.Key -eq 'checkoutApprovalMode' } { 
                                if ($_.Value -notin (0, 1, 2)) {
                                    $isValid = $false 
                                    Write-Host "Checkout approval mode value should be between 0 and 2 (Inclusivly)." -ForegroundColor Red
                                }
                            }
                            { $_.Key -eq 'checkoutReasonMode' } { 
                                if ($_.Value -notin (0, 1, 2 , 3) ) {
                                    $isValid = $false 
                                    Write-Host "Checkout reason mode value should be between 0 and 3 (Inclusivly)." -ForegroundColor Red
                                }
                            }                        
                            { $_.Key -eq 'includeAdminsAsApprovers' } {
                                if ($_.Value -notin (0, 1, 2) ) {
                                    $isValid = $false
                                    Write-Host "Include admins as approvers value should be between 0 and 2 (Inclusivly)." -ForegroundColor Red
                                }
                            }
                            { $_.Key -eq 'includeManagersAsApprovers' } {
                                if ($_.Value -notin (0, 1, 2) ) {
                                    $isValid = $false 
                                    Write-Host "Include managers as approvers value should be between 0 and 2 (Inclusivly)." -ForegroundColor Red
                                }
                            } 
                            { $_.Key -eq 'checkoutTime' } {
                                if ($_.Value -le 0) {
                                    $isValid = $false 
                                    Write-Host "Checkout time value of 0 or less is not accepted." -ForegroundColor Red
                                }
                            }         
                        }
    
                        if ($isValid) {
                            $policyInfos[$_.Key] = $_.Value
                        }
                        else {
                            Write-Host "Value was ignored." -ForegroundColor Red
                        }
                    }
                }
                
                $params = @{
                    Uri    = $URI
                    Method = 'PUT'
                    Body   = $policyInfos | ConvertTo-Json  -Depth 100
                }
    
                $res = Invoke-DS @params
                return $res
            }
            else {
                Write-Host "[Update-DSPamCheckoutPolicy] Checkout policy couldn't be found. Make sure that you are using the correct checkout policy ID and try again." -ForegroundColor Red
            }   
        }
        catch { 
            $exc = $_.Exception
            If ([System.Management.Automation.ActionPreference]::Break -ne $DebugPreference) {
                Write-Debug "[Exception] $exc"
            } 
        }
    }
    END {
        If ($res.isSuccess) {
            Write-Verbose '[New-DSPamTeamFolders] Completed Successfully.'
        }
        else {
            Write-Verbose '[New-DSPamTeamFolders] Ended with errors...'
        }
    }
}