function Get-HelpspotRequestsByFilter {
    [CmdletBinding()]
    param(
        [int]
        $FilterID,
        [Switch]
        $Raw
    )
    Begin {
        $newline = [System.Environment]::NewLine
    }
    Process {
        try {
            $response = Invoke-HelpspotApi -ApiEndpoint private.filter.get -Params @{ xFilter = $FilterID }
            if ($Raw) {
                return $response
            }
            $results = foreach ($case in $response.request) {
                $cleannotes = [System.Web.HttpUtility]::HtmlDecode($case.tNote).trim() -replace '<br>|<br/>|<br />|</p>',$newline -replace '<[^>]+>' -replace "(?m)^$newline$newline"
                [PSCustomObject]@{
                    Request          = $case.xRequest
                    Title            = $case.sTitle
                    OpenedVia        = $case.fOpenedVia
                    OpenedViaId      = $case.xOpenedViaId
                    PersonOpenedBy   = $case.xPersonOpenedBy
                    PersonAssignedTo = $case.xPersonAssignedTo
                    Status           = $case.xStatus
                    Category         = $case.xCategory
                    Opened           = $case.dtGMTOpened
                    Closed           = $case.dtGMTClosed
                    Password         = $case.sRequestPassword
                    Name             = $case.fullname
                    Email            = $case.sEmail
                    CostCenter       = $case.Custom4
                    Custom5          = $case.custom5
                    Custom6          = $case.custom6
                    Custom7          = $case.custom7
                    History          = $cleannotes
                }
            }
        } catch {
            throw $_
        }
    }
    End {
        $Results
    }
}
