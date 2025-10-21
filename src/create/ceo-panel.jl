using Kezdi
using CSV
using DataFrames

# CEO PANEL DATA PARAMETERS
const start_year = 1992
const end_year = 2022

# Load CEO panel data
@use "input/manager-db-ceo-panel/ceo-panel.dta"

# Birth year is better than entry
@replace first_year_as_ceo = birth_year + 18 @if first_year_as_ceo < birth_year + 18 && !ismissing(birth_year)
# Except for very old people
@replace birth_year = 1911 @if birth_year < 1911

# For missing birth year, extrapolate from entry
@egen pt = tag(person_id)
@generate age_at_entry = first_year_as_ceo - birth_year @if !ismissing(birth_year) && !ismissing(first_year_as_ceo)

# Calculate median age at entry
df_temp = @with getdf() begin
    @keep @if pt && !ismissing(age_at_entry)
end
median_age_at_entry = median(df_temp.age_at_entry)

# Impute missing birth years
@generate imputed_age = ismissing(birth_year) && !ismissing(first_year_as_ceo)
@replace birth_year = first_year_as_ceo - median_age_at_entry @if ismissing(birth_year) && !ismissing(first_year_as_ceo)

# Filter by year range
@keep @if year >= start_year && year <= end_year

# Keep only relevant dimensions
@keep frame_id_numeric person_id year male birth_year manager_category owner cf

# Count CEOs per firm-year
@egen n_ceo = rowcount(person_id), by(frame_id_numeric, year)

# Save the processed CEO panel
@save "temp/ceo-panel.dta", replace