function Get-ChannelID {
    [CmdletBinding()]
    param(
        [String] $channel,
        [String] $file = "$PSScriptRoot\channels.json"
    )
    #caching the channel.json file.
    If (Test-Path -Path $file -NewerThan (Get-Date).AddDays(-7)) {
        $ChannelLookup = Get-Content -Raw -Path $file | ConvertFrom-Json -AsHashtable
    } else {
        $ChannelLookup = Update-ChannelList
        $ChannelLookup | ConvertTo-Json | Set-Content $file -Encoding UTF8BOM
    }
    if ($channel) {
        return $ChannelLookup["$($channel)"]
    } elseif (!$channel) {
        return $ChannelLookup
    }
}

