<#
i dont really know why i made this thing..
mostly for fun and cause i wanted to see the visuals compared of the original string and the result.

performance test

appearently this is a thing
'🤷‍♂️' -eq '🤷♂️'
True
(I do know why, but its still funny)

should run the test once before upping the testruns just to let the dotnet classes load
otherwise it skews the results a bit.
normally first run for them are in 150ms range and then they drop to 2-3ms

ps. i dont recommend running this on ps 5.1.

#>
<#
with 2000 iterations.
ie, 2000 of each test both Input and Pipeline.

all time is in milliseconds
> PS 7.4.0-preview.5
Command                            Time
-------                            ----
Invoke-TrimCharClass            2865,99
Invoke-TrimRuneClass            3149,11
Remove-Whitespace               3680,94
Invoke-TrimRunesRange          15276,63
Invoke-TrimRunesWithCategories 24484,27
Invoke-TrimRunes               28353,70

> PS 7.3.6
Command                            Time
-------                            ----
Invoke-TrimCharClass            3423,97
Invoke-TrimRuneClass            4038,76
Remove-Whitespace               5349,17
Invoke-TrimRunesRange          16476,13
Invoke-TrimRunesWithCategories 27051,54
Invoke-TrimRunes               29565,24
#>

Import-Module -Name $PSScriptRoot/../StringUtils.psm1 -Force
$testruns = 500



$sampledata = [Ordered]@{
    Test01 = @{
        Input    = "String: '\t\t' `t`tTabs🤷‍♂️"
        Expected = "String: '\t\t' Tabs🤷‍♂️"
    }
    Test02 = @{
        Input    = "String: '\n\n' `n`nNewlines"
        Expected = "String: '\n\n' Newlines"
    }
    Test03 = @{
        Input    = "String: '\r\r' `r`rCarriage Returns"
        Expected = "String: '\r\r' Carriage Returns"
    }
    Test04 = @{
        Input    = "String: '\v\v' `v`vVertical Tabs"
        Expected = "String: '\v\v' Vertical Tabs"
    }
    Test05 = @{
        Input    = "String: '\f\f' `f`fForm Feeds"
        Expected = "String: '\f\f' Form Feeds"
    }
    Test06 = @{
        Input    = "String: '\b\b' `b`bBackspaces"
        Expected = "String: '\b\b' Backspaces"
    }
    Test07 = @{
        Input    = "String: '\0\0' `0`0Null Characters"
        Expected = "String: '\0\0' Null Characters"
    }
    Test08 = @{
        Input    = "String: '\a\a' `a`aAlerts"
        Expected = "String: '\a\a' Alerts"
    }
    Test09 = @{
        Input    = "String: '\e\e' `e`eEscapes"
        Expected = "String: '\e\e' Escapes"
    }
    Test10 = @{
        Input    = "String: '\r\n' `r`nNewline Carriage Return"
        Expected = "String: '\r\n' Newline Carriage Return"
    }
    Test11 = @{
        Input    = "Some '\r\n'`r`n😍🙌 with an '\e'`e escape "
        Expected = "Some '\r\n'😍🙌 with an '\e' escape"
    }
    Test12 = @{
        Input    = '😁 just a happy emoji'
        Expected = '😁 just a happy emoji'
    }
    Test13 = @{
        Input    = "double quote "" and single quote '"
        Expected = "double quote "" and single quote '"
    }
    Test14 = @{
        Input    = "`n`n newlines for the win`t and tabs"
        Expected = "newlines for the win and tabs"
    }
    Test15 = @{
        Input    = '123'
        Expected = '123'
    }
    Test16 = @{
        Input    = "string has a null character$null"
        Expected = 'string has a null character'
    }
    Test17 = @{
        Input    = '`n`n literal string'
        Expected = '`n`n literal string'
    }
    Test18 = @{
        Input    = [string]@(1, 2, 3)
        Expected = '1 2 3'
    }
    Test19 = @{
        Input    = '1       5'
        Expected = '1       5'
    }
    Test20 = @{
        Input    = "😁🤷‍♂️🙌❤️🤣🤞✌️🤷‍♀️🤦‍♂️🤦‍♀️"
        Expected = '😁🤷‍♂️🙌❤️🤣🤞✌️🤷‍♀️🤦‍♂️🤦‍♀️'
    }
    Test21 = @{
        Input    = "😎🎶😢😜🧍‍♂️🏃‍♂️🏃‍♀️🧎‍♂️👨‍🦼👩‍🦼🤚🤜"
        Expected = '😎🎶😢😜🧍‍♂️🏃‍♂️🏃‍♀️🧎‍♂️👨‍🦼👩‍🦼🤚🤜'
    }
    Test22 = @{
        Input    = @("String1 `n1", "String2 `n2", "String3 `n2")
        Expected = @("String1 1", "String2 2", "String3 2")
    }
}

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $commands = Get-Command -Module StringUtils | Where-Object { $_.Name -like 'Invoke-*' -Or $_.Name -like 'Remove-*' }
}
else {
    # PS 5.1 Doesn't support .EnumerateRunes() so we have to limit the tests to commands that dont use it.
    $commands = Get-Command -Module StringUtils -Name Remove-Whitespace,Invoke-TrimCharClass
}
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$timearray = [System.Collections.Generic.List[psobject]]::new()
$timerinput = [System.Diagnostics.Stopwatch]::StartNew()
$timerpipeline = [System.Diagnostics.Stopwatch]::StartNew()
$f = "$($PSStyle.Background.red)False$($PSStyle.Reset)"
$t = "$($PSStyle.Background.green)True $($PSStyle.Reset)"
$r = foreach ($c in $commands) {
    $stopwatch.Restart()
    $sampledata.keys | ForEach-Object {
        $curr = $sampledata[$_]
        $timerinput.restart()
        1..$testruns | ForEach-Object { $testin = & $c $($curr.Input) }
        #this is just super duper stupid, but fun.
        $runtimeinput = $timerinput.elapsed.TotalMilliseconds
        $timerpipeline.restart()
        1..$testruns | ForEach-Object { $testpipe = $Curr.Input | & $c }
        $runtimepipeline = $timerpipeline.Elapsed.TotalMilliseconds
        if ($curr.Expected -is [String]) {
            if ($curr.Expected -ceq $testin) {
                $in = $t
            }
            else {
                $in = $f
            }
            if ($curr.Expected -ceq $testpipe) {
                $pipe = $t
            }
            else {
                $pipe = $f
            }
        }
        elseif ($Curr.Expected -is [array]) {
            #compare the last object in the array
            if ($curr.Expected[-1] -ceq $testin[-1]) {
                $in = $t
            }
            else {
                $in = $f
            }
            # compare the first object in the array
            if ($curr.Expected[0] -ceq $testpipe[0]) {
                $pipe = $t
            }
            else {
                $pipe = $f
            }
        }
        [PSCustomObject]@{
            Function   = $c
            Test       = $_
            PipeTest   = $pipe
            InputTest  = $in
            InputTime  = $runtimeinput
            PipeTime   = $runtimepipeline
            Input      = $curr.Input
            Expected   = $curr.Expected
            ResultIn   = $testin
            ResultPipe = $testpipe
        }
    }
    $timearray.add([PSCustomObject]@{
            Command = $c.Name
            Time    = $stopwatch.Elapsed.TotalMilliseconds
        })
}
$good = $r | Where-Object { $_.PipeTest -eq $t -or $_.InputTest -eq $t }
$bad = $r | Where-Object { $_.PipeTest -eq $f -or $_.InputTest -eq $f }

# $r | Select-Object -ExcludeProperty Input, ResultPipe | Sort-Object -Property Test,Function | Format-Table
$r | Select-Object -ExcludeProperty Input*,ResultIn | Sort-Object -Property Test,Pipetime | Format-Table
Write-Host `n
$r | Select-Object -ExcludeProperty Pipe*,Input, ResultPipe | Sort-Object -Property Test,InputTime | Format-Table
$timearray | Sort-Object -Property Time | Format-Table
Write-Host "TestIterations: $testruns"
Write-Host "Tested $($commands.count) commands against $($r.count * 2) tests"
Write-Host "Passed: $($good.count * 2)"
Write-Host "Failed: $($bad.count * 2)"
$r | Where-Object { $_.PipeTest -eq $f -or $_.InputTest -eq $f }
# $r
