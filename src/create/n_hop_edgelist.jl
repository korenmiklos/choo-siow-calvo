# ============================================================
# Mobility pairs by matrix algebra
# ------------------------------------------------------------
# Enumerates endpoint and observation pairs required for
# covariance-style calculations without persisting endpoint-only
# CSV exports (wide/match outputs remain optional).
# Methods: 2-step pairs correspond to adjacency in the relevant
# projection, and pure 4-step pairs correspond to A^2 minus direct
# neighbors, diag=0.
# ============================================================

# -----------------------------------------------------------------------------
# OVERVIEW (read this first)
# -----------------------------------------------------------------------------
# Graph objects and what we compute
#   • B (P×F): person×firm incidence (binary). Rows are unique managers, columns are
#     unique firms. B[p,f]=1 iff manager p is observed at firm f (in any spell).
#   • A_mm (P×P): manager–manager projection adjacency, A_mm = (B*B')>0 with zero diag.
#     Two managers are adjacent if they share ≥1 firm. Corresponds to “2-hop” mm pairs.
#   • A_ff (F×F): firm–firm projection adjacency, A_ff = (B'*B)>0 with zero diag.
#     Two firms are adjacent if they share ≥1 manager. Corresponds to “2-hop” ff pairs.
#   • Pure 4-step adjacencies: From A_mm^2 (or A_ff^2), keep pairs connected at 2 hops
#     *within the projection* but NOT directly adjacent in that projection; zero diag.
#     These correspond to 4-step paths in the original bipartite graph
#       (e.g., m1–fA–mX–fB–m2 for mm; analogously for ff).
#   • DF (O×F), DM (O×P): observation×endpoint incidence matrices where each dataset row
#     (one firm–person spell) has exactly one 1 in DF and one 1 in DM.
#     PF = (DF*DF')>0 marks obs-pairs sharing a firm; PM = (DM*DM')>0 marks obs-pairs
#     sharing a manager. These are used ONLY to enumerate concrete observation pairs and
#     attach values (lnR, T) and intermediates in the optional “wide/matches” outputs.
# Files we write
#   • Endpoint-only CSV exports are intentionally disabled; pairs remain in memory for downstream consumption.
#   • Observation-wide (if WRITE_WIDE=true):
#       mm_2hop_wide.csv, ff_2hop_wide.csv, mm_4hop_pure_wide.csv, ff_4hop_pure_wide.csv
#     Witness enumerations that search for intermediate nodes (``*_matches.csv``) are disabled by default;
#     remove the surrounding `#= ... =#` block near the bottom of this file to reactivate them.
# -----------------------------------------------------------------------------

using CSV, DataFrames, Parquet2
using SparseArrays, LinearAlgebra

# ------------------------
# Configuration
# ------------------------
const IN_EDGELIST = "temp/edgelist.parquet"           # columns: :frame_id_numeric, :person_id
const OUT_DIR     = "./temp"
const FIRM_COL    = :frame_id_numeric
const PERSON_COL  = :person_id
const Y_COL      = :lnR                 # outcome y_im used in covariances
const WRITE_WIDE = true                 # write observation-wide pair files with IDs and y

# ------------------------
# Helpers
# ------------------------
"""
    build_incidence_matrix(df; person_col, firm_col)

Return a tuple (B, person_ids, firm_ids) where B is a sparse P×F 0–1
incidence matrix with rows indexed by `person_ids` and columns by `firm_ids`.
"""
function build_incidence_matrix(df::DataFrame; person_col::Symbol, firm_col::Symbol)
    # Unique ID vectors define the *axis order* for B (rows: persons, cols: firms)
    person_ids = unique!(Int.(copy(df[!, person_col])))
    firm_ids   = unique!(Int.(copy(df[!, firm_col])))
    # O(1) maps from external IDs to their row/column indices in B
    pid_to_row = Dict{Int,Int}(p => i for (i,p) in enumerate(person_ids))
    fid_to_col = Dict{Int,Int}(f => j for (j,f) in enumerate(firm_ids))

    # Assemble triplet form (I,J,V) for sparse constructor
    rows = Vector{Int}(undef, nrow(df))
    cols = Vector{Int}(undef, nrow(df))
    @inbounds for (k, r) in enumerate(eachrow(df))
        rows[k] = pid_to_row[Int(r[person_col])]
        cols[k] = fid_to_col[Int(r[firm_col])]
    end
    vals = ones(Int, length(rows))
    # Build B: counts collapse duplicate (person,firm) spells; we binarize next
    B = sparse(rows, cols, vals, length(person_ids), length(firm_ids))
    B .= sign.(B)  # ensure 0–1 incidence regardless of multiple spells per (p,f)
    return B, person_ids, firm_ids
end

"""
    build_observation_incidence(df; person_col, firm_col)

Return (DF, DM, firm_ids, person_ids) where DF is obs×F and DM is obs×P sparse 0–1 incidence matrices.
"""
function build_observation_incidence(df::DataFrame; person_col::Symbol, firm_col::Symbol)
    n_obs = nrow(df)
    # Axis order for observation-level incidence matrices (used for wide/matches only)
    firm_ids   = unique!(Int.(copy(df[!, firm_col])))
    person_ids = unique!(Int.(copy(df[!, person_col])))
    fid_to_col = Dict{Int,Int}(f => j for (j,f) in enumerate(firm_ids))
    pid_to_col = Dict{Int,Int}(p => i for (i,p) in enumerate(person_ids))

    # DF: obs×F (each row selects exactly one firm column)
    rows = collect(1:n_obs)
    colsF = similar(rows)
    @inbounds for r in 1:n_obs
        colsF[r] = fid_to_col[Int(df[r, firm_col])]
    end
    DF = sparse(rows, colsF, ones(Int, n_obs), n_obs, length(firm_ids))

    # DM: obs×P (each row selects exactly one person column)
    colsP = similar(rows)
    @inbounds for r in 1:n_obs
        colsP[r] = pid_to_col[Int(df[r, person_col])]
    end
    DM = sparse(rows, colsP, ones(Int, n_obs), n_obs, length(person_ids))

    # Note: PF=(DF*DF')>0 and PM=(DM*DM')>0 are obs×obs adjacencies used to enumerate
    # concrete pairs and attach lnR/T. They are *not* used for endpoint-level graph B.
    return DF, DM, firm_ids, person_ids
end

"""
    upper_triangle_pairs(A)

Given a symmetric Bool/Sparse adjacency matrix A with zero diagonal,
return a 2-column DataFrame of 1-based indices for the upper-triangle
edges (i<j).
"""
function upper_triangle_pairs(A::SparseMatrixCSC{Bool,Int})
    rows, cols, _ = findnz(triu(A, 1))
    return DataFrame(i = rows, j = cols)
end

"""
    obs_upper_pairs(Aobs)

Given a symmetric Bool/Sparse obs×obs adjacency with zero diagonal, return a DataFrame with columns :r1, :r2 (row indices, r1<r2).
"""
function obs_upper_pairs(Aobs::SparseMatrixCSC{Bool,Int})
    r, c, _ = findnz(triu(Aobs, 1))
    return DataFrame(r1 = r, r2 = c)
end

"""
    projection_adjacencies(B)

Compute manager and firm projection adjacencies (Boolean, zero diag):
  A_mm = (B * B') .> 0     # managers share ≥1 firm
  A_ff = (B' * B) .> 0     # firms share ≥1 manager
Diagonal entries are set to false.
"""
function projection_adjacencies(B::SparseMatrixCSC{Int,Int})
    # Manager projection: managers share a firm ⇔ positive dot product of their rows in B
    A_mm = (B * B') .> 0
    # Firm projection: firms share a manager ⇔ positive dot product of their columns in B
    A_ff = (B' * B) .> 0
    # Remove trivial self-links
    for i in 1:size(A_mm,1); A_mm[i,i] = false; end
    for j in 1:size(A_ff,1); A_ff[j,j] = false; end
    return A_mm, A_ff
end

"""
    pure_four_step_adjacency(A2, A)

Given A2 = (A*A) .> 0 and A (both Bool, zero diag), return the Bool
matrix of *pure* distance-4 connections: pairs connected in A2 but not
in A, with zero diagonal.
"""
function pure_four_step_adjacency(A2::SparseMatrixCSC{Bool,Int}, A::SparseMatrixCSC{Bool,Int})
    # A2 encodes 2-step connectivity *within the projection graph* (e.g., A_mm^2>0).
    # We want “pure” distance-4 in the bipartite sense: keep A2 edges but drop direct
    # neighbors already adjacent in A (and drop the diagonal).
    A4 = copy(A2)
    rowsA, colsA, _ = findnz(A)
    @inbounds for k in eachindex(rowsA)
        i = rowsA[k]; j = colsA[k]
        A4[i,j] = false
        A4[j,i] = false
    end
    for i in 1:size(A4,1); A4[i,i] = false; end
    return A4
end

"""
    index_pairs_to_ids(pairs_df, id_vec)

Map 1-based index pairs (i,j) to external identifiers using `id_vec`.
Returns a DataFrame with columns `id_1`, `id_2`.
"""
function index_pairs_to_ids(pairs_df::DataFrame, id_vec::Vector{Int}; c1::Symbol=:id_1, c2::Symbol=:id_2)
    ids1 = id_vec[pairs_df.i]
    ids2 = id_vec[pairs_df.j]
    return DataFrame(Symbol(c1) => ids1, Symbol(c2) => ids2)
end

"""
    write_pairs(path, id_pairs, colnames)

Write a two-column CSV of endpoint identifiers.
"""
function write_pairs(path::AbstractString, id_pairs::DataFrame, colnames::Tuple{Symbol,Symbol})
    desired = collect(colnames)
    current_names = names(id_pairs)
    rename_map = Dict{Symbol,Symbol}()
    for (curr, want) in zip(current_names, desired)
        if curr != want
            rename_map[Symbol(curr)] = Symbol(want)
        end
    end
    if !isempty(rename_map)
        rename!(id_pairs, rename_map)
    end
    CSV.write(path, id_pairs)
    return path
end

"""
    boolify(M)

Threshold a numeric sparse matrix to Bool and zero the diagonal.
"""
function boolify(M::SparseMatrixCSC)
    A = M .> 0
    for i in 1:size(A,1); A[i,i] = false; end
    return A
end

"""
    pure4_from_twohop(A2, A1)

Return Bool matrix of pure 4-step connections: A2 minus direct neighbors in A1 and zero diagonal.
"""
function pure4_from_twohop(A2::SparseMatrixCSC{Bool,Int}, A1::SparseMatrixCSC{Bool,Int})
    # Same operation as pure_four_step_adjacency but with different naming:
    # start from 2-step adjacency A2 within the observation graph, remove direct
    # neighbors in A1, and clear the diagonal.
    A4 = copy(A2)
    r, c, _ = findnz(A1)
    @inbounds for k in eachindex(r)
        i = r[k]; j = c[k]
        A4[i,j] = false
        A4[j,i] = false
    end
    for i in 1:size(A4,1); A4[i,i] = false; end
    return A4
end

# ------------------------
# Enrichment helpers (intermediate nodes + y values)
# ------------------------

"""
    build_lookup_maps(df; person_col, firm_col)

Return dictionaries to quickly retrieve observation row indices by (person, firm), by person, and by firm.
"""
function build_lookup_maps(df::DataFrame; person_col::Symbol, firm_col::Symbol)
    # by_pf[(p,f)] → vector of dataset row indices with that (person,firm) spell
    # by_p[p]      → all row indices where person p appears
    # by_f[f]      → all row indices where firm f appears
    by_pf = Dict{Tuple{Int,Int}, Vector{Int}}()
    by_p  = Dict{Int, Vector{Int}}()
    by_f  = Dict{Int, Vector{Int}}()
    @inbounds for r in 1:nrow(df)
        p = Int(df[r, person_col]); f = Int(df[r, firm_col])
        push!(get!(by_pf, (p,f), Int[]), r)
        push!(get!(by_p,  p,    Int[]), r)
        push!(get!(by_f,  f,    Int[]), r)
    end
    return by_pf, by_p, by_f
end

"""
    mm2_matches_rows(m1, m2, firm_ids_common, by_pf, df, Y_COL, T_sym)

Create rows for all (m1, m2) sharing firms, including lnR and time for each side and the via firm.
"""
function mm2_matches_rows(m1::Int, m2::Int, firm_ids_common::Vector{Int}, by_pf::Dict{Tuple{Int,Int},Vector{Int}},
                          df::DataFrame, Y_COL::Symbol, T_sym::Union{Symbol,Nothing})
    # Enumerate all obs-level pairs (r1, r2) for m1, m2 sharing a firm; emit one row per (r1 from (m1,f), r2 from (m2,f)) with via firm and lnR.
    rows = Vector{NamedTuple}()
    for f in firm_ids_common
        r1s = get(by_pf, (m1,f), Int[]); r2s = get(by_pf, (m2,f), Int[])
        for r1 in r1s, r2 in r2s
            nt = (
                person_id_1 = m1,
                person_id_2 = m2,
                via_firm_id = f,
                y_1 = df[r1, Y_COL],
                y_2 = df[r2, Y_COL],
                T_1 = T_sym === nothing ? missing : df[r1, T_sym],
                T_2 = T_sym === nothing ? missing : df[r2, T_sym],
            )
            push!(rows, nt)
        end
    end
    return rows
end

"""
    ff2_matches_rows(f1, f2, person_ids_common, by_pf, df, Y_COL, T_sym)

Symmetric to mm2 for firm–firm via shared managers.
"""
function ff2_matches_rows(f1::Int, f2::Int, person_ids_common::Vector{Int}, by_pf::Dict{Tuple{Int,Int},Vector{Int}},
                          df::DataFrame, Y_COL::Symbol, T_sym::Union{Symbol,Nothing})
    # Enumerate all obs-level pairs (r1, r2) for f1, f2 sharing a manager; emit one row per (r1 from (m, f1), r2 from (m, f2)) with via person and lnR.
    rows = Vector{NamedTuple}()
    for m in person_ids_common
        r1s = get(by_pf, (m,f1), Int[]); r2s = get(by_pf, (m,f2), Int[])
        for r1 in r1s, r2 in r2s
            nt = (
                firm_id_1 = f1,
                firm_id_2 = f2,
                via_person_id = m,
                y_1 = df[r1, Y_COL],
                y_2 = df[r2, Y_COL],
                T_1 = T_sym === nothing ? missing : df[r1, T_sym],
                T_2 = T_sym === nothing ? missing : df[r2, T_sym],
            )
            push!(rows, nt)
        end
    end
    return rows
end

#=
"""
    mm4_matches_rows(m1, m2, B, person_ids, firm_ids, by_pf, df, Y_COL, T_sym)

For each mm pure 4-step pair (m1,m2), find witness chains m1–fA–mX–fB–m2, and output one row per concrete observation-quartet with both intermediate nodes and lnR at endpoints.
"""
function mm4_matches_rows(m1::Int, m2::Int, B::SparseMatrixCSC{Int,Int}, person_ids::Vector{Int}, firm_ids::Vector{Int},
                          by_pf::Dict{Tuple{Int,Int},Vector{Int}}, df::DataFrame, Y_COL::Symbol, T_sym::Union{Symbol,Nothing})
    # Enumerate all concrete observation-level witness chains m1–fA–mX–fB–m2 and emit
    # one row per (r1 from (m1,fA), r2 from (m2,fb)), carrying intermediates and lnR.
    rows = Vector{NamedTuple}()
    i = findfirst(==(m1), person_ids); j = findfirst(==(m2), person_ids)
    # Firms worked by each endpoint
    Fi = findall(x->x>0, B[i,:])
    Fj = findall(x->x>0, B[j,:])
    for fa_idx in Fi
        fa = firm_ids[fa_idx]
        # Managers who also worked at fa
        mX_rows = findall(x->x>0, B[:,fa_idx])
        for mx_row in mX_rows
            mX = person_ids[mx_row]
            if mX == m1 || mX == m2; continue; end
            # Firms of mX
            Fmx = findall(x->x>0, B[mx_row,:])
            for fb_idx in Fmx
                fb = firm_ids[fb_idx]
                # endpoint 2 must have worked at fb
                if B[j, fb_idx] == 0; continue; end
                # materialize observation-level combinations
                r1s = get(by_pf, (m1,fa), Int[])
                r2s = get(by_pf, (m2,fb), Int[])
                for r1 in r1s, r2 in r2s
                    nt = (
                        person_id_1 = m1,
                        person_id_2 = m2,
                        via_person_id = mX,
                        via_firm_id_left = fa,
                        via_firm_id_right = fb,
                        y_1 = df[r1, Y_COL],
                        y_2 = df[r2, Y_COL],
                        T_1 = T_sym === nothing ? missing : df[r1, T_sym],
                        T_2 = T_sym === nothing ? missing : df[r2, T_sym],
                    )
                    push!(rows, nt)
                end
            end
        end
    end
    return rows
end

"""
    ff4_matches_rows(f1, f2, B, person_ids, firm_ids, by_pf, df, Y_COL, T_sym)

For each ff pure 4-step pair (f1,f2), find chains f1–mX–fY–mZ–f2 and output both intermediates and lnR at endpoints.
"""
function ff4_matches_rows(f1::Int, f2::Int, B::SparseMatrixCSC{Int,Int}, person_ids::Vector{Int}, firm_ids::Vector{Int},
                          by_pf::Dict{Tuple{Int,Int},Vector{Int}}, df::DataFrame, Y_COL::Symbol, T_sym::Union{Symbol,Nothing})
    # Enumerate all obs-level witness chains f1–mX–fY–mZ–f2; emit one row per (r1 from (mX,f1), r2 from (mZ,f2)), with both intermediates and lnR.
    rows = Vector{NamedTuple}()
    a = findfirst(==(f1), firm_ids); b = findfirst(==(f2), firm_ids)
    # Managers who worked at each endpoint firm
    Ma = findall(x->x>0, B[:,a])
    Mb = findall(x->x>0, B[:,b])
    for mx_row in Ma
        mX = person_ids[mx_row]
        # Firms also worked by mX (potential middle firm)
        Fy = findall(x->x>0, B[mx_row,:])
        for fy_idx in Fy
            fY = firm_ids[fy_idx]
            # Managers who worked at fY
            Mz_rows = findall(x->x>0, B[:,fy_idx])
            for mz_row in Mz_rows
                mZ = person_ids[mz_row]
                # mZ must have worked at f2
                if B[mz_row, b] == 0; continue; end
                # materialize observation-level combinations for endpoints
                r1s = get(by_pf, (mX,f1), Int[])
                r2s = get(by_pf, (mZ,f2), Int[])
                for r1 in r1s, r2 in r2s
                    nt = (
                        firm_id_1 = f1,
                        firm_id_2 = f2,
                        via_person_id_left = mX,
                        via_firm_id_mid = fY,
                        via_person_id_right = mZ,
                        y_1 = df[r1, Y_COL],
                        y_2 = df[r2, Y_COL],
                        T_1 = T_sym === nothing ? missing : df[r1, T_sym],
                        T_2 = T_sym === nothing ? missing : df[r2, T_sym],
                    )
                    push!(rows, nt)
                end
            end
        end
    end
    return rows
end
=#

# ------------------------
# Main
# ------------------------
function main()
    isdir(OUT_DIR) || mkpath(OUT_DIR)

    @info "Reading edgelist" IN_EDGELIST
    df = DataFrame(Parquet2.Dataset(IN_EDGELIST))
    # df is an edgelist of firm–person spells; columns include PERSON_COL, FIRM_COL,
    # and optionally T and Y_COL (lnR). Each row is a single observation/spell.
    @assert PERSON_COL ∈ propertynames(df) "Missing column: $(PERSON_COL)"
    @assert FIRM_COL   ∈ propertynames(df) "Missing column: $(FIRM_COL)"

    # Optional time column (if present)
    T_sym = :T in propertynames(df) ? :T : nothing

    # Build lookup maps for enrichment
    by_pf, by_p, by_f = build_lookup_maps(df; person_col=PERSON_COL, firm_col=FIRM_COL)

    # Build B (person×firm) and projection adjacencies A_mm (manager–manager) and
    # A_ff (firm–firm). These drive the endpoint-only pair outputs below.
    B, person_ids, firm_ids = build_incidence_matrix(df; person_col=PERSON_COL, firm_col=FIRM_COL)
    A_mm, A_ff = projection_adjacencies(B)

    if WRITE_WIDE
        # Observation-level route: replicate the same logic in obs-space (PF, PM) so
        # we can enumerate concrete pairs and attach lnR/T and intermediates. This
        # does not affect endpoint-only pairs written later.
        @info "Building observation-level projections for wide outputs"
        @assert Y_COL ∈ propertynames(df) "Missing outcome column: $(Y_COL)"
        DF, DM, firm_ids_obs, person_ids_obs = build_observation_incidence(df; person_col=PERSON_COL, firm_col=FIRM_COL)

        # PF[o1,o2]=1 ⇔ obs share a firm; PM[o1,o2]=1 ⇔ obs share a manager.
        PF = boolify(DF * transpose(DF))
        PM = boolify(DM * transpose(DM))

        # 2-step sets
        mm2_obs_pairs = obs_upper_pairs(PF)                    # same firm, potentially different managers
        ff2_obs_pairs = obs_upper_pairs(PM)                    # same manager, potentially different firms

        # Enforce that the two observations correspond to *different* endpoints on the
        # dimension of interest (avoid trivial self-matches through the same person/firm).
        mm2_obs_pairs = mm2_obs_pairs[df[mm2_obs_pairs.r1, PERSON_COL] .!= df[mm2_obs_pairs.r2, PERSON_COL], :]
        ff2_obs_pairs = ff2_obs_pairs[df[ff2_obs_pairs.r1, FIRM_COL]   .!= df[ff2_obs_pairs.r2, FIRM_COL],   :]

        # Pure 4-step via squared projection minus direct neighbors
        PF2 = boolify(SparseMatrixCSC{Int,Int}(PF) * SparseMatrixCSC{Int,Int}(PF))
        PM2 = boolify(SparseMatrixCSC{Int,Int}(PM) * SparseMatrixCSC{Int,Int}(PM))

        mm4_obs_pure = obs_upper_pairs(pure4_from_twohop(PF2, PF))
        ff4_obs_pure = obs_upper_pairs(pure4_from_twohop(PM2, PM))

        # Assemble wide DataFrames with IDs and outcomes
        function assemble_wide(pairs::DataFrame)
            r1 = pairs.r1; r2 = pairs.r2
            return DataFrame(
                firm_id_1   = df[r1, FIRM_COL],
                person_id_1 = df[r1, PERSON_COL],
                y_1         = df[r1, Y_COL],
                firm_id_2   = df[r2, FIRM_COL],
                person_id_2 = df[r2, PERSON_COL],
                y_2         = df[r2, Y_COL],
            )
        end

        mm2_wide = assemble_wide(mm2_obs_pairs)
        ff2_wide = assemble_wide(ff2_obs_pairs)
        mm4_wide = assemble_wide(mm4_obs_pure)
        ff4_wide = assemble_wide(ff4_obs_pure)

        # Write wide outputs
        mm2_wide_path = joinpath(OUT_DIR, "mm_2hop_wide.csv")
        ff2_wide_path = joinpath(OUT_DIR, "ff_2hop_wide.csv")
        mm4_wide_path = joinpath(OUT_DIR, "mm_4hop_pure_wide.csv")
        ff4_wide_path = joinpath(OUT_DIR, "ff_4hop_pure_wide.csv")

        CSV.write(mm2_wide_path, mm2_wide)
        CSV.write(ff2_wide_path, ff2_wide)
        CSV.write(mm4_wide_path, mm4_wide)
        CSV.write(ff4_wide_path, ff4_wide)

        @info "Wide outputs written" mm2=mm2_wide_path ff2=ff2_wide_path mm4=mm4_wide_path ff4=ff4_wide_path
    end

    # 2-step pairs (upper triangle only)
    mm2_idx = upper_triangle_pairs(A_mm)
    ff2_idx = upper_triangle_pairs(A_ff)

    mm2_ids = index_pairs_to_ids(mm2_idx, person_ids; c1=:person_id_1, c2=:person_id_2)
    ff2_ids = index_pairs_to_ids(ff2_idx, firm_ids; c1=:firm_id_1, c2=:firm_id_2)

    # Pure 4-step at endpoint level: square projection adjacencies and subtract direct
    # neighbors. Upper triangle extraction yields unique pairs (i<j).
    A_mm2 = (SparseMatrixCSC{Int,Int}(A_mm) * SparseMatrixCSC{Int,Int}(A_mm)) .> 0
    A_ff2 = (SparseMatrixCSC{Int,Int}(A_ff) * SparseMatrixCSC{Int,Int}(A_ff)) .> 0

    A_mm4_pure = pure_four_step_adjacency(A_mm2, A_mm)
    A_ff4_pure = pure_four_step_adjacency(A_ff2, A_ff)

    mm4_idx = upper_triangle_pairs(A_mm4_pure)
    ff4_idx = upper_triangle_pairs(A_ff4_pure)

    mm4_ids = index_pairs_to_ids(mm4_idx, person_ids; c1=:person_id_1, c2=:person_id_2)
    ff4_ids = index_pairs_to_ids(ff4_idx, firm_ids;   c1=:firm_id_1,   c2=:firm_id_2)

    @info "Endpoint pair CSV export skipped per configuration"

    # ------------------------
    # Enriched witness enumerations: disabled by default to skip intermediate-node search.
    # To re-enable the logic and produce the ``*_matches.csv`` files, delete the surrounding
    # `#= ... =#` comment block and rerun the script (WRITE_WIDE must remain true).
    # ------------------------

    # Helper to collect common firms for two managers
    function common_firms(m1::Int, m2::Int)
        i = findfirst(==(m1), person_ids); j = findfirst(==(m2), person_ids)
        Fi = findall(x->x>0, B[i,:]); Fj = findall(x->x>0, B[j,:])
        return firm_ids[intersect(Fi, Fj)]
    end

    # Helper to collect common managers for two firms
    function common_persons(f1::Int, f2::Int)
        a = findfirst(==(f1), firm_ids); b = findfirst(==(f2), firm_ids)
        Ma = findall(x->x>0, B[:,a]); Mb = findall(x->x>0, B[:,b])
        return person_ids[intersect(Ma, Mb)]
    end

    #=
    # mm 2-hop matches
    mm2_rows = NamedTuple[]
    for row in eachrow(mm2_ids)
        m1 = Int(row[:person_id_1]); m2 = Int(row[:person_id_2])
        cfs = common_firms(m1, m2)
        append!(mm2_rows, mm2_matches_rows(m1, m2, cfs, by_pf, df, Y_COL, T_sym))
    end
    mm2_matches = DataFrame(mm2_rows)
    CSV.write(joinpath(OUT_DIR, "mm_2hop_matches.csv"), mm2_matches)

    # ff 2-hop matches
    ff2_rows = NamedTuple[]
    for row in eachrow(ff2_ids)
        f1 = Int(row[:firm_id_1]); f2 = Int(row[:firm_id_2])
        cps = common_persons(f1, f2)
        append!(ff2_rows, ff2_matches_rows(f1, f2, cps, by_pf, df, Y_COL, T_sym))
    end
    ff2_matches = DataFrame(ff2_rows)
    CSV.write(joinpath(OUT_DIR, "ff_2hop_matches.csv"), ff2_matches)

    # mm pure 4-step matches (with intermediates)
    mm4_rows = NamedTuple[]
    for row in eachrow(mm4_ids)
        m1 = Int(row[:person_id_1]); m2 = Int(row[:person_id_2])
        append!(mm4_rows, mm4_matches_rows(m1, m2, B, person_ids, firm_ids, by_pf, df, Y_COL, T_sym))
    end
    mm4_matches = DataFrame(mm4_rows)
    CSV.write(joinpath(OUT_DIR, "mm_4hop_pure_matches.csv"), mm4_matches)

    # ff pure 4-step matches (with intermediates)
    ff4_rows = NamedTuple[]
    for row in eachrow(ff4_ids)
        f1 = Int(row[:firm_id_1]); f2 = Int(row[:firm_id_2])
        append!(ff4_rows, ff4_matches_rows(f1, f2, B, person_ids, firm_ids, by_pf, df, Y_COL, T_sym))
    end
    ff4_matches = DataFrame(ff4_rows)
    CSV.write(joinpath(OUT_DIR, "ff_4hop_pure_matches.csv"), ff4_matches)
    =#

    @info "Enriched outputs skipped" hint="remove #= ... =# block to enable matches"
end

main()
