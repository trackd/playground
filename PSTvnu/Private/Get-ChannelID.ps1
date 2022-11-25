function Get-ChannelID {
    [CmdletBinding()]
    param(
        [String] $channel,
        [String] $file = "$PSScriptRoot\channels.json"
    )
    #caching the channel.json file.
    If (Test-Path -Path $file -NewerThan (Get-Date).AddDays(-7)) {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $ChannelLookup = Get-Content -Raw -Path $file | ConvertFrom-Json -AsHashtable
        } else {
            #for better compatibility
            $json = Get-Content -Raw -Path $file | ConvertFrom-Json
            $ChannelLookup = @{}
            $json.psobject.Properties | ForEach-Object { $ChannelLookup[$_.Name] = $_.Value }
        }
    } else {
        $ChannelLookup = Update-ChannelList
        $ChannelLookup | ConvertTo-Json | Set-Content $file -Encoding UTF8
    }
    if ($channel) {
        return $ChannelLookup["$($channel)"]
    } else {
        return $ChannelLookup
    }
}

