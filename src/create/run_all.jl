#!/usr/bin/env julia

using Logging

@info "Starting data processing pipeline"

@info "Processing CEO panel data"
include("ceo-panel.jl")

@info "Processing balance sheet data"
include("balance.jl")

@info "Merging data and creating analysis panel"
include("merged-panel.jl")

@info "Creating edgelist with spell lengths"
include("edgelist.jl")

@info "Data processing pipeline completed"