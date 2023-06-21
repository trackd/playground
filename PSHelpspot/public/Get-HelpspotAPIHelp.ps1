function Get-HelpspotAPIHelp {
    [CmdletBinding()]
    param (
        [String]
        $ApiEndpoint
    )
    process {
        if ($ApiEndpoint) {
            if ($APIEndpoint -match 'private') {
                $helpurl = "https://support.helpspot.com/index.php?pg=kb.page&id=164#$($APIEndpoint)"
            } else {
                $helpurl = "https://support.helpspot.com/index.php?pg=kb.page&id=163#$($ApiEndpoint)"
            }
            $config = $script:apidefinition[$ApiEndpoint]
            $helper = [PSCustomObject]@{
                APIEndpoint = $config.endpoint
                Method      = $config.method
                Description = $config.description
                Notes       = $config.notes
                url         = $config.URL
                HelpUrl     = $helpurl
            }
            $i = 0
            $x = 0
            foreach ($parameter in $config.param.GetEnumerator()) {
                if ($Parameter.value.Required -eq $true) {
                    $i++
                    Add-Member -InputObject $helper -MemberType NoteProperty -Name "RequiredParameter_$i" -Value $Parameter.value.Parameter
                } else {
                    $x++
                    Add-Member -InputObject $helper -MemberType NoteProperty -Name "OptionalParameter_$x" -Value $Parameter.value.Parameter
                }
            }
            $helper | Select-Object APIEndpoint, Method, Description, Notes, Url, HelpUrl, RequiredParameter*, OptionalParameter*
        }
    }
}
