using Kezdi

# Load CEO panel data
@use "input/manager-db-ceo-panel/ceo-panel.dta"

# Filter by year range
@keep @if year >= 1992 && year <= 2022

# Keep only relevant dimensions
@keep frame_id_numeric person_id year manager_category

# Count CEOs per firm-year
@egen n_ceo = rowcount(person_id), by(frame_id_numeric, year)

@save "temp/ceo-panel.dta", replace
