clear all
use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "lib/create/network-sample.do"

tabulate year giant_component
tabulate year connected_components