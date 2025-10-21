using Kezdi
using CSV
using DataFrames
using Dates
using Parquet2

# Load balance sheet data
df_balance = Parquet2.readfile("temp/balance.parquet") |> DataFrame
setdf(df_balance)

# Load CEO panel data
df_ceo = Parquet2.readfile("temp/ceo-panel.parquet") |> DataFrame

# Perform the merge
setdf(leftjoin(df_balance, df_ceo, on=[:frame_id_numeric, :year], makeunique=true))

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

# Apply filters
@drop @if ceo_spell == 0  # No CEO
const excluded_sectors = [2, 9]
@drop @if sector ∈ excluded_sectors

# Keep only observations with valid CEO assignments
@drop @if ismissing(person_id)

# Save the merged panel to Parquet
df_merged_panel = getdf()
Parquet2.writefile("temp/merged-panel.parquet", df_merged_panel)