import delimited "schedule_d.csv", clear

rename *, upper
rename TAX_YEAR Tax_Year


duplicates drop EIN Tax_Year, force
drop X


* 2015
preserve
keep if Tax_Year == 2015

foreach var in CONTRIBUTIONS EARNINGS END_VALUE_BOY END_VALUE_EOY {
	rename M0_`var' `var'_2015
	rename M1_`var' `var'_2014
	rename M2_`var' `var'_2013
	rename M3_`var' `var'_2012
	rename M4_`var' `var'_2011
}

reshape long  CONTRIBUTIONS_ EARNINGS_ END_VALUE_BOY_ END_VALUE_EOY_, i(EIN) j(year)

tempfile 2015
save "2015.dta", replace
restore



* 2016
preserve
keep if Tax_Year == 2016

foreach var in CONTRIBUTIONS EARNINGS END_VALUE_BOY END_VALUE_EOY {
	rename M0_`var' `var'_2016
	rename M1_`var' `var'_2015
	rename M2_`var' `var'_2014
	rename M3_`var' `var'_2013
	rename M4_`var' `var'_2012
}

reshape long  CONTRIBUTIONS_ EARNINGS_ END_VALUE_BOY_ END_VALUE_EOY_, i(EIN) j(year)
tempfile 2016
save `2016'
restore

* 2017

preserve
keep if Tax_Year == 2017
foreach var in CONTRIBUTIONS EARNINGS END_VALUE_BOY END_VALUE_EOY {
	rename M0_`var' `var'_2017
	rename M1_`var' `var'_2016
	rename M2_`var' `var'_2015
	rename M3_`var' `var'_2014
	rename M4_`var' `var'_2013
}

reshape long  CONTRIBUTIONS_ EARNINGS_ END_VALUE_BOY_ END_VALUE_EOY_, i(EIN) j(year)
gsort EARNINGS_
tempfile 2017
save `2017'
restore




* 2018
preserve
keep if Tax_Year == 2018

foreach var in CONTRIBUTIONS EARNINGS END_VALUE_BOY END_VALUE_EOY {
	rename M0_`var' `var'_2018
	rename M1_`var' `var'_2017
	rename M2_`var' `var'_2016
	rename M3_`var' `var'_2015
	rename M4_`var' `var'_2014
}

reshape long  CONTRIBUTIONS_ EARNINGS_ END_VALUE_BOY_ END_VALUE_EOY_, i(EIN) j(year)

tempfile 2018
save `2018'
restore


* 2019
preserve
keep if Tax_Year == 2019

foreach var in CONTRIBUTIONS EARNINGS END_VALUE_BOY END_VALUE_EOY {
	rename M0_`var' `var'_2019
	rename M1_`var' `var'_2018
	rename M2_`var' `var'_2017
	rename M3_`var' `var'_2016
	rename M4_`var' `var'_2015
}

reshape long  CONTRIBUTIONS_ EARNINGS_ END_VALUE_BOY_ END_VALUE_EOY_, i(EIN) j(year)

tempfile 2019
save `2019'
restore


* 2020
preserve
keep if Tax_Year == 2020

foreach var in CONTRIBUTIONS EARNINGS END_VALUE_BOY END_VALUE_EOY {
	rename M0_`var' `var'_2020
	rename M1_`var' `var'_2019
	rename M2_`var' `var'_2018
	rename M3_`var' `var'_2017
	rename M4_`var' `var'_2016
}

reshape long  CONTRIBUTIONS_ EARNINGS_ END_VALUE_BOY_ END_VALUE_EOY_, i(EIN) j(year)

tempfile 2020
save `2020'
restore



* 2021
preserve
keep if Tax_Year == 2021

foreach var in CONTRIBUTIONS EARNINGS END_VALUE_BOY END_VALUE_EOY {
	rename M0_`var' `var'_2021
	rename M1_`var' `var'_2020
	rename M2_`var' `var'_2019
	rename M3_`var' `var'_2018
	rename M4_`var' `var'_2017
}

reshape long  CONTRIBUTIONS_ EARNINGS_ END_VALUE_BOY_ END_VALUE_EOY_, i(EIN) j(year)

tempfile 2021
save `2021'
restore




* 2022
preserve
keep if Tax_Year == 2022

foreach var in CONTRIBUTIONS EARNINGS END_VALUE_BOY END_VALUE_EOY {
	rename M0_`var' `var'_2022
	rename M1_`var' `var'_2021
	rename M2_`var' `var'_2020
	rename M3_`var' `var'_2019
	rename M4_`var' `var'_2018
}

reshape long  CONTRIBUTIONS_ EARNINGS_ END_VALUE_BOY_ END_VALUE_EOY_, i(EIN) j(year)

tempfile 2022
save `2022'
restore

use "2015.dta", clear
append using `2016'
append using `2017'
append using `2018'
append using `2019'
append using `2020'
append using `2021'
append using `2022'
rename Tax_Year Reported_Year
rename year Tax_Yearh

duplicates report EIN Tax_Year

* take the endowment data that is in the most recent filing year
bysort EIN Tax_Year: egen max_year = max(Reported_Year)
bysort EIN Tax_Year: keep if Reported_Year == max_year

duplicates report EIN Tax_Year


foreach var in CONTRIBUTIONS EARNINGS END_VALUE_BOY END_VALUE_EOY PERC_PERM PERC_BOARD UNRELATED RELATED {
	replace `var'_ = "0" if `var'_ == "NA" | `var'_ == "FALSE"
	replace `var'_ = "1" if `var'_ == "TRUE"
	destring `var', replace
}

levelsof PERC_PERM
* check if they all add up to 1
gen PERC_TERM = 1 - PERC_BOARD - PERC_PERM

