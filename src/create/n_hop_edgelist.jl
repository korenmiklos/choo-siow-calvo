using CSV, DataFrames, SparseArrays, Random, StatsBase, Parquet2

# I/O
const IN_EDGELIST = "temp/edgelist.parquet"   # columns: frame_id_numeric, person_id, T, lnR, lnY, lnL
const OUT_DIR     = "temp"
const MAX_N       = 4                     # even only: 2,4,6,...,MAX_N

# Load & checks
df = Parquet2.readfile(IN_EDGELIST) |> DataFrame

# If random sample desired to speed up computation, uncomment below:
# rng = MersenneTwister(123456)  # reproducible
# k = max(1, round(Int, 0.10 * nrow(df)))              # exact count
# df = df[sample(rng, 1:nrow(df), k; replace=false), :] # pick k row indices

required = [:frame_id_numeric, :person_id, :T, :lnR, :lnY, :lnL]
missing  = setdiff(required, propertynames(df))
@assert isempty(missing) "Missing columns in edgelist: $(missing)"
isdir(OUT_DIR) || mkpath(OUT_DIR)

# Manager–firm bipartite
pairs = unique(select(df, :person_id, :frame_id_numeric))

# Indexers
manager_ids = unique(pairs.person_id)
firm_ids    = unique(pairs.frame_id_numeric)
m_to_i      = Dict(manager_ids[i] => i for i in eachindex(manager_ids))   # manager id -> row index
f_to_j      = Dict(firm_ids[j]    => j for j in eachindex(firm_ids))      # firm id    -> col index
M, F        = length(manager_ids), length(firm_ids)

# Sparse incidence MF[i,j] = 1 iff manager i is linked to firm j
MF_I = Vector{Int}(undef, nrow(pairs))
MF_J = Vector{Int}(undef, nrow(pairs))
for r in 1:nrow(pairs)
    MF_I[r] = m_to_i[pairs.person_id[r]]
    MF_J[r] = f_to_j[pairs.frame_id_numeric[r]]
end
MF = sparse(MF_I, MF_J, ones(Int, nrow(pairs)), M, F)

# Helpers
function zero_diag!(A::SparseMatrixCSC{T,Int}) where {T}
    n = min(size(A,1), size(A,2))
    @inbounds for k in 1:n
        A[k,k] = zero(T)
    end
    return A
end

function upper_pairs(B::SparseMatrixCSC{Bool,Int})
    I,J,V = findnz(B)                     # matrix -> (I,J,V)
    keep = findall(t -> V[t] && (I[t] < J[t]), eachindex(V))
    return I[keep], J[keep]
end

# Edge profile: (person_id, frame_id_numeric) -> (T, lnR, lnY, lnL)
# Required to pick edge attribute values for output pairs
function build_edge_profile(df::DataFrame)
    ep = Dict{Tuple{Int,Int}, NamedTuple{(:T,:lnR,:lnY,:lnL),Tuple{Int,Float64,Float64,Float64}}}()
    for r in eachrow(df)
        key = (Int(r.person_id), Int(r.frame_id_numeric))
        ep[key] = (T = Int(r.T), lnR = Float64(r.lnR), lnY = Float64(r.lnY), lnL = Float64(r.lnL))
    end
    return ep
end
const EDGE = build_edge_profile(df)

@inline function edge_vals(pid, fid)
    get(EDGE, (Int(pid), Int(fid)), (T=missing, lnR=missing, lnY=missing, lnL=missing))
end

# Precompute neighbor lists from CSC internals
# mgr_to_firms[i]  = list of firm column indices connected to manager-row i
# firm_to_mgrs[j]  = list of manager row indices connected to firm-column j
mgr_to_firms = [Int[] for _ in 1:M]
firm_to_mgrs = [Int[] for _ in 1:F]
@inbounds for j in 1:F
    for p in MF.colptr[j]:(MF.colptr[j+1]-1)
        i = MF.rowval[p]
        push!(firm_to_mgrs[j], i)
        push!(mgr_to_firms[i], j)
    end
end

# 2-step layers with witnesses
# Managers: L2[a,b]=true if share at least one firm; store one shared firm j as witness
function mm2_with_witness()
    MM2 = MF * MF'
    L2  = (MM2 .> 0); L2 = L2 .| L2'; zero_diag!(L2)
    witness = Dict{Tuple{Int,Int},Int}()  # (a,b)-> firm col index j
    @inbounds for j in 1:F
        mgrs = firm_to_mgrs[j]
        for u in 1:length(mgrs)-1
            a = mgrs[u]
            for v in (u+1):length(mgrs)
                b = mgrs[v]
                key = a < b ? (a,b) : (b,a)
                get!(witness, key, j)      # store first seen firm as witness
            end
        end
    end
    return L2, witness
end

# Firms: L2[f,g]=true if share at least one manager; store one shared manager i as witness
function ff2_with_witness()
    FF2 = MF' * MF
    L2  = (FF2 .> 0); L2 = L2 .| L2'; zero_diag!(L2)
    witness = Dict{Tuple{Int,Int},Int}()  # (f,g)-> manager row index i
    @inbounds for i in 1:M
        frms = mgr_to_firms[i]
        for u in 1:length(frms)-1
            a = frms[u]
            for v in (u+1):length(frms)
                b = frms[v]
                key = a < b ? (a,b) : (b,a)
                get!(witness, key, i)
            end
        end
    end
    return L2, witness
end

# Compose higher even layers carrying witnesses
# Managers: compose (n-2)-hop with 2-hop via intermediate k; carry left/right witnesses
function compose_mm_layer(L_prev::SparseMatrixCSC{Bool,Int},
                          left_prev::Dict{Tuple{Int,Int},Int},
                          L2::SparseMatrixCSC{Bool,Int},
                          right2::Dict{Tuple{Int,Int},Int},
                          M::Int)
    pairs_set = Set{Tuple{Int,Int}}()
    left_w    = Dict{Tuple{Int,Int},Int}()
    right_w   = Dict{Tuple{Int,Int},Int}()

    prev_neigh = [Int[] for _ in 1:M]
    begin
        I,J,_ = findnz(L_prev)            # matrix -> 3-tuple
        @inbounds for t in eachindex(I)
            a = I[t]; k = J[t]
            if a == k; continue; end
            push!(prev_neigh[k], a)
        end
    end
    two_neigh = [Int[] for _ in 1:M]
    begin
        I,J,_ = findnz(L2)                # matrix -> 3-tuple
        @inbounds for t in eachindex(I)
            k = I[t]; b = J[t]
            if k == b; continue; end
            push!(two_neigh[k], b)
        end
    end

    @inbounds for k in 1:M
        a_list = prev_neigh[k]
        b_list = two_neigh[k]
        isempty(a_list) && continue
        isempty(b_list) && continue
        for a in a_list
            la = left_prev[a < k ? (a,k) : (k,a)]   # firm adjacent to a on (a,k)
            for b in b_list
                if a == b; continue; end
                rb = right2[k < b ? (k,b) : (b,k)]  # firm adjacent to b on (k,b)
                x, y = a < b ? (a,b) : (b,a)
                if !((x,y) in pairs_set)
                    push!(pairs_set, (x,y))
                    if x == a
                        left_w[(x,y)]  = la
                        right_w[(x,y)] = rb
                    else
                        left_w[(x,y)]  = right2[a < k ? (a,k) : (k,a)]
                        right_w[(x,y)] = left_prev[k < b ? (k,b) : (b,k)]
                    end
                end
            end
        end
    end

    I = Int[]; J = Int[]
    @inbounds for (a,b) in pairs_set
        push!(I, a); push!(J, b)
        push!(I, b); push!(J, a)
    end
    raw = sparse(I, J, trues(length(I)), M, M)
    zero_diag!(raw)
    return raw, left_w, right_w
end

# Firms: analogous composition with manager witnesses
function compose_ff_layer(L_prev::SparseMatrixCSC{Bool,Int},
                          left_prev::Dict{Tuple{Int,Int},Int},
                          L2::SparseMatrixCSC{Bool,Int},
                          right2::Dict{Tuple{Int,Int},Int},
                          F::Int)
    pairs_set = Set{Tuple{Int,Int}}()
    left_w    = Dict{Tuple{Int,Int},Int}()
    right_w   = Dict{Tuple{Int,Int},Int}()

    prev_neigh = [Int[] for _ in 1:F]
    begin
        I,J,_ = findnz(L_prev)
        @inbounds for t in eachindex(I)
            a = I[t]; k = J[t]
            if a == k; continue; end
            push!(prev_neigh[k], a)
        end
    end
    two_neigh = [Int[] for _ in 1:F]
    begin
        I,J,_ = findnz(L2)
        @inbounds for t in eachindex(I)
            k = I[t]; b = J[t]
            if k == b; continue; end
            push!(two_neigh[k], b)
        end
    end

    @inbounds for k in 1:F
        a_list = prev_neigh[k]
        b_list = two_neigh[k]
        isempty(a_list) && continue
        isempty(b_list) && continue
        for a in a_list
            la = left_prev[a < k ? (a,k) : (k,a)]   # manager adjacent to a on (a,k)
            for b in b_list
                if a == b; continue; end
                rb = right2[k < b ? (k,b) : (b,k)]  # manager adjacent to b on (k,b)
                x, y = a < b ? (a,b) : (b,a)
                if !((x,y) in pairs_set)
                    push!(pairs_set, (x,y))
                    if x == a
                        left_w[(x,y)]  = la
                        right_w[(x,y)] = rb
                    else
                        left_w[(x,y)]  = right2[a < k ? (a,k) : (k,a)]
                        right_w[(x,y)] = left_prev[k < b ? (k,b) : (b,k)]
                    end
                end
            end
        end
    end

    I = Int[]; J = Int[]
    @inbounds for (a,b) in pairs_set
        push!(I, a); push!(J, b)
        push!(I, b); push!(J, a)
    end
    raw = sparse(I, J, trues(length(I)), F, F)
    zero_diag!(raw)
    return raw, left_w, right_w
end

# Build all PURE layers with witnesses
# Managers
MM2_bool, mm2_shared_firm = mm2_with_witness()
mm_layers = Dict{Int,SparseMatrixCSC{Bool,Int}}(2 => MM2_bool)
mm_left   = Dict{Int,Dict{Tuple{Int,Int},Int}}(2 => Dict{Tuple{Int,Int},Int}())
mm_right  = Dict{Int,Dict{Tuple{Int,Int},Int}}(2 => Dict{Tuple{Int,Int},Int}())
for (key, j) in mm2_shared_firm
    mm_left[2][key]  = j
    mm_right[2][key] = j
end
mm_prev_reach = copy(MM2_bool)

# Firms
FF2_bool, ff2_shared_mgr = ff2_with_witness()
ff_layers = Dict{Int,SparseMatrixCSC{Bool,Int}}(2 => FF2_bool)
ff_left   = Dict{Int,Dict{Tuple{Int,Int},Int}}(2 => Dict{Tuple{Int,Int},Int}())
ff_right  = Dict{Int,Dict{Tuple{Int,Int},Int}}(2 => Dict{Tuple{Int,Int},Int}())
for (key, i) in ff2_shared_mgr
    ff_left[2][key]  = i
    ff_right[2][key] = i
end
ff_prev_reach = copy(FF2_bool)

# Higher even layers
for n in 4:2:MAX_N
    # managers
    raw_mm, left_w_mm, right_w_mm = compose_mm_layer(mm_layers[n-2], mm_left[n-2],
                                                     MM2_bool, mm2_shared_firm, M)
    raw_mm = raw_mm .| raw_mm' ; zero_diag!(raw_mm)
    pure_mm = raw_mm .& .!mm_prev_reach
    mm_layers[n] = pure_mm

    pure_left  = Dict{Tuple{Int,Int},Int}()
    pure_right = Dict{Tuple{Int,Int},Int}()
    I,J,_ = findnz(pure_mm)
    @inbounds for t in eachindex(I)
        a = I[t]; b = J[t]; if a >= b; continue; end
        key = (a,b)
        pure_left[key]  = left_w_mm[key]
        pure_right[key] = right_w_mm[key]
    end
    mm_left[n]  = pure_left
    mm_right[n] = pure_right
    mm_prev_reach .= mm_prev_reach .| raw_mm

    # firms
    raw_ff, left_w_ff, right_w_ff = compose_ff_layer(ff_layers[n-2], ff_left[n-2],
                                                     FF2_bool, ff2_shared_mgr, F)
    raw_ff = raw_ff .| raw_ff' ; zero_diag!(raw_ff)
    pure_ff = raw_ff .& .!ff_prev_reach
    ff_layers[n] = pure_ff

    pure_left_f  = Dict{Tuple{Int,Int},Int}()
    pure_right_f = Dict{Tuple{Int,Int},Int}()
    I2,J2,_ = findnz(pure_ff)
    @inbounds for t in eachindex(I2)
        a = I2[t]; b = J2[t]; if a >= b; continue; end
        key = (a,b)
        pure_left_f[key]  = left_w_ff[key]
        pure_right_f[key] = right_w_ff[key]
    end
    ff_left[n]  = pure_left_f
    ff_right[n] = pure_right_f
    ff_prev_reach .= ff_prev_reach .| raw_ff
end

# Output writers (use witnesses to fetch endpoint-edge values)
function write_wide_pairs_managers(n::Int, B::SparseMatrixCSC{Bool,Int},
                                   left_w::Dict{Tuple{Int,Int},Int},
                                   right_w::Dict{Tuple{Int,Int},Int},
                                   outpath::String)
    if nnz(B) == 0
        CSV.write(outpath, DataFrame()); return
    end
    id1 = Int[]; id2 = Int[]
    frame1 = Int[]; frame2 = Int[]
    T1 = Vector{Union{Int,Missing}}(); lnR1 = Vector{Union{Float64,Missing}}(); lnY1 = Vector{Union{Float64,Missing}}(); lnL1 = Vector{Union{Float64,Missing}}()
    T2 = Vector{Union{Int,Missing}}(); lnR2 = Vector{Union{Float64,Missing}}(); lnY2 = Vector{Union{Float64,Missing}}(); lnL2 = Vector{Union{Float64,Missing}}()

    I,J,_ = findnz(B)
    @inbounds for t in eachindex(I)
        a = I[t]; b = J[t]
        if a >= b; continue; end
        key = (a,b)
        jl = left_w[key]   # firm col index adjacent to manager a
        jr = right_w[key]  # firm col index adjacent to manager b
        mL = manager_ids[a]; mR = manager_ids[b]
        fL = firm_ids[jl];  fR = firm_ids[jr]

        v1 = edge_vals(mL, fL)
        v2 = edge_vals(mR, fR)

        push!(id1, mL); push!(id2, mR)
        push!(frame1, fL); push!(frame2, fR)
        push!(T1, v1.T); push!(lnR1, v1.lnR); push!(lnY1, v1.lnY); push!(lnL1, v1.lnL)
        push!(T2, v2.T); push!(lnR2, v2.lnR); push!(lnY2, v2.lnY); push!(lnL2, v2.lnL)
    end

    out = DataFrame(person_id_1 = id1, person_id_2 = id2,
                    frame_id_numeric_1 = frame1, frame_id_numeric_2 = frame2,
                    T_1 = T1, lnR_1 = lnR1, lnY_1 = lnY1, lnL_1 = lnL1,
                    T_2 = T2, lnR_2 = lnR2, lnY_2 = lnY2, lnL_2 = lnL2)
    CSV.write(outpath, out)
end

function write_wide_pairs_firms(n::Int, B::SparseMatrixCSC{Bool,Int},
                                left_w::Dict{Tuple{Int,Int},Int},
                                right_w::Dict{Tuple{Int,Int},Int},
                                outpath::String)
    if nnz(B) == 0
        CSV.write(outpath, DataFrame()); return
    end
    id1 = Int[]; id2 = Int[]
    mgr1 = Int[]; mgr2 = Int[]
    T1 = Vector{Union{Int,Missing}}(); lnR1 = Vector{Union{Float64,Missing}}(); lnY1 = Vector{Union{Float64,Missing}}(); lnL1 = Vector{Union{Float64,Missing}}()
    T2 = Vector{Union{Int,Missing}}(); lnR2 = Vector{Union{Float64,Missing}}(); lnY2 = Vector{Union{Float64,Missing}}(); lnL2 = Vector{Union{Float64,Missing}}()

    I,J,_ = findnz(B)
    @inbounds for t in eachindex(I)
        a = I[t]; b = J[t]
        if a >= b; continue; end
        key = (a,b)
        il = left_w[key]   # manager row index adjacent to firm a
        ir = right_w[key]  # manager row index adjacent to firm b
        fL = firm_ids[a];  fR = firm_ids[b]
        mL = manager_ids[il]; mR = manager_ids[ir]

        v1 = edge_vals(mL, fL)
        v2 = edge_vals(mR, fR)

        push!(id1, fL); push!(id2, fR)
        push!(mgr1, mL); push!(mgr2, mR)
        push!(T1, v1.T); push!(lnR1, v1.lnR); push!(lnY1, v1.lnY); push!(lnL1, v1.lnL)
        push!(T2, v2.T); push!(lnR2, v2.lnR); push!(lnY2, v2.lnY); push!(lnL2, v2.lnL)
    end

    out = DataFrame(frame_id_numeric_1 = id1, frame_id_numeric_2 = id2,
                    person_id_1 = mgr1, person_id_2 = mgr2,
                    T_1 = T1, lnR_1 = lnR1, lnY_1 = lnY1, lnL_1 = lnL1,
                    T_2 = T2, lnR_2 = lnR2, lnY_2 = lnY2, lnL_2 = lnL2)
    CSV.write(outpath, out)
end

# Build & write
MM2_bool, mm2_shared_firm = mm2_with_witness()
FF2_bool, ff2_shared_mgr  = ff2_with_witness()

mm_layers = Dict{Int,SparseMatrixCSC{Bool,Int}}(2 => MM2_bool)
ff_layers = Dict{Int,SparseMatrixCSC{Bool,Int}}(2 => FF2_bool)

mm_left   = Dict{Int,Dict{Tuple{Int,Int},Int}}(2 => Dict{Tuple{Int,Int},Int}())
mm_right  = Dict{Int,Dict{Tuple{Int,Int},Int}}(2 => Dict{Tuple{Int,Int},Int}())

for (key, j) in mm2_shared_firm
    mm_left[2][key]  = j
    mm_right[2][key] = j
end

ff_left   = Dict{Int,Dict{Tuple{Int,Int},Int}}(2 => Dict{Tuple{Int,Int},Int}())
ff_right  = Dict{Int,Dict{Tuple{Int,Int},Int}}(2 => Dict{Tuple{Int,Int},Int}())

for (key, i) in ff2_shared_mgr
    ff_left[2][key]  = i
    ff_right[2][key] = i
end

mm_prev_reach = copy(MM2_bool)
ff_prev_reach = copy(FF2_bool)

for n in 4:2:MAX_N
    raw_mm, left_w_mm, right_w_mm = compose_mm_layer(mm_layers[n-2], mm_left[n-2],
                                                     MM2_bool, mm2_shared_firm, M)
    raw_mm = raw_mm .| raw_mm' ; zero_diag!(raw_mm)
    pure_mm = raw_mm .& .!mm_prev_reach
    mm_layers[n] = pure_mm
    mm_prev_reach .= mm_prev_reach .| raw_mm

    pure_left  = Dict{Tuple{Int,Int},Int}()
    pure_right = Dict{Tuple{Int,Int},Int}()
    I,J,_ = findnz(pure_mm)
    @inbounds for t in eachindex(I)
        a = I[t]; b = J[t]; if a >= b; continue; end
        key = (a,b)
        pure_left[key]  = left_w_mm[key]
        pure_right[key] = right_w_mm[key]
    end

    mm_left[n]  = pure_left
    mm_right[n] = pure_right

    raw_ff, left_w_ff, right_w_ff = compose_ff_layer(ff_layers[n-2], ff_left[n-2],
                                                     FF2_bool, ff2_shared_mgr, F)
    raw_ff = raw_ff .| raw_ff' ; zero_diag!(raw_ff)
    pure_ff = raw_ff .& .!ff_prev_reach
    ff_layers[n] = pure_ff
    ff_prev_reach .= ff_prev_reach .| raw_ff

    pure_left_f  = Dict{Tuple{Int,Int},Int}()
    pure_right_f = Dict{Tuple{Int,Int},Int}()
    I2,J2,_ = findnz(pure_ff)
    @inbounds for t in eachindex(I2)
        a = I2[t]; b = J2[t]; if a >= b; continue; end
        key = (a,b)
        pure_left_f[key]  = left_w_ff[key]
        pure_right_f[key] = right_w_ff[key]
    end
    ff_left[n]  = pure_left_f
    ff_right[n] = pure_right_f
end

for n in sort(collect(keys(mm_layers)))
    outpath = "$(OUT_DIR)/mm_pure_$(n)hop.csv"
    write_wide_pairs_managers(n, mm_layers[n], mm_left[n], mm_right[n], outpath)
end

for n in sort(collect(keys(ff_layers)))
    outpath = "$(OUT_DIR)/ff_pure_$(n)hop.csv"
    write_wide_pairs_firms(n, ff_layers[n], ff_left[n], ff_right[n], outpath)
end

println("Wrote PURE manager–manager and firm–firm CSVs for even steps up to $(MAX_N). Endpoint lnR/lnY/lnL are taken from the exact witnessing edges.")