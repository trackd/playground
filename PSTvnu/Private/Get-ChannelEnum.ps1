#not working
#TODO: fix enum foreach..pretty broken right now

function Get-ChannelEnum {
    [CmdletBinding()]
    param(
        [Parameter(ValuefromPipeline = $True)]
        [String] $file = "$PSScriptRoot\previous_channels.json",
        [String] $fileEnum = "$PSScriptRoot\enum_channels.json"
    )
    If (Test-Path -Path $file -NewerThan (Get-Date).AddDays(-7)) {
        Write-Debug 'File is newer than 7 days, importing previous hashtable'
        $chanEnumload = Get-Content -Raw -Path $file | ConvertFrom-Json -AsHashtable
        Write-Debug "Loaded $($chanEnumload.keys.count) from file"
    } else {
        #Remove-Item $file -ea 0 | Out-Null
        #Remove-Item $fileEnum -ea 0 | Out-Null
        Write-Debug 'hashtable file too old or missing, generating new file'
        . $PSScriptRoot\Update-ChannelList.ps1
        $chanEnumload = Update-ChannelList
        $chanEnumload | ConvertTo-Json | Set-Content $file -Encoding UTF8BOM
        Write-Debug "Loaded $($chanEnumload.keys.count) from Restapi"
    }
    #try turn it into an enum
    $ChannelEnum = "enum Channel{$(foreach ($item in $chanEnumload.Keys){"`n$("$item")`"})`n}"
    Invoke-Expression $ChannelEnum
    $chanEnumload.keys | ConvertTo-Json | Set-Content $fileEnum -Encoding UTF8BOM
    return $ChannelEnum
}