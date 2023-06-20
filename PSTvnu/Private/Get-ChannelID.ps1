function Get-ChannelID {
    [CmdletBinding()]
    param(
        [String] $file = "$PSScriptRoot\channels.json"
    )
    $json = Get-Content -Raw -Path $file | ConvertFrom-Json
    $ChannelLookup = @{}
    foreach ($item in $json.psobject.Properties) {
        $ChannelLookup[$item.Name] = $item.Value
    }
    return $ChannelLookup

}
<#
function Get-ChannelID {
    [CmdletBinding()]
    param(
        [String] $channel,
        [String] $file = "$PSScriptRoot\channels.json"
    )
    #caching the channel.json file.
    If (Test-Path -Path $file -NewerThan (Get-Date).AddDays(-7)) {
        # this makes the hashtable case sensitive which affects the argumentcompleter.. just sticking with the old method for now.
        # if ($PSVersionTable.PSVersion.Major -ge 7) {
        #     $ChannelLookup = Get-Content -Raw -Path $file | ConvertFrom-Json -AsHashtable
        # } else {
        #for better compatibility
        $json = Get-Content -Raw -Path $file | ConvertFrom-Json
        $ChannelLookup = @{}
        $json.psobject.Properties | ForEach-Object { $ChannelLookup[$_.Name] = $_.Value }
        #}
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
#>
