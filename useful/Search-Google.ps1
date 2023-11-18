#Import-Module PSParseHtml

function Search-Google {
    <#
    .SYNOPSIS
        Search Google and return the first result(s)
    .PARAMETER Query
        The search query
    .PARAMETER MaxResults
        The maximum number of results to return
    .PARAMETER Open
        Open the result(s) in the default browser
    .EXAMPLE
        Search-Google -Query "PowerShell"
    .EXAMPLE
        Search-Google -Query "PowerShell" -MaxResults 5
    .EXAMPLE
        Search-Google -Query "PowerShell" -Open
    .NOTES
    based on ninmonkeys work
    https://github.com/ninmonkey/notebooks/blob/c8791e91328a6bcea6b58f735badd838b5306676/Pwsh/Web/ParsingDom/ParsingDom%20%E2%81%9E%20Pwsh%20with%20PSParseHtml%20%E2%81%9E%20XPath%20Query%20Selectors.ps1

    #>
    [cmdletbinding()]
    [Alias('Google')]
    param(
        [Parameter(Mandatory)]
        [String]
        $Query,
        [ValidateRange(1, 10)]
        [Alias('Results')]
        [int]
        $MaxResults = 1,
        [Switch]
        $Open,
        [ValidateLength(2, 3)]
        [String]
        $Language = (Get-Culture).TwoLetterISOLanguageName
    )
    # just to avoid conflicting with PowerHTML which has a function with the same name. but differ on param -URI vs -URL.
    if (-Not (Get-Module PSParseHTML)) { Import-Module PSParseHTML }
    # sometimes you get sent to a google help page about search language unless you specify the language.
    $urlbuilder = "https://www.google.com/search?&q=" + [System.Web.HttpUtility]::UrlEncode($Query) + "&hl=$language"
    # seems specifying lang. doesnt always fix it... below also show up for some queries.
    $filter = @(
        [regex]::Escape('https://support.google.com/')
        [regex]::Escape('https://accounts.google.com/')
        [regex]::Escape('https://policies.google.com/')
    ) -join '|'
    $response = ConvertFrom-Html -URI $urlbuilder -Engine AgilityPack
    $hrefs = $response.SelectNodes('//a')
    Write-Debug $hrefs.count
    $i = 0
    $Count = $MaxResults # to avoid the ValidateRange stuff on $MaxResults.
    $searchresults = while ($i -lt $hrefs.Count -and $Count -gt 0) {
        Write-Debug "iteration: $i need: $Count"
        [uri]$url = $hrefs[$i].Attributes["href"].Value
        if ($url.IsAbsoluteUri -and $url.AbsoluteUri -notmatch $filter) {
            $url.AbsoluteUri
            $Count--
        }
        $i++
    }
    if ($Open) {
        # assuming you would only want to open 1 page..
        Start-Process $searchresults[0]
    }
    else {
        $searchresults
    }
}
