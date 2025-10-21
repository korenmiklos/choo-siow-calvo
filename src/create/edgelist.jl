using Kezdi
using CSV
using DataFrames

# Load the merged panel data
@use "temp/merged-panel.dta"

# Calculate spell length for each person-firm pair
# First, calculate the tenure for each observation
@sort frame_id_numeric person_id year
@egen spell_start = minimum(year), by(frame_id_numeric, person_id)
@egen spell_end = maximum(year), by(frame_id_numeric, person_id)
@generate T = spell_end - spell_start + 1

# Create unique person-firm pairs with their characteristics
# Keep one observation per person-firm pair with averages
@collapse T = mean(T) lnR = mean(lnR) lnY = mean(lnY) lnL = mean(lnL), by(frame_id_numeric, person_id)

# Drop any observations with missing values in key variables
@drop @if ismissing(lnR) || ismissing(lnY) || ismissing(lnL)

# Select and order the columns for the edgelist
@keep frame_id_numeric person_id T lnR lnY lnL

# Export to CSV
df_final = getdf()
CSV.write("temp/edgelist.csv", df_final)

# Also save as .dta for compatibility
@save "temp/edgelist.dta", replace

# Print summary statistics
println("\nEdgelist created with $(nrow(df_final)) manager-firm pairs")
println("\nSummary of spell lengths:")
describe(df_final.T)
println("\nFirst few rows:")
println(first(df_final, 10))