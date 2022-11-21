function Get-ChannelID {
    [CmdletBinding()]
    param(
        [Parameter(ValuefromPipeline = $True)]
        [String] $channel,
        [String] $file = "$PSScriptRoot\channels.json"
    )
    If (Test-Path -Path $file -NewerThan (Get-Date).AddDays(-7)) {
        Write-Debug 'File is newer than 7 days, importing previous file'
        $ChannelLookup = Get-Content -Raw -Path $file | ConvertFrom-Json -AsHashtable
        Write-Debug "Loaded $($ChannelLookup.keys.count) channels from file"
    } else {
        #Remove-Item $file -ea 0 | Out-Null
        Write-Debug 'hashtable file too old or missing, generating new file'
        . $PSScriptRoot\Update-ChannelList.ps1
        $ChannelLookup = Update-ChannelList
        $ChannelLookup | ConvertTo-Json | Set-Content $file -Encoding UTF8BOM
        Write-Debug "Loaded $($ChannelLookup.keys.count) from Update-ChannelList, saving for next run"
    }
    if ($channel) {
        return $ChannelLookup["$($channel)"]
    } elseif (!$channel) {
        return $ChannelLookup
    }
}

