/*==================================================
project:       GIC with longest period for each comparable spell
Author:        R.Andres Castaneda & Christoph Lakner
E-email:       acastanedaa@worldbank.org
url:           
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    16 Oct 2019 - 20:49:38
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
0: Program set up
==================================================*/
version 14
drop _all


cap findfile scheme-plotplainblind.scheme
if (_rc) ssc install blindschemes

set scheme plotplainblind

//========================================================
//  User inputs
//========================================================

local country_list "ARG THA GHA"  // change this
local year_range "1990/2016"      // change this as a numlist (help nlist)


/*==================================================
1:  Load data and merge with metadata
==================================================*/

*----------1.1:
local rawcontent "https://raw.githubusercontent.com/"
local metadata "`rawcontent'worldbank/povcalnet/master/metadata/povcalnet_metadata.dta"
povcalnet, clear
merge 1:1 countrycode year coveragetype datatype using "`metadata'"


*----------1.2: keep relevant observations

* countries
local country_list: subinstr local country_list " " "|", all // do NOT change this
keep if regexm(countrycode, "`country_list'")

* Years
numlist "`year_range'"
local year_range = "`r(numlist)'"
local year_range: subinstr local year_range " " "|", all // do NOT change this
keep if regexm(strofreal(year), "`year_range'")

label var year "Year"
//------------find longest spell 

cap drop spell
gen spell = .

levelsof countrycode, local(countries)
levelsof comparability, local(breaks)

qui foreach country of local countries {
	
	foreach break of local breaks {
		
		local c_cb `" countrycode == "`country'" & comparability == `break' "' // condition country and break
		count if (`c_cb')
		if (r(N) == 0) continue  // skip if combination does not exist
		
		// Legend
		sum year if (`c_cb'), meanonly
		replace spell =  r(max) - r(min)  if (`c_cb')
		
	}
}

bysort countrycode: egen mcom = max(spell)               // max count of comparability
keep if spell == mcom   // keep longest spell

/*==================================================
2: calculate GIC
==================================================*/

*----------2.1: reshape and format
reshape long decile, i(countrycode year) j(dec)
egen panelid=group(countrycode dec)
xtset panelid year

replace dec=10*dec
replace decile=10*decile*mean

*----------2.2: create GIC
levelsof countrycode, local(countries)
gen g = .
foreach country of local countries {
	local condif `"countrycode == "`country'""'
	sum spell if `condif', meanonly
	local sp = r(min)
	replace g =(((decile/L`sp'.decile)^(1/`sp'))-1)*100	 if `condif'
}

/*==================================================
3:  Chart
==================================================*/


*##s
*----------3.1: parametter
local colors "sky turquoise reddish vermillion sea orangebrown" // help plotplainblind
local pattern "solid" // help linepatternstyle
local symbol "O"  // help symbolstyle

*----------3.2:
levelsof countrycode, local(countries)

local c = 0
global gic_lines ""
global glegend ""
foreach country of local countries {
	local ++c
	local color: word `c' of `colors'
	
	local condif `"countrycode == "`country'""'
	
	// line
	local gline (sc g dec if (`condif'), c(l) lpattern(`pattern') /* 
	 */ lcolor(`color') mcolor(`color')  msymbol(`symbol'))
	global gic_lines "${gic_lines} `gline'"
	
	// Legend
	levelsof countryname if (`condif'), local(countryname) clean
	
	sum year if (`condif'), meanonly
	local min = r(min)
	local max = r(max)
	global glegend = `" ${glegend} `c' "`countryname' (`min'-`max')" "'
	
}



*----------3.3: Plot


twoway ${gic_lines}, legend(order(${glegend}) rows(1) pos(6)) /* 
 */ ytitle("Annual growth in decile average income (%)",  size(small))  /* 
 */	xtitle("Decile group",  size(small))

*##e



exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:

