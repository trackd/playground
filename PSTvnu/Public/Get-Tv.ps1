function Get-Tv {
    <#
    .SYNOPSIS
    get tv schedule for swedish tv from tv.nu
    unofficial use of api... could break

    .EXAMPLE
    Get-Tvnu
    works without parameters

    .PARAMETER Day
    -Day Today (default)
    -Day Tomorrow

    .PARAMETER Full
    Show all values, skips defaultdisplay stuff

    .PARAMETER Channel
    Show only select channel, autocomplete is available
    Get-Tv -Channel SVT1
    Get-Tv -Channel "SVT Barn"

    .PARAMETER Title
    Wildcard search through schedule for title
    Get-Tv -Title Macgyver
    Get-Tv -Title "Without a Trace"

    .PARAMETER Movies
    Filter output for things tagged with type Movies
    Get-Tv -Movies
    Can be combined like
    Get-Tv -Channel TV6 -Movies

    .PARAMETER Series
    Filter output for things tagged with type Series
    Get-Tv -Series
    Get-Tv -Series -Channel "Kanal 5"

    .NOTES
    Default channel selection is the same as going to tv.nu
    .LINK
    credit www.tv.nu
#>
    [CmdletBinding()]
    param(
        [ArgumentCompletions( 'Today', 'Tomorrow' )]
        [string] $Day,
        [Switch] $Full,
        [string] $Channel,
        [string] $Title,
        [Switch] $Movies,
        [Switch] $Series
    )
    begin {
        switch ($Day) {
            Today { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
            Tomorrow { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).ToString('yyyy-MM-dd') } else { $date = (Get-Date).AddDays(1).ToString('yyyy-MM-dd') } }
            Default { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
        }
        $tvschedule = [System.Collections.Generic.List[psobject]]::new()
        $ChannelLookup = Get-ChannelID
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
        $allchannels = '&modules[]=pp-13&modules[]=pp-12&modules[]=ch-51&modules[]=ch-52&modules[]=pp-14&modules[]=ed-6&modules[]=pp-18&modules[]=ch-60&modules[]=ed-19&modules[]=ch-27&modules[]=pl-3&modules[]=pp-31&modules[]=ch-63&modules[]=ch-65&modules[]=pp-9&modules[]=ch-64&modules[]=ed-15&modules[]=ch-66&modules[]=pp-34&modules[]=ch-67&modules[]=pp-30&modules[]=tl-13&modules[]=ch-68&modules[]=pp-4&modules[]=ch-70&modules[]=pp-16&modules[]=ch-88&modules[]=pc-8&modules[]=ch-132&modules[]=pl-2&modules[]=ch-49&modules[]=ch-53&modules[]=pp-33&modules[]=ch-54&modules[]=pp-36&modules[]=ch-30233'
    }
    process {
        try {
            if ($Channel) {
                $channelselection = "&modules[]=$($ChannelLookup[$Channel])"
            }
            if (!$Channel) {
                $channelselection = $allchannels
            }
            $url = "https://web-api.tv.nu/startFeed?date=$($date)&limit=8$($channelselection)&offset=0"
            $raw = Invoke-RestMethod -UseBasicParsing -UserAgent $useragent -Headers $headers -Uri $url
            $Response += $raw.data.modules.content
            while ($null -ne $raw.data.nextoffset) {
                $url = "https://web-api.tv.nu/startFeed?date=$($date)&limit=12$($channelselection)&offset=$($raw.data.nextoffset)"
                $raw = Invoke-RestMethod -UserAgent $useragent -Headers $headers -Uri $url
                $Response += $raw.data.modules.content
            }
            $Response | ForEach-Object {
                $chan = $_.name
                $_.broadcasts | ForEach-Object {
                    if ($null -ne $_.type -And $_.endTime -gt [DateTimeOffset]::Now.ToUnixTimeMilliSeconds() ) {
                        $object = [pscustomobject]@{
                            Channel   = $chan
                            Title     = $_.title
                            StartFull = [System.DateTimeOffset]::FromUnixTimeMilliseconds($_.startTime).LocalDateTime.ToString('yyyy-MM-dd HH:mm')
                            EndFull   = [System.DateTimeOffset]::FromUnixTimeMilliseconds($_.endTime).LocalDateTime.ToString('yyyy-MM-dd HH:mm')
                            Start     = [System.DateTimeOffset]::FromUnixTimeMilliseconds($_.startTime).LocalDateTime.ToString('ddd HH:mm')
                            End       = [System.DateTimeOffset]::FromUnixTimeMilliseconds($_.endTime).LocalDateTime.ToString('ddd HH:mm')
                            Tags      = $_.tags -join ','
                            Type      = $_.type
                            Movie     = $_.isMovie
                            Rating    = $_.imdb.rating
                            imdb      = $_.imdb.link
                        }
                        $tvschedule.add($object)
                    }
                }
            }
        } catch {
            Write-Error "ERROR $($error[0].exception.message)"
            break
        }
    }
    end {
        if (!$Full) {
            $fields = 'Channel', 'Title', 'Start', 'End'
            $default = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$fields)
            $members = [System.Management.Automation.PSMemberInfo[]]@($default)
            $tvschedule | Add-Member MemberSet PSStandardMembers $members
        }
        if ($Title) {
            $tvschedule | Where-Object -FilterScript { $_.Title -like "$($Title)" } | Sort-Object -Property StartFull
        } elseif ($Movies) {
            $tvschedule | Where-Object -FilterScript { $_.Movie -eq 'true' } | Sort-Object -Property StartFull
        } elseif ($Series) {
            $tvschedule | Where-Object -FilterScript { $_.Tags -like '*series*' } | Sort-Object -Property StartFull
        } else {
            $tvschedule | Sort-Object -Property StartFull
        }
    }
}
