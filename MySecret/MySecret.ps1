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
#>

function Set-MySecret {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Value,
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
    $securekey = ConvertTo-SecureString -String $Encryptionkey -AsPlainText -Force
    $file = "$($path)\$($name).json"
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
