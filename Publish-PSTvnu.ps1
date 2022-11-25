#cleanup temp json files.
Remove-Item .\PSTvnu\Private\*.json
Publish-Module .\PSTvnu -NuGetApiKey $env:nugetapikey