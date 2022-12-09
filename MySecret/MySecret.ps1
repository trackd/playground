#Requires -Version 7.0
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
#>

Function Set-MySecret {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Value,
        [ArgumentCompletions('Cloud','Local','OneDrive')]
        [String] $Location,
        [String] $Notes,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (([system.Text.Encoding]::UTF8).GetByteCount($_) * 8 -in 128,192,256) {
                    $true
                } else {
                    throw "$_ invalid, Bitlength: $(([system.Text.Encoding]::UTF8).GetByteCount($_)) Needs to be divisible by 8 (128,192,256 bit keys)."
                }
            })]
        [String] $Encryptionkey
    )
    Switch ($Location) {
        Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/googledrive folder
        Local { if (-not (Test-Path -Path "$env:localappdata\secrets")) { New-Item -Path "$env:localappdata\secrets" -ItemType Directory } $path = "$env:localappdata\secrets" }
        OneDrive { if (-not (Test-Path -Path "$env:OneDrive\secrets")) { New-Item -Path "$env:OneDrive\secrets" -ItemType Directory } $path = "$env:OneDrive\secrets" }
        Default { $path = "$pshpath\profile\secrets" }
    }
    $securekey = ConvertTo-SecureString -String $Encryptionkey -AsPlainText -Force
    $SecureString = ConvertTo-SecureString -AsPlainText -String $Value
    $EncryptedString = @{
        Name            = $Name
        EncryptedString = $SecureString | ConvertFrom-SecureString –SecureKey $securekey
        Notes           = $Notes
    }
    $file = "$($path)\$($Name).json"
    $EncryptedString | ConvertTo-Json | Set-Content $file -Encoding UTF8
}

Function Get-MySecret {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [ArgumentCompletions('Cloud','Local','OneDrive')]
        [String] $Location,
        [switch] $AsSecureString,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (([system.Text.Encoding]::UTF8).GetByteCount($_) * 8 -in 128,192,256) {
                    $true
                } else {
                    throw "$_ invalid, Bitlength: $(([system.Text.Encoding]::UTF8).GetByteCount($_)) Needs to be divisible by 8 (128,192,256 bit keys)."
                }
            })]
        [String] $Encryptionkey
    )
    Switch ($Location) {
        Cloud { $path = "$pshpath\profile\secrets" } #update this to dropbox/onedrive/googledrive folder
        Local { $path = "$env:localappdata\secrets" }
        OneDrive { $path = "$env:OneDrive\secrets" }
        Default { $path = "$pshpath\profile\secrets" }
    }
    $file = "$($path)\$($name).json"
    if (-not (Test-Path -Path $file)) { throw "$($Name) secret does not exist in this location, check name and location" }
    $securekey = ConvertTo-SecureString -String $Encryptionkey -AsPlainText -Force
    $import = Get-Content -Raw -Path $file -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    $secret = ConvertTo-SecureString -String $import.EncryptedString –SecureKey $securekey
    if (!$AsSecureString) {
        $text = ConvertFrom-SecureString -AsPlainText $secret
        return $text
    }
    if ($AsSecureString) {
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Name, $secret
        return $credentials
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
    if (-not (Test-Path -Path $path)) { throw 'No secrets folder found in this location' }
    $secrets = Get-ChildItem -Path $path -Filter *.json
    if (!$secrets) { throw 'No secrets found in this location' }
    $list = foreach ($item in $secrets) {
        $load = Get-Content -Raw -Path $item.FullName -Encoding UTF8 | ConvertFrom-Json -AsHashtable
        [PSCustomObject] @{
            Created = (Get-Date $item.CreationTime -Format 'yyyy-MM-dd')
            Name    = $load.Name
            Notes   = $load.Notes
        }
    }
    return $list
}