function Get-MSEOL {
    <#
    .DESCRIPTION
    Get End of life data from ADObject versionumber.
    .EXAMPLE
    Get-AdComputer -identity myserver -Properties -Properties OperatingSystemversion,OperatingSystem | Get-MSEOL
    Get-MSEOL -Version 12345 -Type Client
    $servers = Get-AdComputer -Filter "OperatingSystem -Like '*Windows Server*' -and Enabled -eq 'True'" -Properties OperatingSystemversion,OperatingSystem
    $eol = $servers | Get-MSEOL
    but probably makes most sense in a ad inventory script where you just add this in the foreach.
    $eol = ($_ | Get-MSEOL).eol
    .NOTES
    will only run begin {} once per pipeline so should only run against one OS type (cliient or server)
    type param client should probably be rewritten a bit.. as long as it doesnt match Server its a client.
    .PARAMETER Version
    takes OperatingSystemversion from adobject as param or normal stringvalue
    .PARAMETER Type
    takes OperatingSystem from adobject as param
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('OperatingSystemversion')]
        [String]
        $Version,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('OperatingSystem')]
        [String]
        $Type
    )
    begin {
        if ($type -match 'Server') {
            Write-Debug 'working with servers'
            $EOL = Invoke-RestMethod -Uri 'https://endoflife.date/api/windowsserver.json'
        } elseif ($type -notmatch 'Server') {
            Write-Debug 'working with clients'
            $EOL = Invoke-RestMethod -Uri 'https://endoflife.date/api/windows.json'
        }
        Write-Debug "loaded $($EOL.count) from json"
        #clean up operatingsystemversion field
        $filterversion = '®|\)| |'
    }
    process {
        #clean up operatingsystemversion, add a . instead of (
        $object = $version -replace $filterversion -replace '\(','.'
        #check for matches in $eol array.
        $check = $eol | Where-Object -FilterScript { $_.latest -eq $object }
        #if we returned more than 1 object its probably an lts release. select last entry.
        if ($check.count -gt 1) {
            Write-Debug "$($check.count) matching version: $($check.latest | Sort-Object -Unique) most likely LTS release. selecting last entry."
            $check | Select-Object -Last 1 #-ExpandProperty EOL
        } else {
            $check #| Select-Object -ExpandProperty EOL
        }
    }
}