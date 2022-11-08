function Get-Tvnu {
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

    .EXAMPLE
    If you want to filter on channel the easiest way is
    Get-Tvnu | Where -Property Channel -EQ 'SVT1'
    Get-Tvnu | Where -FilterScript {$_.Channel -eq 'SVT1'}

    .LINK
    credit www.tv.nu
#>
    [CmdletBinding()]
    param(
        [ValidateSet('Today', 'Tomorrow')]
        [string] $Day,
        [Switch] $Full
    )
    begin {
        switch ($Day) {
            Today { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
            Tomorrow { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).ToString('yyyy-MM-dd') } else { $date = (Get-Date).AddDays(1).ToString('yyyy-MM-dd') } }
            Default { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
        }
        [System.Collections.ArrayList]$tvschedule = @()
        #TODO: implement channel filter parameter
        # $allchannels = Invoke-RestMethod -Uri https://web-api.tv.nu/packages/allChannels
        # $allchannels.data | ForEach-Object { Write-Host $_.id $_.Name }
        # switch ($channel) {
        #     'SVT Play' { $chselect = 'pp-13' }
        #     'Netflix' { $chselect = 'pp-12' }
        #     'SVT1' { $chselect = 'ch-51' }
        #     'SVT2' { $chselect = 'ch-52' }
        #     'TV4 Play' { $chselect = 'pp-14' }
        #     'Dagens snackis' { $chselect = 'ed-6' }
        #     'Discovery+' { $chselect = 'pp-18' }
        #     'TV3' { $chselect = 'ch-60' }
        #     'Få nyhetsbrev från tv.nu' { $chselect = 'ed-19' }
        #     'TV4' { $chselect = 'ch-27' }
        #     'Gratis filmer att streama' { $chselect = 'pl-3' }
        #     'Tele2 Play' { $chselect = 'pp-31' }
        #     'Kanal 5' { $chselect = 'ch-63' }
        #     'TV6' { $chselect = 'ch-65' }
        #     'Viaplay' { $chselect = 'pp-9' }
        #     'Sjuan' { $chselect = 'ch-64' }
        #     'Tips från redaktionen' { $chselect = 'ed-15' }
        #     'TV8' { $chselect = 'ch-66' }
        #     'Kanal 9' { $chselect = 'ch-67' }
        #     'Disney+' { $chselect = 'pp-30' }
        #     'Nya trailers' { $chselect = 'tl-13' }
        #     'TV10' { $chselect = 'ch-68' }
        #     'C More' { $chselect = 'pp-4' }
        #     'Kanal 11' { $chselect = 'ch-70' }
        #     'HBO Max' { $chselect = 'pp-16' }
        #     'TV12' { $chselect = 'ch-88' }
        #     'Premiärer' { $chselect = 'pc-8' }
        #     'Eurosport 1' { $chselect = 'ch-132' }
        #     'Nya filmer på streaming' { $chselect = 'pl-2' }
        #     'Kunskapskanalen' { $chselect = 'ch-49' }
        #     'SVT24' { $chselect = 'ch-53' }
        #     'TriArtPlay' { $chselect = 'pp-33' }
        #     'SVT Barn' { $chselect = 'ch-54' }
        #     'Cineasterna' { $chselect = 'pp-36' }
        #     'Godare' { $chselect = 'ch-30233' }
        # }
    }
    process {
        try {
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
            $url = "https://web-api.tv.nu/startFeed?date=$($date)&limit=8&modules[]=pp-13&modules[]=pp-12&modules[]=ch-51&modules[]=ch-52&modules[]=pp-14&modules[]=ed-6&modules[]=pp-18&modules[]=ch-60&modules[]=ed-19&modules[]=ch-27&modules[]=pl-3&modules[]=pp-31&modules[]=ch-63&modules[]=ch-65&modules[]=pp-9&modules[]=ch-64&modules[]=ed-15&modules[]=ch-66&modules[]=pp-34&modules[]=ch-67&modules[]=pp-30&modules[]=tl-13&modules[]=ch-68&modules[]=pp-4&modules[]=ch-70&modules[]=pp-16&modules[]=ch-88&modules[]=pc-8&modules[]=ch-132&modules[]=pl-2&modules[]=ch-49&modules[]=ch-53&modules[]=pp-33&modules[]=ch-54&modules[]=pp-36&modules[]=ch-30233&offset=0"
            $raw = Invoke-RestMethod -UseBasicParsing -UserAgent $useragent -Headers $headers -Uri $url
            $Response += $raw.data.modules.content
            while ($null -ne $raw.data.nextoffset) {
                $url = "https://web-api.tv.nu/startFeed?date=$($date)&limit=12&modules[]=pp-13&modules[]=pp-12&modules[]=ch-51&modules[]=ch-52&modules[]=pp-14&modules[]=ed-6&modules[]=pp-18&modules[]=ch-60&modules[]=ed-19&modules[]=ch-27&modules[]=pl-3&modules[]=pp-31&modules[]=ch-63&modules[]=ch-65&modules[]=pp-9&modules[]=ch-64&modules[]=ed-15&modules[]=ch-66&modules[]=pp-34&modules[]=ch-67&modules[]=pp-30&modules[]=tl-13&modules[]=ch-68&modules[]=pp-4&modules[]=ch-70&modules[]=pp-16&modules[]=ch-88&modules[]=pc-8&modules[]=ch-132&modules[]=pl-2&modules[]=ch-49&modules[]=ch-53&modules[]=pp-33&modules[]=ch-54&modules[]=pp-36&modules[]=ch-30233&offset=$($raw.data.nextoffset)"
                $raw = Invoke-RestMethod -UseBasicParsing -UserAgent $useragent -Headers $headers -Uri $url
                $Response += $raw.data.modules.content
            }
            $Response | ForEach-Object {
                $chan = $_.name
                $_.broadcasts | ForEach-Object {
                    if ($_.isPlay -ne 'true' -And $null -ne $_.type -And $_.endTime -gt [DateTimeOffset]::Now.ToUnixTimeMilliSeconds() ) {
                        $object = [pscustomobject]@{
                            Channel   = $chan
                            Showing   = $_.title
                            StartFull = [System.DateTimeOffset]::FromUnixTimeMilliseconds($_.startTime).LocalDateTime.ToString('yyyy-MM-dd HH:mm')
                            EndFull   = [System.DateTimeOffset]::FromUnixTimeMilliseconds($_.endTime).LocalDateTime.ToString('yyyy-MM-dd HH:mm')
                            Start     = [System.DateTimeOffset]::FromUnixTimeMilliseconds($_.startTime).LocalDateTime.ToString('ddd HH:mm')
                            End       = [System.DateTimeOffset]::FromUnixTimeMilliseconds($_.endTime).LocalDateTime.ToString('ddd HH:mm')
                            Tags      = $_.tags -join ','
                            Type      = $_.type
                        }
                        $tvschedule.add($object) | Out-Null
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
            $fields = 'Channel', 'Showing', 'Start', 'End'
            $default = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$fields)
            $members = [System.Management.Automation.PSMemberInfo[]]@($default)
            $tvschedule | Add-Member MemberSet PSStandardMembers $members
        }
        $tvschedule | Sort-Object -Property StartFull
    }
}