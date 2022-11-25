#cleanup temp json files.
$ModulePath = "$PSScriptRoot\PSTvnu"
Remove-Item $ModulePath\Private\*.json
Publish-Module -Path $ModulePath -NuGetApiKey $env:nugetapikey