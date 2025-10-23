using CSV, DataFrames, SparseArrays

# I/O
const IN_EDGELIST = "temp/edgelist.csv"  # 1-hop obs: firm–manager spells with lnR, lnY, lnL
const OUT_DIR = "temp"                   # outputs: mm_pure_{n}hop_general.csv, ff_pure_{n}hop_general.csv
const MAX_N = 4                          # compute PURE n-hop for n = 2,4,6,...,MAX_N

# Note: PURE hops means we are looking for pairs with an n-hop
# connection such that those connections are not connected by any
# shorter even-length paths. E.g., PURE 4-hop pairs are connected
# by a 4-hop path but not by any 2-hop paths.

# ------------ Load & sanity check ------------
df = CSV.read(IN_EDGELIST, DataFrame)
required = [:frame_id_numeric, :person_id, :T, :lnR, :lnY, :lnL]
missing = setdiff(required, propertynames(df))
@assert isempty(missing) "Missing columns in edgelist: $(missing)"

# Build (sparse) incidence (obs×firm, obs×person)
n_obs = nrow(df)

firm_ids   = unique(df.frame_id_numeric)
pers_ids   = unique(df.person_id)
firm_to_j  = Dict(firm_ids[i] => i for i in eachindex(firm_ids))
pers_to_j  = Dict(pers_ids[i] => i for i in eachindex(pers_ids))
n_firm, n_pers = length(firm_ids), length(pers_ids)

DF_i = Vector{Int}(undef, n_obs)  # obs index
DF_j = Vector{Int}(undef, n_obs)  # firm col
DM_i = Vector{Int}(undef, n_obs)  # obs index
DM_j = Vector{Int}(undef, n_obs)  # person col

for r in 1:n_obs
    DF_i[r] = r; DF_j[r] = firm_to_j[df.frame_id_numeric[r]]
    DM_i[r] = r; DM_j[r] = pers_to_j[df.person_id[r]]
end

DF = sparse(DF_i, DF_j, ones(Int, n_obs), n_obs, n_firm)  # obs×firm
DM = sparse(DM_i, DM_j, ones(Int, n_obs), n_obs, n_pers)  # obs×person

# 2-hop projections on observations
# PF>0: two observations share a FIRM  (manager–manager 2-hop)
# PM>0: two observations share a PERSON (firm–firm 2-hop)
PF = DF * DF'
PM = DM * DM'

# Don't count self-links (ensure zero-diagonal)
function zero_diag!(A::SparseMatrixCSC{T,Int}) where {T}
    n = min(size(A,1), size(A,2))
    @inbounds for k in 1:n
        A[k,k] = zero(T)
    end
    return A
end
zero_diag!(PF); zero_diag!(PM)

# PURE even-n hops via ALTERNATING products (SYMMETRIZED)
# mm-style: start with PF; ff-style: start with PM.
# At each even n, raw(n) := (alternating product) > 0; then SYMMETRIZE: raw := raw .| raw'
# PURE(n) = raw(n) \ (union of raw(2), raw(4), ..., raw(n-2)).
function pure_even_hops_alternating(PF::SparseMatrixCSC{Int,Int},
                                    PM::SparseMatrixCSC{Int,Int},
                                    max_n_even::Int; start::Symbol)
    @assert iseven(max_n_even) "max_n_even must be even"

    # Base adjacency and first multiplier
    current = (start == :mm) ? PF : PM
    mult    = (start == :mm) ? PM : PF

    # raw 2-hop (Bool), symmetrize (PF/PM are already symmetric, but keep uniform)
    raw2 = current .> 0
    raw2 = raw2 .| raw2'             # <-- symmetrize
    zero_diag!(raw2)

    prev_reach = copy(raw2)          # union of all lower-even reachability (Bool)
    result = Dict{Int, SparseMatrixCSC{Bool,Int}}(2 => copy(raw2))

    # For n = 4,6,...,max_n_even, alternate multipliers
    for n in 4:2:max_n_even
        current = current * mult      # append two hops via the opposite projection
        raw = current .> 0
        raw = raw .| raw'             # <-- symmetrize the 4-hop (or higher) reachability
        zero_diag!(raw)

        pure = raw .& .!prev_reach    # exclude any shorter even paths (2..n-2)
        result[n] = pure

        prev_reach .= prev_reach .| raw

        # flip multiplier for next even n
        mult = (mult === PM) ? PF : PM
    end
    return result
end

# Build wide pair export
const SELECT = [:frame_id_numeric, :person_id, :T, :lnR, :lnY, :lnL]

# Extract upper-triangular (i<j) true entries from Bool sparse
function upper_pairs(B::SparseMatrixCSC{Bool,Int})
    I,J,V = findnz(B)
    keep = findall(t -> (V[t] == true) && (I[t] < J[t]), eachindex(V))
    return I[keep], J[keep]
end

function write_wide_pairs(df::DataFrame, B::SparseMatrixCSC{Bool,Int}, outpath::String)
    if nnz(B) == 0
        CSV.write(outpath, DataFrame())  # empty file if no pairs
        return
    end
    i, j = upper_pairs(B)
    left  = df[i, SELECT]
    right = df[j, SELECT]
    rename!(left,  Symbol.(string.(names(left))  .* "_1"))
    rename!(right, Symbol.(string.(names(right)) .* "_2"))
    out = hcat(left, right)
    CSV.write(outpath, out)
end

# Compute and write PURE n-hop datasets
mm_pure = pure_even_hops_alternating(PF, PM, MAX_N; start=:mm)  # PF, PF·PM, PF·PM·PF, ...
ff_pure = pure_even_hops_alternating(PF, PM, MAX_N; start=:ff)  # PM, PM·PF, PM·PF·PM, ...

for n in sort(collect(keys(mm_pure)))
    write_wide_pairs(df, mm_pure[n], "$(OUT_DIR)/mm_pure_$(n)hop_general.csv")
end
for n in sort(collect(keys(ff_pure)))
    write_wide_pairs(df, ff_pure[n], "$(OUT_DIR)/ff_pure_$(n)hop_general.csv")
end

println("Wrote PURE n-hop CSVs (n even, up to $(MAX_N)) in $(OUT_DIR).")