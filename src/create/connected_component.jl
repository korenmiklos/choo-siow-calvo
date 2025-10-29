using DataFrames, Parquet2
using SparseArrays, Graphs, Random
using LinearAlgebra

# --- Data Structures --- #

struct BipartiteGraph
    sources::Vector{Int}
    targets::Vector{Int}
end

BipartiteGraph(edges::Vector{Tuple{Int, Int}}) = BipartiteGraph([e[1] for e in edges], [e[2] for e in edges])

struct ProjectedGraph
    adjacency::SparseMatrixCSC{Int, Int}
    node_idx::Dict{Int, Int}  # maps original ID to index
end

# --- I/O --- #

function resolve_column(df::DataFrame, name::AbstractString)::Symbol
    for col in names(df)
        if String(col) == name
            return Symbol(col)
        end
    end
    error("Column $(name) not found in DataFrame")
end

function read_edgelist_parquet(path::String, source_col::String, target_col::String)::BipartiteGraph
    df = Parquet2.readfile(path) |> DataFrame
    source_key = resolve_column(df, source_col)
    target_key = resolve_column(df, target_col)

    # Drop rows with missing person_id
    df = df[.!ismissing.(df[!, target_key]), :]
    return BipartiteGraph(Vector{Int}(df[!, source_key]), Vector{Int}(df[!, target_key]))
end

function write_edgelist_parquet(path::String, sources::Vector{Int}, targets::Vector{Int})
    dir = dirname(path)
    if !isempty(dir) && !isdir(dir)
        mkpath(dir)
    end
    df = DataFrame(source=sources, target=targets)
    Parquet2.writefile(path, df)
end

function write_component_parquet(path::String, person_ids::Vector{Int}, component_ids::Vector{Int}, sizes::Vector{Int})
    dir = dirname(path)
    if !isempty(dir) && !isdir(dir)
        mkpath(dir)
    end
    df = DataFrame(person_id=person_ids, component_id=component_ids, component_size=sizes)
    Parquet2.writefile(path, df)
end

# --- Core Logic --- #

function project_bipartite_graph(bipartite::BipartiteGraph)::ProjectedGraph
    sources, targets = bipartite.sources, bipartite.targets
    uniq_sources = unique(sources)
    uniq_targets = unique(targets)
    source_idx = Dict(s => i for (i, s) in enumerate(uniq_sources))
    target_idx = Dict(t => i for (i, t) in enumerate(uniq_targets))

    rows = [source_idx[s] for s in sources]
    cols = [target_idx[t] for t in targets]
    B = sparse(rows, cols, ones(Bool, length(rows)), length(uniq_sources), length(uniq_targets))

    P = B' * B
    P = dropzeros!(P - spdiagm(0 => diag(P)))  # remove self-loops

    return ProjectedGraph(P, target_idx)
end

function large_connected_components(graph::ProjectedGraph, min_size::Int=1000)::Tuple{Vector{Int}, Vector{Int}, Vector{Int}}
    G = SimpleGraph(graph.adjacency)
    components = connected_components(G)
    println("Number of components: ", length(components))
    
    # Filter components with at least min_size nodes
    large_components = filter(c -> length(c) >= min_size, components)
    println("Number of components with at least $min_size nodes: ", length(large_components))
    
    # Sort by size (descending)
    sort!(large_components, by=length, rev=true)
    
    # Print component sizes
    for (i, comp) in enumerate(large_components)
        println("Component $i size: ", length(comp))
    end
    
    # Convert indices to original IDs and assign component IDs
    idx_to_id = Dict(v => k for (k, v) in graph.node_idx)
    person_ids = Int[]
    component_ids = Int[]
    sizes = Int[]
    
    for (comp_id, component) in enumerate(large_components)
        size = length(component)
        for idx in component
            push!(person_ids, idx_to_id[idx])
            push!(component_ids, comp_id)
            push!(sizes, size)
        end
    end

    return person_ids, component_ids, sizes
end

# --- Synthetic Data Generator --- #

function generate_edgelist(n_left::Int, n_right::Int, edges_per_right::Int)::BipartiteGraph
    sources = Int[]
    targets = Int[]
    for t in 1:n_right
        selected_sources = rand(1:n_left, edges_per_right)
        append!(sources, selected_sources)
        append!(targets, fill(t, edges_per_right))
    end
    return BipartiteGraph(sources, targets)
end

# --- Main Analysis --- #
const COMPONENT_SIZE_CUTOFF = 30

# Read firm-manager edgelist from Stata output
bipartite = read_edgelist_parquet("temp/edgelist.parquet", "frame_id_numeric", "person_id")
println("Read ", length(bipartite.sources), " edges")

# Project to manager-manager network and find large connected components
graph = project_bipartite_graph(bipartite)
person_ids, component_ids, component_sizes = large_connected_components(graph, COMPONENT_SIZE_CUTOFF)
println("Total managers in components with $(COMPONENT_SIZE_CUTOFF)+ nodes: ", length(person_ids))

# Write manager person_ids and component_ids to Parquet
write_component_parquet("temp/large_component_managers.parquet", person_ids, component_ids, component_sizes)
