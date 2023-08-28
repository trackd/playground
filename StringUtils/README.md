playing around with Character codes and System.Text.Rune  

goal was to Trim a string(s) of all weird characters but preserving spaces..  

Like Whitespace and ControlCodes.  

mostly just for fun and to learn a bit more about Unicode/Runes  

string.tests.ps1 is a pester test with some sample data  

stringtests.ps1 is a quick and dirty visual test where you can see the strings input/expectation and what the function returned.  

note:

Windows Powershell (v5.1) support is pretty spotty.  
only Remove-Whitespace, Invoke-TrimCharClass are semi-functional.  
But it cannot clean all sample data.  
specifically both seem to fail on Test06, Test08, Test09, Test11  

Seem to be control codes: backspace, escape, alert.  

Not sure why that happens..  

The others require PS7 (because they rely on .EnumerateRunes())  

```ps1
.\tests\speed_stringtest.ps1
Testruns: 500  
Tested 6 commands against 264 tests  
Passed: 264  
Failed: 0  
```

|Command|Time|
|-------|----|
|Invoke-TrimCharClass|956,38|
|Invoke-TrimRuneClass|996,66|
|Remove-Whitespace|1099,92|
|Invoke-TrimRunesRange|4107,05|
|Invoke-TrimRunesWithCategories|6426,21|
|Invoke-TrimRunes|7395,23|

theres also a pester test in  
.\tests\string.tests.ps1  
but its not nearly as visually fun to look at  
