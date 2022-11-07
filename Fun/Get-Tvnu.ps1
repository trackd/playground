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
            Today { if (-not((Get-Date) -gt (Get-Date 05:00))) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
            Tomorrow { if (-not((Get-Date) -gt (Get-Date 05:00))) { $date = (Get-Date -Format yyyy-MM-dd) } else { $date = (Get-Date).AddDays(1).ToString('yyyy-MM-dd') } }
            Default { if (-not((Get-Date) -gt (Get-Date 05:00))) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
        }
        $offset = '0'
        $limit = '8'
        [System.Collections.ArrayList]$tvschedule = @()
        #TODO: implement channel filter parameter
        # switch ($channel) {
        #     'SVT Play' { $chselect = 'pp-13' }
        #     'Netflix' { $chselect = 'pp-12' }
        #     'SVT1' { $chselect = 'ch-51' }
        #     'SVT2' { $chselect = 'ch-52' }
        #     'TV4 Play' { $chselect = 'pp-14' }
        #     'Dagens snackis' { $chselect = 'ed-6' }
        #     'Discovery+' { $chselect = 'pp-18' }
        #     'TV3' { $chselect = 'ch-60' }
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
            #untouched url
            #$url = "https://web-api.tv.nu/startFeed?date=$($date)&limit=8&modules[]=pp-13&modules[]=pp-12&modules[]=ch-51&modules[]=ch-52&modules[]=pp-14&modules[]=ed-6&modules[]=pp-18&modules[]=ch-60&modules[]=ed-19&modules[]=ch-27&modules[]=pl-3&modules[]=pp-31&modules[]=ch-63&modules[]=ch-65&modules[]=pp-9&modules[]=ch-64&modules[]=ed-15&modules[]=ch-66&modules[]=pp-34&modules[]=ch-67&modules[]=pp-30&modules[]=tl-13&modules[]=ch-68&modules[]=pp-4&modules[]=ch-70&modules[]=pp-16&modules[]=ch-88&modules[]=pc-8&modules[]=ch-132&modules[]=pl-2&modules[]=ch-49&modules[]=ch-53&modules[]=pp-33&modules[]=ch-54&modules[]=pp-36&modules[]=ch-30233&offset=0"
            #removed some streaming services
            $url = "https://web-api.tv.nu/startFeed?date=$($date)&limit=$($limit)&modules[]=ch-51&modules[]=ch-52&modules[]=pp-14&modules[]=ch-60&modules[]=ed-19&modules[]=ch-27&modules[]=pl-3&modules[]=pp-31&modules[]=ch-63&modules[]=ch-65&modules[]=pp-9&modules[]=ch-64&modules[]=ed-15&modules[]=ch-66&modules[]=pp-34&modules[]=ch-67&modules[]=pp-30&modules[]=tl-13&modules[]=ch-68&modules[]=pp-4&modules[]=ch-70&modules[]=pp-16&modules[]=ch-88&modules[]=pc-8&modules[]=ch-132&modules[]=pl-2&modules[]=ch-49&modules[]=ch-53&modules[]=pp-33&modules[]=ch-54&modules[]=pp-36&modules[]=ch-30233&offset=$($offset)"
            $raw = Invoke-RestMethod -UseBasicParsing -UserAgent $useragent -Headers $headers -Uri $url #-FollowRelLink -MaximumFollowRelLink 10
            $Response += $raw.data.modules.content
            while ($null -ne $raw.data.nextoffset) {
                $offset = $raw.data.nextoffset
                $limit = '12'
                $url = "https://web-api.tv.nu/startFeed?date=$($date)&limit=$($limit)&modules[]=ch-51&modules[]=ch-52&modules[]=pp-14&modules[]=ch-60&modules[]=ed-19&modules[]=ch-27&modules[]=pl-3&modules[]=pp-31&modules[]=ch-63&modules[]=ch-65&modules[]=pp-9&modules[]=ch-64&modules[]=ed-15&modules[]=ch-66&modules[]=pp-34&modules[]=ch-67&modules[]=pp-30&modules[]=tl-13&modules[]=ch-68&modules[]=pp-4&modules[]=ch-70&modules[]=pp-16&modules[]=ch-88&modules[]=pc-8&modules[]=ch-132&modules[]=pl-2&modules[]=ch-49&modules[]=ch-53&modules[]=pp-33&modules[]=ch-54&modules[]=pp-36&modules[]=ch-30233&offset=$($offset)"
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
                            #IMDB     = $_.broadcasts.rating.imdb.rating
                            #IMDBUrl  = $_.broadcasts.rating.imdb.link
                            Tags      = $_.tags -join ','
                            #IsPlay   = $_.isPlay
                            #RequireLogin = $_.requiresLogin
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