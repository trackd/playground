<#
script to download spot prices from vattenfall api
trackd.
https://github.com/trackd/Powershell
#>

#create archive, create folders beforehand.
$path = '<path_to>\SolarReport\spotprices'
#which regions do you want to download
$priceregions = @('SN1','SN2','SN3','SN4')
#which years
$allyears = 2020..2023
#iterate over each month.
$months = 1..12

foreach ($region in $priceregions) {
    foreach ($year in $allyears) {
        foreach ($month in $months) {
            $strmonth = '{0:0#}' -f $month #adds 0 before 1-9.
            $file = "$($path)\$($region)\$($region)_$($year)_$($strmonth).json" #string for filename
            $LastDayOfThemonth = [DateTime]::DaysInMonth($year,$strmonth) #figure out last day of the month.
            $datecheck = Get-Date "$($year)-$($strmonth)-$($LastDayOfThemonth)" #get it in [datetime]
            if ($datecheck -gt (Get-Date)) { continue } #nothing newer than today. we only want complete months.
            if (-Not (Test-Path $file)) {
                #dont download file if we already have it.
                Write-Output "Downloading $($file)" #write out that we found new file to download.
                #url format
                $url = "https://www.vattenfall.se/api/price/spot/pricearea/$($year)-$($strmonth)-01/$($year)-$($strmonth)-$($LastDayOfThemonth)/$($region)"
                #downloading from above url and saving to $file.
                Invoke-RestMethod -Uri $url -OutFile $file
                #sleep for 20sec as to not hammer the api, will only run once a month so shouldn't matter to much.
                Start-Sleep -Seconds 20
            }
        }
    }
}


