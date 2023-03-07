
function Get-Tvshows {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $url
    )
    begin {
        switch ($url) {
            on { $url = 'http://today.on-my.tv/?xml' }
            at { $url = 'http://today.at-my.tv/?xml' }
            default { $url = 'http://today.at-my.tv/?xml' }
        }
    }
    process {
        try {
            $tvshows = [System.Collections.Generic.List[psobject]]::new()
            $raw = Invoke-WebRequest -Uri $url
            $data = ([xml]$raw.content).tvdata.episodes.entry
            $data | ForEach-Object {
                $object = [PSCustomObject] @{
                    TvShow      = $_.show_name.'#cdata-section'
                    ID          = $_.id.'#cdata-section'
                    ShowId      = $_.Show_id.'#cdata-section'
                    Season      = $_.Season.'#cdata-section'
                    Episode     = $_.Episode.'#cdata-section'
                    Date        = $_.Date.'#cdata-section'
                    EpisodeName = $_.Name.'#cdata-section'
                    Summary     = $_.episode_summary.'#cdata-section' -replace '<[^>]+>',''
                }
                if ($_.tvrage_url) {
                    $object | Add-Member -MemberType NoteProperty -Name 'TvRage' -Value $_.tvrage_url.'#cdata-section'
                }
                $tvshows.add($object)
            }
        } catch {
            throw $_
        }
    }
    end {
        $tvshows
    }
}
