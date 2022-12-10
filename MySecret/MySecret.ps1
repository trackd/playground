#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
<#
testing securestring and encrypted string for storing values more securely
trackd 2022-12-07
note set-mysecret will overwrite any existing secret stored with that name.

depending on locale might need change the encoding
([System.Text.Encoding]::ASCII)
([System.Text.Encoding]::Unicode)
([system.Text.Encoding]::UTF8)
([System.Text.Encoding]::Default)
.EXAMPLE
Set-MySecret -Name Secretsauce -Value Sugar -Location Cloud -Notes 'super secret ingredient' -Encryptionkey abcdef1234567890
Get-MySecret -Name SecretSauce -Location Cloud -Encryptionkey abcdef1234567890
Get-MySecretList -Location Cloud
Remove-MySecret -Name Secretsauce -Location Cloud

Username and Notes are optional, just if you need to store something or use for PSCredentials.
only the actual secret is encrypted.
#>

Function Set-MySecret {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Secret,
        [ArgumentCompletions('Cloud','Local','OneDrive')]
        [String] $Location,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (([system.Text.Encoding]::UTF8).GetByteCount($_) * 8 -in 128,192,256) {
                    $true
                } else {
                    throw "$_ invalid, Bitlength: $(([system.Text.Encoding]::UTF8).GetByteCount($_)) Needs to be divisible by 8 (128,192,256 bit keys)."
                }
            })]
        [String] $Encryptionkey,
        [String] $Username,
        [String] $Notes
    )
    Switch ($Location) {
        Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/googledrive folder
        Local { if (-not (Test-Path -Path "$env:localappdata\secrets")) { New-Item -Path "$env:localappdata\secrets" -ItemType Directory } $path = "$env:localappdata\secrets" }
        OneDrive { if (-not (Test-Path -Path "$env:OneDrive\secrets")) { New-Item -Path "$env:OneDrive\secrets" -ItemType Directory } $path = "$env:OneDrive\secrets" }
        Default { $path = "$pshpath\profile\secrets" }
    }
    try {
        $securekey = ConvertTo-SecureString -String $Encryptionkey -AsPlainText
        $SecureString = ConvertTo-SecureString -AsPlainText -String $Value
        $encryptedstring = ConvertFrom-SecureString –SecureKey $securekey -SecureString $SecureString
        $SecretObject = [PSCustomObject] @{
            Name     = $Name
            Username = $Username
            Secret   = $encryptedstring
            Notes    = $Notes
        }
        $file = Join-Path $path ($name + '.json')
        $SecretObject | ConvertTo-Json | Set-Content $file -Encoding UTF8
    } catch [System.Security.Cryptography.CryptographicException] {
        Write-Error "$($Name) something went wrong during encryption`n$($PSItem.ToString())"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error "$($name) error`n$($PSItem.ToString())"
    } catch {
        Write-Error "ERROR $($error[0].exception.message)"
    }
}

Function Get-MySecret {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [ArgumentCompletions('Cloud','Local','OneDrive')]
        [String] $Location,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Encryptionkey,
        [switch] $PSCredential,
        [Switch] $Print
    )
    Switch ($Location) {
        Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/onedrive/googledrive folder
        Local { $path = "$env:localappdata\secrets" }
        OneDrive { $path = "$env:OneDrive\secrets" }
        Default { $path = "$pshpath\profile\secrets" }
    }
    try {
        $file = Join-Path $path ($name + '.json')
        $null = Test-Path -Path $file
        $securekey = ConvertTo-SecureString -String $Encryptionkey -AsPlainText
        $import = Get-Content -Raw -Path $file -Encoding UTF8 | ConvertFrom-Json
        $secretstring = ConvertTo-SecureString -String $import.Secret –SecureKey $securekey
        $plaintext = ConvertFrom-SecureString -AsPlainText $secretstring
        if ($PSCredential) {
            $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $import.Username, $secretstring
            return $credentials
        } elseif ($Print) {
            $object = [PSCustomObject]@{
                Name     = $Import.Name
                Username = $Import.Username
                Secret   = $plaintext
                Notes    = $import.notes
            }
            return $object
        } else {
            return $plaintext
        }
    } catch [System.Security.Cryptography.CryptographicException] {
        Write-Error "Wrong SecureKey for $($Name)"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error "$($name) secret not found`n$($PSItem.ToString())"
    } catch {
        Write-Error "ERROR $($error[0].exception.message)"
    }
}

Function Get-MySecretList {
    param(
        [ArgumentCompletions('Cloud','Local','OneDrive')]
        [String] $Location
    )
    Switch ($Location) {
        Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/onedrive/googledrive folder
        Local { $path = "$env:localappdata\secrets" }
        OneDrive { $path = "$env:OneDrive\secrets" }
        Default { $path = "$pshpath\profile\secrets" }
    }
    try {
        $null = Test-Path -Path $path
        $secrets = Get-ChildItem -Path $path -Filter *.json
        if ($secrets) {
            $list = foreach ($item in $secrets) {
                $load = Get-Content -Raw -Path $item.FullName -Encoding UTF8 | ConvertFrom-Json -AsHashtable
                [PSCustomObject] @{
                    Created  = (Get-Date $item.CreationTime -Format 'yyyy-MM-dd')
                    Name     = $load.Name
                    Username = $load.Username
                    Notes    = $load.Notes
                }
            }
            return $list
        } else { return 'no secrets found for this location' }
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error "$($PSItem.ToString())"
    } catch {
        Write-Error "ERROR $($error[0].exception.message)"
    }
}

Function Remove-MySecret {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [ArgumentCompletions('Cloud','Local','OneDrive')]
        [String] $Location
    )
    Switch ($Location) {
        Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/onedrive/googledrive folder
        Local { $path = "$env:localappdata\secrets" }
        OneDrive { $path = "$env:OneDrive\secrets" }
        Default { $path = "$pshpath\profile\secrets" }
    }
    try {
        $file = Join-Path $path ($name + '.json')
        $null = Test-Path -Path $file
        Remove-Item -Path $file
        if (-not (Test-Path -Path $file)) {
            return "$($name) deleted from $($path)"
        }
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error "$($name) secret not found`n$($PSItem.ToString())"
    } catch {
        Write-Error "ERROR $($error[0].exception.message)"
    }
}