function Get-DSServerInfo{
<#
.SYNOPSIS

.DESCRIPTION

.EXAMPLE

.NOTES
This endpoint does not require authentication.

.LINK
#>
	[CmdletBinding()]
	param(			
		[parameter(Mandatory)]
		[string]$BaseURI
	)
	
	BEGIN {
        Write-Verbose '[Get-DSServerInfo] begin...'

		<# 
		We can call the api repeatedly, even after we've established the session.  We must close the existing session only if we change the URI
		 #>
		if ($Script:DSBaseURI -ne $BaseURI)
		{
			if ($Script:DSSessionToken)
			{
				throw "Session already established, Close it before switching servers."
			}
		}

		#only time we use baseURI as provided, we will set variable only upon success
		$URI = "$BaseURI/api/server-information"
	}

	PROCESS {

		try
		{
			$response = Invoke-WebRequest -URI $URI -Method 'GET' -SessionVariable script:WebSession

			If ($null -ne $response) {
				$jsonContent = $response.Content | ConvertFrom-JSon
	
				Write-Verbose "[Get-DSServerInfo] Got response from ""$($jsonContent.data.servername)"""
				
				If ([System.Management.Automation.ActionPreference]::SilentlyContinue -ne $DebugPreference) {
						Write-Debug "[Response.Data] $($jsonContent)"
				}
				
				$publickey_mod = $jsonContent.data.publicKey.modulus
				$publickey_exp = $jsonContent.data.publicKey.exponent
				$session_Key = New-CryptographicKey
				$safeSessionKey = Encrypt-RSA -publickey_mod $publickey_mod -publickey_exp $publickey_exp -session_Key $session_Key

				[System.Version]$instanceVersion = $jsonContent.data.version

				Set-Variable -Name DSBaseURI -Value $BaseURI -Scope Script
				Set-Variable -Name DSKeyExp -Value $publickey_exp -Scope Script
				Set-Variable -Name DSKeyMod -Value $publickey_mod -Scope Script
				Set-Variable -Name DSSessionKey -Value $session_Key -Scope Script
				Set-Variable -Name DSSafeSessionKey -Value $safeSessionKey -Scope Script
				Set-Variable -Name DSInstanceVersion -Value $instanceVersion -Scope Script
				Set-Variable -Name DSInstanceName -Value $jsonContent.data.serverName -Scope Script

				return [ServerResponse]::new(($response.StatusCode -eq 200), $response, $jsonContent, $null, "", $response.StatusCode)
			}
			return [ServerResponse]::new(($false), $null, $null, $null, "", 500)	
		}
		catch
		{
			$exc = $_.Exception
			If ([System.Management.Automation.ActionPreference]::SilentlyContinue -ne $DebugPreference) {
					Write-Debug "[Exception] $exc"
			} 
		}
	}

	END {
	   If ($?) {
          Write-Verbose '[Get-DSServerInfo] Completed Successfully.'
        } else {
	        Write-Verbose '[Get-DSServerInfo] ended with errors...'
		}
	}
}