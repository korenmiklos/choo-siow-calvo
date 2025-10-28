using Kezdi
using Parquet2

# Load the merged panel data
df_merged = Parquet2.readfile("temp/merged-panel.parquet") |> DataFrame
setdf(df_merged)

# Calculate spell length for each person-firm pair
# First, calculate the tenure for each observation
@sort frame_id_numeric person_id year
@egen spell_start = minimum(year), by(frame_id_numeric, person_id)
@egen spell_end = maximum(year), by(frame_id_numeric, person_id)
@generate T = spell_end - spell_start + 1

# The network code has no sense of time, remove time effects by demeaning lnR, lnY, lnL by year 
@egen lnR_mean = mean(lnR), by(year)
@egen lnY_mean = mean(lnY), by(year)
@egen lnL_mean = mean(lnL), by(year)

@replace lnR = lnR - lnR_mean
@replace lnY = lnY - lnY_mean
@replace lnL = lnL - lnL_mean

# Create unique person-firm pairs with their characteristics
# Keep one observation per person-firm pair with averages
@collapse T = mean(T) lnR = mean(lnR) lnY = mean(lnY) lnL = mean(lnL) spell_start = minimum(year) spell_end = maximum(year), by(frame_id_numeric, person_id)

# Drop any observations with missing values in key variables
@drop @if ismissing(lnR) || ismissing(lnY) || ismissing(lnL)

# Select and order the columns for the edgelist
@keep frame_id_numeric person_id T lnR lnY lnL

# Export to CSV and Parquet
df_final = getdf()
Parquet2.writefile("temp/edgelist.parquet", df_final)