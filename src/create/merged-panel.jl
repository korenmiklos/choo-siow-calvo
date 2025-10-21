using Kezdi
using CSV
using DataFrames
using Dates

# Load balance sheet data
@use "temp/balance.dta"

# Merge with CEO panel data
df_balance = getdf()
@use "temp/ceo-panel.dta", clear
df_ceo = getdf()

# Perform the merge
setdf(leftjoin(df_balance, df_ceo, on=[:frame_id_numeric, :year], makeunique=true))

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

# Filter sample
const max_ceos_per_year = 2
const max_ceo_spells = 6
const min_firm_age = 1
const excluded_sectors = [2, 9]
const min_employment = 5

# Count max CEOs per firm
@egen max_n_ceo = maximum(n_ceo), by(frame_id_numeric)

# Count CEO spells
@egen firm_year_tag = tag(frame_id_numeric, year)
@sort frame_id_numeric year

# Identify first time for each CEO-firm pair
@egen first_time = minimum(year) @if !ismissing(person_id), by(frame_id_numeric, person_id)

# Mark new CEO entries
@generate has_new_ceo = (first_time == year)
@egen has_new_ceo_fy = maximum(has_new_ceo), by(frame_id_numeric, year)

# Calculate CEO spell number (cumulative sum of new CEO indicators)
df_sorted = @with getdf() begin
    @sort frame_id_numeric year
end

# Group by frame_id_numeric and calculate cumulative sum
setdf(df_sorted)
transform!(groupby(getdf(), :frame_id_numeric), 
          :has_new_ceo_fy => cumsum => :ceo_spell)

@egen max_ceo_spell = maximum(ceo_spell), by(frame_id_numeric)
@egen max_employment = maximum(employment), by(frame_id_numeric)

# Calculate firm age
@generate firm_age = year - foundyear

# Apply filters
@drop @if ceo_spell == 0  # No CEO
@drop @if max_n_ceo > max_ceos_per_year
@drop @if max_ceo_spell > max_ceo_spells
@drop @if firm_age < min_firm_age
@drop @if sector ∈ excluded_sectors
@drop @if max_employment < min_employment

# Keep only observations with valid CEO assignments
@drop @if ismissing(person_id)

# Save the merged panel
@save "temp/merged-panel.dta", replace