Function Read-VSCodeLogs {
    <#
        .SYNOPSIS
        Reads the VSCode pwsh extension logs.
        by default it checks for errors and exceptions.
        .PARAMETER Edition
        Insiders or Stable.
        .PARAMETER FolderCount
        How many folders to check.
        each folder represents a start of vscode (i think).
        .PARAMETER Pattern
        Regex pattern to search for.
        Default is Error|Exception.
        .PARAMETER Context
        How many lines to show before and after the match.
        .PARAMETER Raw
        Just show the raw output from Select-String.
        .NOTES
        this is just meant to give you starting point if you're having issues.
        But might save you some time going through all the logs manually.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Insiders', 'Stable')]
        [String]$Edition,
        [int]$FolderCount = 10,
        [String]$Pattern = 'Error|Exception',
        [int]$Context = 1,
        [Parameter(DontShow)]
        [Switch]$Raw
    )
    # saves you from manually sanitizing the output, some people dont like showing their username.
    $sanitizeappdata = [Regex]::Escape($env:APPDATA)
    $username = [Regex]::Escape($env:USERNAME)
    if ($Edition -eq 'Insiders') {
        $LogPath = "$env:APPDATA\Code - Insiders\User\globalStorage\ms-vscode.powershell\logs\"
    }
    else {
        $LogPath = "$env:APPDATA\Code\User\globalStorage\ms-vscode.powershell\logs\"
    }
    $logfolders = Get-ChildItem -Directory $LogPath | Sort-Object -Property LastWriteTime -Descending | Select-Object -First $FolderCount
    foreach ($folder in $logfolders) {
        $logfiles = Get-ChildItem $folder.Fullname -Filter *.log
        foreach ($log in $logfiles) {
            if (-Not $Raw) {
                Select-String -Path $log.FullName -Pattern $Pattern -Context $Context | ForEach-Object {
                    [PSCustomObject]@{
                        Date        = $log.LastWriteTime
                        PreContext  = $_.context.PreContext -replace $sanitizeappdata, '~\AppData\Roaming' -replace $username, '~'
                        Error       = $_.ToString() -replace $sanitizeappdata, '~\AppData\Roaming' -replace $username, '~'
                        PostContext = $_.context.PostContext -replace $sanitizeappdata, '~\AppData\Roaming' -replace $username, '~'
                        Filename    = $Log.Name
                        Type        = $_.Matches.Value
                        Folder      = $folder.Name
                    }
                }
            }
            else {
                Select-String -Path $log.FullName -Pattern $Pattern -Context $Context
            }
        }
    }
}
