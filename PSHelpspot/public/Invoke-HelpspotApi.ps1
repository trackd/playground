function Invoke-HelpspotApi {
    <#
    .Example
    Invoke-HelpspotApi -ApiEndpoint private.filter.get -Params @{ xFilter='123' } -Debug
    .LINK
    https://support.helpspot.com/index.php?pg=kb.page&id=164
    #>
    [cmdletbinding(HelpUri = 'https://support.helpspot.com/index.php?pg=kb.page&id=164')]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ $null -ne $script:apidefinition[$_] })]
        [String]
        $ApiEndpoint,
        [Parameter()]
        [System.Collections.IDictionary]
        $Params,
        [Parameter(Mandatory)]
        [String]
        $baseUrl,
        [Parameter(Mandatory)]
        [String]
        $apikey
    )
    $headers = @{
        Authorization = "Bearer $apikey"
    }
    $config = $script:apidefinition[$ApiEndpoint]
    if ($Params) {
        $ExtraParamString = [System.Web.HttpUtility]::ParseQueryString('')
        foreach ($object in $Params.GetEnumerator()) {
            if ($config.param[$object.Name]) {
                $ExtraParamString.Add("$($object.Name)", "$($object.Value)")
                $config.param.remove[$object.Name]
            } else {
                Write-Warning "$($object.Name) is not a valid parameter for this endpoint, only: `n$($script:apidefinition[$ApiEndpoint].param.keys -join ', ')"
            }
        }
        $urlBuilder = "$($baseUrl)/api/index.php?method=$($ApiEndpoint)&$($ExtraParamString.Tostring())&output=json"
    } else {
        $urlBuilder = "$($baseUrl)/api/index.php?method=$($ApiEndpoint)&output=json"
    }
    Write-Debug "Method: $Method Url: $urlBuilder"
    try {
        $RequiredParameters = $config.param.GetEnumerator() | Where-Object { $_.Value.Required -eq $true }
        if (-Not $RequiredParameters) {
            $response = Invoke-RestMethod -Headers $headers -Uri $urlBuilder -Method $config.method
            $response
        } else {
            Write-Error "Missing Parameters $($RequiredParameters.key -join ', ') `nGet-HelpspotAPIHelp -ApiEndpoint $($ApiEndpoint)" -ErrorAction Stop
        }
    } catch {
        throw $_
    }
}
