function Update-ChannelList {
    $OnlineChannels = @{}
    $useragent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36'
    $headers = @{
        'authority'       = 'web-api.tv.nu'
        'method'          = 'GET'
        'scheme'          = 'https'
        'accept'          = 'application/json, text/plain, */*'
        'accept-encoding' = 'gzip, deflate, br'
        'accept-language' = 'en-US,en;q=0.9,sv-SE;q=0.8,sv;q=0.7'
        'origin'          = 'https://www.tv.nu'
    }
    $allchannels = Invoke-RestMethod -UserAgent $useragent -Headers $headers -Uri https://web-api.tv.nu/packages/allChannels
    $allchannels.data | ForEach-Object {
        $OnlineChannels.add($_.Name, "ch-$($_.id)")
    }
    return $OnlineChannels
}
