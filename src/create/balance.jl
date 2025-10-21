using Kezdi

# Load balance sheet data
@use "input/merleg-LTS-2023/balance/balance_sheet_80_22.dta"

# Filter by year range
@keep @if year >= 1992 && year <= 2022
@drop @if frame_id == "only_originalid"

# Generate numeric frame ID from string ID
@generate frame_id_numeric = parse(Int64, frame_id[3:end]) @if startswith(frame_id, "ft")

# Keep relevant dimensions and facts
@keep frame_id_numeric originalid foundyear year teaor08_2d teaor08_1d sales export emp tanass ranyag wbill persexp immat so3_with_mo3 fo3

# Rename variables to match expected names
@rename emp employment
@rename tanass tangible_assets
@rename ranyag materials
@rename wbill wagebill
@rename persexp personnel_expenses
@rename immat intangible_assets
@rename so3_with_mo3 state_owned
@rename fo3 foreign_owned

# Replace missing values with 0 for numeric variables
@mvencode sales export employment tangible_assets materials wagebill personnel_expenses intangible_assets state_owned foreign_owned, mv(0)

# Apply minimum employment threshold
@replace employment = 1 @if employment < 1
@replace employment = floor(Int, employment)

# Apply industry classification
@generate sector = missing
@replace sector = 1 @if teaor08_1d == "A"  # Agriculture
@replace sector = 2 @if teaor08_1d == "B"  # Mining
@replace sector = 3 @if teaor08_1d == "C"  # Manufacturing  
@replace sector = 4 @if teaor08_1d ∈ ["G", "H"]  # Wholesale, Retail, Transportation
@replace sector = 5 @if teaor08_1d ∈ ["J", "M"]  # Telecom and Business Services
@replace sector = 9 @if teaor08_1d == "K"  # Finance
@replace sector = 6 @if teaor08_1d == "F"  # Construction
@replace sector = 7 @if ismissing(sector)  # Nontradable services

# Make sector constant within firm (use mode)
df_temp = @with getdf() begin
    @collapse sector_mode = mode(sector), by(frame_id_numeric)
end
setdf(leftjoin(getdf(), df_temp, on=:frame_id_numeric))
@replace sector = sector_mode
@drop sector_mode

# Generate key variables
# Value added approximation
@generate value_added = sales - personnel_expenses - materials

# Log transformations
@generate lnR = log(sales)
@generate lnY = log(value_added) 
@generate lnL = log(employment)

@save "temp/balance.dta", replace
