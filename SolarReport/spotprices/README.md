### Spotprice from Swedish marketplace nordpool.

Easiest way to work with these is with a hashtable.

example:
~~~
PS> $ImportJson = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/trackd/Powershell/master/SolarReport/spotprices/SN1/SN1_2020_11.json'
PS> $pricehashtable = $ImportJson | Group-Object -Property TimeStamp -AsHashTable -AsString

PS> $pricehashtable['2020-11-28 13:00:00']

TimeStamp     : 2020-11-28 13:00:00
TimeStampDay  : 2020-11-28
TimeStampHour : 13:00
Value         : 17,41
PriceArea     : SN1
Unit          : öre/kWh
~~~

if you want to load multiple files, download them and work locally like this.
~~~
#path to files, SN4_202* will only match files from 2020 and forward.
$spotprice = Get-ChildItem "SolarReport\spotprices\SN4\SN4_202*"

#loop through each file from $spotprice results and convert them and saves it to an array ($loadspot)
$loadspot = foreach ($file in $spotprice) {
    Get-Content -Raw -Path $file.FullName | ConvertFrom-Json
}
#create hashtable for easy lookups
$pricehashtable = $loadspot | Sort-Object -Property Timestamp -Unique | Group-Object -Property TimeStamp -AsHashTable -AsString
~~~

To directly access the price value you can
~~~
PS> $pricehash['2020-11-28 13:00:00'].value
17,41