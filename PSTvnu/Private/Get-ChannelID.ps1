function Get-ChannelID {
    [CmdletBinding()]
    param(
        [Parameter(ValuefromPipeline = $True)]
        [String] $channel,
        [String] $file = "$PSScriptRoot\previous_channels.xml"
    )
    If (Test-Path -Path $file -OlderThan (Get-Date).AddDays(-7)) {
        Write-Debug 'File is newer than 7 days, importing previous hashtable'
        $ChannelLookup = Import-Clixml $file
        Write-Debug "Loaded $($ChannelLookup.keys.count) from file"
    } else {
        Remove-Item $file -ea 0 | Out-Null
        Write-Debug 'hashtable file too old or missing, generating new file'
        . $PSScriptRoot\Update-ChannelList.ps1
        $ChannelLookup = Update-ChannelList
        $ChannelLookup | Export-Clixml $file
        Write-Debug "Loaded $($ChannelLookup.keys.count) from Restapi"
    }
    if ($channel) {
        return $ChannelLookup["$($channel)"]
    } elseif (!$channel) {
        return $ChannelLookup
    }
}

