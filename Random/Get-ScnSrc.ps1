function Get-Scnsrc {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Category
    )
    begin {
        switch ($category) {
            Movies { $url = 'https://www.scnsrc.me/category/films/feed/' ; $movies = 'yes' }
            Tv { $url = 'https://www.scnsrc.me/category/tv/feed/' ; $tv = 'yes' }
            default { $url = 'https://www.scnsrc.me/category/films/feed/' ; $movies = 'yes' }
        }
    }
    process {
        try {
            $scnsrc = [System.Collections.Generic.List[psobject]]::new()
            $raw = Invoke-WebRequest -Uri $url
            $data = ([xml]$raw.content).rss.channel.item
            $data | ForEach-Object {
                if ($movies) {
                    #playing around with regex match groups
                    $cleanMovietitle = Select-String -Pattern '(.*)(\b(19|20)\d{2}\b)' -InputObject $_.title
                }
                if ($tv) {
                    #playing around with regex match groups
                    $cleanTvtitle = Select-String -Pattern '(.*) (S)(\d{2})(E)(\d{2})' -InputObject $_.title
                    if (!$cleantvtitle) {
                        #<Title> S01 blabla
                        $cleanTvtitle = Select-String -Pattern '(.*) (S)(\d{2})' -InputObject $_.title
                    }
                }
                if ($cleanMovietitle) {
                    $object = [PSCustomObject] @{
                        Title     = $cleanMovietitle.Matches.Groups[1].Value
                        Year      = $cleanMovietitle.Matches.Groups[2].Value
                        Release   = $_.title
                        Published = (Get-Date $_.pubDate -Format 'yyyy-MM-dd MM:hh')
                        Category  = $_.category.'#cdata-section' -join ','
                    }
                }
                if ($cleanTvtitle) {
                    $object = [PSCustomObject] @{
                        Title     = $cleanTvtitle.matches.groups[1].value
                        TvEpisode = $($cleanTvtitle.matches.groups[2..5].value -join '')
                        Release   = $_.title
                        Published = (Get-Date $_.pubDate -Format 'yyyy-MM-dd MM:hh')
                        Category  = $_.category.'#cdata-section' -join ','
                    }
                }
                #discard all unformatted stuff, probably just late night tv shows..
                $scnsrc.add($object)
            }
        } catch {
            throw $_
        }
    }
    end {
        $scnsrc
    }
}
