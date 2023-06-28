#Requires -Version 7.0
<#
testing securestring and encrypted string for storing secrets more securely
trackd 2022-12-07
note set-mysecret will overwrite any existing secret stored with that name.

depending on locale might need change the encoding
([System.Text.Encoding]::ASCII)
([System.Text.Encoding]::Unicode)
([system.Text.Encoding]::UTF8)
([System.Text.Encoding]::Default)
.EXAMPLE
Set-MySecret -Name Secretsauce -Secret Sugar -Location Cloud -Notes 'super secret ingredient' -Encryptionkey abcdef1234567890
Get-MySecret -Name SecretSauce -Location Cloud -Encryptionkey abcdef1234567890
Get-MySecretList -Location Cloud
Remove-MySecret -Name Secretsauce -Location Cloud
.Example
Using DAPI, only works for the user running it and on the same computer.
Set-MySecret -Name SecretSauce -Secret 'secret stuff' -Location Cloud -Notes 'DAPI, unsharable. this computer and this user only' -DAPI

Username and Notes are optional, just if you need to store something or use for PSCredentials.
only the actual secret is encrypted.
#>

Function Set-MySecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Secret,
        [ArgumentCompletions('Cloud','Local','OneDrive','appdata')]
        [String] $Location,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true,ParameterSetName = 'EncryptionKey')]
        [ValidateScript({
                if (([system.Text.Encoding]::UTF8).GetByteCount($_) * 8 -in 128,192,256) {
                    $true
                } else {
                    throw "$_ invalid, Bitlength: $(([system.Text.Encoding]::UTF8).GetByteCount($_)) Needs to be divisible by 8 (128,192,256 bit keys)."
                }
            })]
        [String] $Encryptionkey,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String] $Username,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Notes,
        [Parameter(Mandatory = $true,ParameterSetName = 'DAPI')]
        [Switch] $DAPI
    )
    Switch ($Location) {
        Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/googledrive folder
        Local { if (-not (Test-Path -Path "$env:localappdata\secrets")) { New-Item -Path "$env:localappdata\secrets" -ItemType Directory } $path = "$env:localappdata\secrets" }
        OneDrive { if (-not (Test-Path -Path "$env:OneDrive\secrets")) { New-Item -Path "$env:OneDrive\secrets" -ItemType Directory } $path = "$env:OneDrive\secrets" }
        appdata { if (-not (Test-Path -Path "$env:appdata\secrets")) { New-Item -Path "$env:appdata\secrets" -ItemType Directory } $path = "$env:appdata\secrets" }
        Default { $path = "$pshpath\profile\secrets" }
    }
    $owner = Join-Path $env:computername $env:username
    $datetime = Get-Date -Format 'yyyy-MM-dd HH:mm'
    try {
        if ($encryptionkey) {
            #securekey is needed to share credentials or use on different machines.
            $securekey = ConvertTo-SecureString -String $Encryptionkey -AsPlainText
            $SecureString = ConvertTo-SecureString -AsPlainText -String $Secret
            $encryptedstring = ConvertFrom-SecureString –SecureKey $securekey -SecureString $SecureString
            $type = 'EncryptionKey'
        } elseif ($DAPI) {
            #Windows Built in encryption scheme without securekey, only usable on the same machin with the same user.
            $SecureString = ConvertTo-SecureString -AsPlainText -String $Secret
            $encryptedstring = ConvertFrom-SecureString -SecureString $SecureString
            $type = 'DAPI'
        }
        $SecretObject = [PSCustomObject] @{
            Name     = $Name
            Username = $Username
            Secret   = $encryptedstring
            Notes    = $Notes
            Type     = $type
            Owner    = $owner
            Created  = $datetime
        }
        $file = Join-Path $path ($name + '.secret.json')
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [ArgumentCompletions('Cloud','Local','OneDrive','appdata')]
        [String] $Location,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory,ParameterSetName = 'EncryptionKey')]
        [String] $Encryptionkey,
        [Parameter()]
        [switch] $PSCredential,
        [Parameter()]
        [Switch] $Print,
        [Parameter(Mandatory,ParameterSetName = 'DAPI')]
        [Switch] $DAPI
    )
    begin {
        Switch ($Location) {
            Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/onedrive/googledrive folder
            Local { $path = "$env:localappdata\secrets" }
            OneDrive { $path = "$env:OneDrive\secrets" }
            appdata { $path = "$env:appdata\secrets" }
            Default { $path = "$pshpath\profile\secrets" }
        }
        $file = Join-Path $path ($name + '.secret.json')
        $null = Test-Path -Path $file
        $import = Get-Content -Raw -Path $file -Encoding UTF8 | ConvertFrom-Json
    }
    process {
        try {
            if ($Encryptionkey) {
                $securekey = ConvertTo-SecureString -String $Encryptionkey -AsPlainText
                $secretstring = ConvertTo-SecureString -String $import.Secret –SecureKey $securekey
                $plaintext = ConvertFrom-SecureString -AsPlainText $secretstring
            } elseif ($DAPI) {
                $secretstring = ConvertTo-SecureString -String $import.Secret
                $plaintext = ConvertFrom-SecureString -AsPlainText $secretstring
            }
        } catch [System.Security.Cryptography.CryptographicException] {
            Write-Error "Wrong SecureKey for $($Name), encryptionmethod: $($import.Type)"
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Error "$($name) secret not found`n$($PSItem.ToString())"
        } catch {
            Write-Error "ERROR $($error[0].exception.message)"
        }
    }
    end {
        if ($PSCredential) {
            $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $import.Username, $secretstring
            return $credentials
        } elseif ($Print) {
            $object = [PSCustomObject]@{
                Name     = $Import.Name
                Username = $Import.Username
                Secret   = $plaintext
                Notes    = $import.notes
                Type     = $Import.Type
                Owner    = $Import.Owner
                Created  = $import.created
            }
            return $object
        } else {
            return $plaintext
        }
    }
}

Function Get-MySecretList {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ArgumentCompletions('Cloud','Local','OneDrive','appdata')]
        [String] $Location
    )
    Switch ($Location) {
        Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/onedrive/googledrive folder
        Local { $path = "$env:localappdata\secrets" }
        OneDrive { $path = "$env:OneDrive\secrets" }
        appdata { $path = "$env:appdata\secrets" }
        Default { $path = "$pshpath\profile\secrets" }
    }
    try {
        $null = Test-Path -Path $path
        $secrets = Get-ChildItem -Path $path -Filter *.secret.json
        if ($secrets) {
            $list = foreach ($item in $secrets) {
                $load = Get-Content -Raw -Path $item.FullName -Encoding UTF8 | ConvertFrom-Json
                [PSCustomObject] @{
                    #Created  = (Get-Date $item.CreationTime -Format 'yyyy-MM-dd')
                    Name     = $load.Name
                    Username = $load.Username
                    Notes    = $load.Notes
                    Type     = $load.Type
                    Owner    = $load.Owner
                    Created  = $load.created
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [ArgumentCompletions('Cloud','Local','OneDrive','appdata')]
        [String] $Location
    )
    Switch ($Location) {
        Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/onedrive/googledrive folder
        Local { $path = "$env:localappdata\secrets" }
        OneDrive { $path = "$env:OneDrive\secrets" }
        appdata { $path = "$env:appdata\secrets" }
        Default { $path = "$pshpath\profile\secrets" }
    }
    try {
        $file = Join-Path $path ($name + '.secret.json')
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
