function Get-HelpSpotRequest {
    [CmdletBinding()]
    param(
        [int]
        $id,
        [Switch]
        $Raw
    )
    Begin {
        $newline = [System.Environment]::NewLine
    }
    Process {
        try {
            $response = Invoke-HelpspotApi -ApiEndpoint private.request.get -Params @{
                xRequest = $id
            }
            if ($Raw) {
                # this is just to debug output
                return $response
            }
            $history = $response.request_history.item.psobject.properties.value | ForEach-Object {
                $cleannotes = [System.Web.HttpUtility]::HtmlDecode($_.tNote).trim() -replace '<br>|<br/>|<br />|</p>',$newline -replace '<[^>]+>' -replace "(?m)^$newline$newline" # -replace '(?m)^\r\n'
                [PSCustomObject]@{
                    RequestHistory   = $_.xRequestHistory
                    Person           = $_.xPerson
                    GMTChange        = (Get-Date $_.dtGMTChange -Format 'yyy-MM-dd HH:mm')
                    #Public         = $_.fPublic
                    Initial          = $_.fInitial
                    #NoteIsHTML     = $_.fNoteIsHTML
                    #Log              = $_.tLog
                    Note             = $cleannotes
                    #mailHeaders    = $_.tEmailHeaders
                    Pinned           = $_.fPinned
                    external         = $_.external
                    person_type      = $_.person_type
                    files            = $_.files.file.sFilename -join ';'
                    files_urlpublic  = $_.files.file.public_url -join ';'
                    files_urlprivate = $_.files.file.private_url -join ';'
                }
            }
            $Results = [PSCustomObject]@{
                Request          = $response.xRequest
                Title            = $response.sTitle
                OpenedVia        = $response.fOpenedVia
                OpenedViaId      = $response.xOpenedViaId
                PersonOpenedBy   = $response.xPersonOpenedBy
                PersonAssignedTo = $response.xPersonAssignedTo
                Status           = $response.xStatus
                Category         = $response.xCategory
                Opened           = $response.dtGMTOpened
                Closed           = $response.dtGMTClosed
                Password         = $response.sRequestPassword
                Name             = $response.fullname
                Email            = $response.sEmail
                CostCenter       = $response.Custom4
                Custom5          = $response.custom5
                Custom6          = $response.custom6
                Custom7          = $response.custom7
                History          = $history
                #InitialCase      = $history[-1].Note
            }
        } catch {
            throw $_
        }
    }
    End {
        $Results
    }
}
