<#
just a little experiment with runes and strings
#>

. $PSScriptRoot\Public\Invoke-TrimRunes.ps1
. $PSScriptRoot\Public\Invoke-TrimRunesRange.ps1
. $PSScriptRoot\Public\Invoke-TrimCharClass.ps1
. $PSScriptRoot\Public\Invoke-TrimRunesWithCategories.ps1
. $PSScriptRoot\Public\Invoke-TrimRuneClass.ps1
. $PSScriptRoot\Public\Remove-Whitespace.ps1

. $PSScriptRoot\Public\RuneInfo.ps1
Export-ModuleMember -Function *
