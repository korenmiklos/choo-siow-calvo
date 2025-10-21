#!/usr/bin/env julia
# Main script to run the entire data processing pipeline

println("Starting data processing pipeline...")
println("=" ^ 60)

# Step 1: Process CEO panel data
println("\n1. Processing CEO panel data...")
include("ceo-panel.jl")
println("   ✓ CEO panel processed and saved to temp/ceo-panel.dta")

# Step 2: Process balance sheet data
println("\n2. Processing balance sheet data...")
include("balance.jl")
println("   ✓ Balance sheet data processed and saved to temp/balance.dta")

# Step 3: Merge and create analysis panel
println("\n3. Merging data and creating analysis panel...")
include("merged-panel.jl")
println("   ✓ Merged panel created and saved to temp/merged-panel.dta")

# Step 4: Create edgelist with spell lengths
println("\n4. Creating edgelist with spell lengths...")
include("edgelist.jl")
println("   ✓ Edgelist created and saved to:")
println("     - temp/edgelist.csv")
println("     - temp/edgelist.dta")

println("\n" * "=" ^ 60)
println("Data processing pipeline completed successfully!")
println("=" ^ 60)