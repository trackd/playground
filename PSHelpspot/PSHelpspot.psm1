$public = @( Get-ChildItem -Path $PSScriptRoot\public\*.ps1 )
$private = @( Get-ChildItem -Path $PSScriptRoot\private\*.ps1 )

Foreach ($file in @($public + $private)) {
    Try {
        . $file.fullname
    } Catch {
        throw $_
    }
}
Set-HelpspotEndpointhelper
