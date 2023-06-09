﻿function Get-Tv {
    <#
    .SYNOPSIS
    get tv schedule for swedish tv from tv.nu
    unofficial use of api... could break

    .EXAMPLE
    Get-Tv
    default listing (same as on www.tv.nu)

    .EXAMPLE
    Get-Tv -Channel SVT1
    show SVT1 list
    PS C:\> Get-Tv -Channel "SVT Barn"
    Show SVT Barn

    .EXAMPLE
    Get-Tv -Title Macgyver
    Search for MacGyver on todays tv schedule (with default channels)
    PS C:\> Get-Tv -Title "Without a Trace"
    Search for Witout a Trace (with default channels)

    .EXAMPLE
    Get-Tv -Movies
    Show todays Movies (with default channel selection)
    PS C:\> Get-Tv -Channel TV6 -Movies
    show movies on Tv6

    .EXAMPLE
    Get-Tv -Series
    show Series on todays schedule (with default channel selection)
    PS C:\> Get-Tv -Series -Channel "Kanal 5"
    Show Series on Kanal 5.

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
    cannot combine -Movies & -Series & -Title.
    TODO: add better support for config / dynamic channellist as default. so you could set your own default channels.
    .LINK
    credit www.tv.nu
#>
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    param(
        [ValidateSet('Today','Tomorrow')]
        [String]
        $Day,
        [Switch]
        $Full,
        [Parameter(ParameterSetName = 'Title')]
        [String]
        $Title,
        [Parameter(ParameterSetName = 'Movies')]
        [Switch]
        $Movies,
        [Parameter(ParameterSetName = 'Series')]
        [Switch]
        $Series,
        [String]
        $Channel
    )
    begin {
        Write-Verbose "Module: $($ExecutionContext.SessionState.Module.Name) Command: $($MyInvocation.MyCommand.Name) ParameterSetName: $($PSCmdlet.ParameterSetName) Param: $($PSBoundParameters.GetEnumerator())"
        switch ($Day) {
            Today { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
            Tomorrow { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).ToString('yyyy-MM-dd') } else { $date = (Get-Date).AddDays(1).ToString('yyyy-MM-dd') } }
            Default { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
        }
        $tvschedule = [System.Collections.Generic.List[psobject]]::new()
        $useragent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36'
        $headers = @{
            'authority'       = 'web-api.tv.nu'
            'method'          = 'GET'
            'scheme'          = 'https'
            'accept'          = 'application/json, text/plain, */*'
            'accept-encoding' = 'gzip, deflate, br'
            'origin'          = 'https://www.tv.nu'
        }
        $allchannels = '&modules[]=pp-13&modules[]=pp-12&modules[]=ch-51&modules[]=ch-52&modules[]=pp-14&modules[]=ed-6&modules[]=pp-18&modules[]=ch-60&modules[]=ed-19&modules[]=ch-27&modules[]=pl-3&modules[]=pp-31&modules[]=ch-63&modules[]=ch-65&modules[]=pp-9&modules[]=ch-64&modules[]=ed-15&modules[]=ch-66&modules[]=pp-34&modules[]=ch-67&modules[]=pp-30&modules[]=tl-13&modules[]=ch-68&modules[]=pp-4&modules[]=ch-70&modules[]=pp-16&modules[]=ch-88&modules[]=pc-8&modules[]=ch-132&modules[]=pl-2&modules[]=ch-49&modules[]=ch-53&modules[]=pp-33&modules[]=ch-54&modules[]=pp-36&modules[]=ch-30233'
    }
    process {
        try {
            if ($Channel) {
                $ChannelLookup = Get-ChannelID
                $channelselection = "&modules[]=$($ChannelLookup[$Channel])"
            } else {
                $channelselection = $allchannels
            }
            $url = "https://web-api.tv.nu/startFeed?date=$($date)&limit=8$($channelselection)&offset=0"
            $raw = Invoke-RestMethod -UseBasicParsing -UserAgent $useragent -Headers $headers -Uri $url
            $Response = $raw.data.modules.content
            while ($null -ne $raw.data.nextoffset) {
                Write-Verbose "Paginating response, $($raw.data.nextoffset)"
                $url = "https://web-api.tv.nu/startFeed?date=$($date)&limit=12$($channelselection)&offset=$($raw.data.nextoffset)"
                $raw = Invoke-RestMethod -UserAgent $useragent -Headers $headers -Uri $url
                $Response += $raw.data.modules.content
            }
            #Write-Verbose "Response: $($Response.count)"
            foreach ($object in $Response) {
                #need to iterate over all channels and then over each broadcast.
                if ($object.Name) {
                    Write-Verbose "Channel: $($object.Name) Broadcasts: $($object.broadcasts.count)"
                    foreach ($broadcast in $object.broadcasts) {
                        if ($null -ne $broadcast.type -And $broadcast.endTime -gt [DateTimeOffset]::Now.ToUnixTimeMilliSeconds() ) {
                            #Write-Verbose $broadcast.title
                            $item = [PSCustomObject]@{
                                Channel   = $object.Name
                                Title     = $broadcast.title
                                StartFull = [System.DateTimeOffset]::FromUnixTimeMilliseconds($broadcast.startTime).LocalDateTime.ToString('yyyy-MM-dd HH:mm')
                                EndFull   = [System.DateTimeOffset]::FromUnixTimeMilliseconds($broadcast.endTime).LocalDateTime.ToString('yyyy-MM-dd HH:mm')
                                Start     = [System.DateTimeOffset]::FromUnixTimeMilliseconds($broadcast.startTime).LocalDateTime.ToString('ddd HH:mm')
                                End       = [System.DateTimeOffset]::FromUnixTimeMilliseconds($broadcast.endTime).LocalDateTime.ToString('ddd HH:mm')
                                Tags      = $broadcast.tags -join ','
                                Type      = $broadcast.type
                                Movie     = $broadcast.isMovie
                                Rating    = $broadcast.imdb.rating
                                imdb      = $broadcast.imdb.link
                            }
                            $tvschedule.add($item)
                        }
                    }
                }
            }
            Write-Verbose "Total tv broadcasts found: $($tvschedule.count)"
        } catch {
            throw $_
        }
    }
    end {
        if (-Not $Full) {
            $fields = 'Channel', 'Title', 'Start', 'End'
            $default = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$fields)
            $members = [System.Management.Automation.PSMemberInfo[]]@($default)
            $tvschedule | Add-Member MemberSet PSStandardMembers $members
        }
        # Unfortunately api does not support filter
        if ($Title) {
            $tvschedule | Where-Object -FilterScript { $_.Title -like "*$($Title)*" } | Sort-Object -Property StartFull
        } elseif ($Movies) {
            $tvschedule | Where-Object -FilterScript { $_.Movie -eq 'true' } | Sort-Object -Property StartFull
        } elseif ($Series) {
            $tvschedule | Where-Object -FilterScript { $_.Tags -like '*series*' } | Sort-Object -Property StartFull
        } else {
            $tvschedule | Sort-Object -Property StartFull
        }
    }
}
