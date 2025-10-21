using Kezdi
using CSV
using DataFrames

# Load CEO panel data
@use "input/manager-db-ceo-panel/ceo-panel.dta"

# Filter by year range
@keep @if year >= 1992 && year <= 2022

# Keep only relevant dimensions
@keep frame_id_numeric person_id year manager_category

# Count CEOs per firm-year
@egen n_ceo = rowcount(person_id), by(frame_id_numeric, year)

# Save the processed CEO panel to Parquet
using Parquet2
df_ceo_panel = getdf()
Parquet2.writefile("temp/ceo-panel.parquet", df_ceo_panel)