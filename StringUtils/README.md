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
