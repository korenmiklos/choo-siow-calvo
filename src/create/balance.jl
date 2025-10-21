using Kezdi
using CSV
using DataFrames

# BALANCE SHEET DATA PARAMETERS
const start_year = 1992
const end_year = 2022
const min_employment = 1

# Load balance sheet data
@use "input/merleg-LTS-2023/balance/balance_sheet_80_22.dta"

# Filter by year range
@keep @if year >= start_year && year <= end_year
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
@replace employment = min_employment @if employment < min_employment
@replace employment = floor(Int, employment)

# Save the processed balance sheet data to Parquet
using Parquet2
df_balance_data = getdf()
Parquet2.writefile("temp/balance.parquet", df_balance_data)