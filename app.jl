using JuMP, GLPK, CSV, DataFrames, Plots, Distributions

# Inputs
G = 100                                     # Maximum Generation/Quantity | Unit: MW
priceDA = [0 10 20 30 40 50 60 70 80 90]    # Day Ahead Price - Biddings  | Unit: $/MWh
nBids = size(priceDA)[2]                    # Number of bids              | Unit: Scalar

# Real-Time Price - DataFrame
priceRT_file = "Price-Real-Time-2023.csv"
priceRT_df   = CSV.read(priceRT_file, DataFrame; drop=[:1])
priceRT_df   = coalesce.(priceRT_df, 0)
priceRT      = Matrix(priceRT_df)

# Number of scenarios 
nScen = size(priceRT_df)[1]                 # Number of scenarios | Unit: Scalar (One-Dimensional)

# Real-Time Price - Average 
# avgPriceRT = zeros(24)
# for ih in 1:24
#     avgPriceRT[ih]     = sum((priceRT_df[s,ih]) for s in 1:nScen) ./ nScen
# end

# Real-Time Price - Hourly Average 
avgPriceRT = zeros(24,nScen)
for ih in 1:24
    avgPriceRT[:,ih]    .= sum((priceRT_df[s,ih]) for s in 1:nScen) ./ nScen
end

# Real-Time Generation - DataFrame
genRT_file = "Generation-Real-Time-2023.csv"
genRT_df   = CSV.read(genRT_file, DataFrame; drop=[:1])
genRT_df   = coalesce.(genRT_df, 0)
genRT      = Matrix(genRT_df)

# Normalizando
genRT = genRT .* 100 ./ maximum(vec(genRT))

# Análise 1 - Com o objetivo de maximar a quantidade ofertada olhando a media de geracao horaria no Real-Time 
avgGenRT = zeros(nScen,24)
for ih in 1:24
    avgGenRT[:,ih] .= sum((genRT_df[s,ih]) for s in 1:size(genRT_df)[1]) ./ size(genRT_df)[1]
end 

nScen = size(priceRT)[1]
nBids = size(priceDA)[2]
revenue_1    = zeros(nScen, nBids)
offerCurve_1 = zeros(24, nBids)
for iOffer in 1:nBids

    m = Model(GLPK.Optimizer)

    # qDA = Asset's Day-Ahead Generation Offered - Variable Decision 
    @variable(m, 0 <= qDA[h in 1:24] <= G)
    @objective(m, Max, sum((priceDA[iOffer] * qDA[h] + 1/nScen * sum((priceRT[s,h] * (avgGenRT[s,h] - qDA[h])) for s in 1:nScen)) for h in 1:24))

    optimize!(m)
    termination_status(m)
    objective_value(m)    
    offerCurve_1[:,iOffer] = JuMP.value.(qDA[:])
    revenue_1[:, iOffer] = sum(
        (
            priceDA[iOffer] .* (priceDA[iOffer] .<= priceRT[:,ih]) .* JuMP.value(qDA[ih]) .+ 
            priceRT[:,ih] .* (avgGenRT[:,ih] .- JuMP.value(qDA[ih]))
        ) 
        for ih in 1:24)
end

# Análise 2 - Com o objetivo de maximar a quantidade ofertada olhando a geracao horaria no Real-Time 
revenue_2    = zeros(nScen, nBids)
offerCurve_2 = zeros(24, nBids)
for iOffer in 1:nBids

    m = Model(GLPK.Optimizer)

    # qDA = Asset's Day-Ahead Generation Offered - Variable Decision 
    @variable(m, 0 <= qDA[h in 1:24] <= G)
    @objective(m, Max, sum((priceDA[iOffer] * qDA[h] + 1/nScen * sum((priceRT[s,h] * (genRT[s,h] - qDA[h])) for s in 1:nScen)) for h in 1:24))

    optimize!(m)
    termination_status(m)
    objective_value(m)    
    offerCurve_2[:,iOffer] = JuMP.value.(qDA[:])
    revenue_2[:, iOffer] = sum(
        (
            priceDA[iOffer] .* (priceDA[iOffer] .<= priceRT[:,ih]) .* JuMP.value(qDA[ih]) .+ 
            priceRT[:,ih] .* (genRT[:,ih] .- JuMP.value(qDA[ih]))
        ) 
        for ih in 1:24)
end

function calcOfferCurve(G, genRT, priceRT, priceDA)
    
    nScen = size(priceRT)[1]
    nBids = size(priceDA)[2]
    offerCurve = zeros(24, nBids)
    for iOffer in 1:nBids

        m = Model(GLPK.Optimizer)
    
        # qDA = Asset's Day-Ahead Generation Offered - Variable Decision 
        @variable(m, 0 <= qDA[h in 1:24] <= G)
        @objective(m, Max, sum((priceDA[iOffer] * qDA[h] + 1/nScen * sum((priceRT[s,h] * (genRT[s,h] - qDA[h])) for s in 1:nScen)) for h in 1:24))
    
        optimize!(m)
        termination_status(m)
        objective_value(m)    
        offerCurve[:,iOffer] = JuMP.value.(qDA[:])
    end
    return offerCurve
end

function calcRevenue(G, genRT, priceRT, priceDA)
    
    nScen = size(priceRT)[1]
    nBids = size(priceDA)[2]
    revenue    = zeros(nScen, nBids)
    offerCurve = zeros(24, nBids)
    for iOffer in 1:nBids

        m = Model(GLPK.Optimizer)
    
        # qDA = Asset's Day-Ahead Generation Offered - Variable Decision 
        @variable(m, 0 <= qDA[h in 1:24] <= G)
        @objective(m, Max, sum((priceDA[iOffer] * qDA[h] + 1/nScen * sum((priceRT[s,h] * (genRT[s,h] - qDA[h])) for s in 1:nScen)) for h in 1:24))
    
        optimize!(m)
        termination_status(m)
        objective_value(m)    
        offerCurve[:,iOffer] = JuMP.value.(qDA[:])
        revenue[:, iOffer] = sum((priceDA[iOffer] .* JuMP.value(qDA[ih]) .+ priceRT[:,ih] .* ( genRT[:,ih] .- JuMP.value(qDA[ih]) )) for ih in 1:24)
    end
    return revenue
end

# function calcRevenue(G, genRT, priceRT, priceDA, )
    
#     nScen = size(priceRT)[1]
#     nBids = size(priceDA)[2]
#     revenue    = zeros(nScen, nBids)
#     offerCurve = zeros(24, nBids)
#     for iOffer in 1:nBids

#         m = Model(GLPK.Optimizer)
    
#         # qDA = Asset's Day-Ahead Generation Offered - Variable Decision 
#         @variable(m, 0 <= qDA[h in 1:24] <= G)
#         @objective(m, Max, sum((priceDA[iOffer] * qDA[h] + 1/nScen * sum((priceRT[s,h] * (genRT[s,h] - qDA[h])) for s in 1:nScen)) for h in 1:24))
    
#         optimize!(m)
#         termination_status(m)
#         objective_value(m)    
#         offerCurve[:,iOffer] = JuMP.value.(qDA[:])
#         revenue[:, iOffer] = sum((priceDA[iOffer] .* JuMP.value(qDA[ih]) .+ priceRT[:,ih] .* ( genRT[:,ih] .- JuMP.value(qDA[ih]) )) for ih in 1:24)
#     end
#     return revenue
# end

offerCurve = calcOfferCurve(G, genRT, priceRT, priceDA)
revenueRT  = calcRevenue(G, genRT, priceRT, priceDA)
sum(revenueRT)

# aux = 7
# plot(offerCurve[:,aux])
# plot!(avgPriceRT)
# priceAux = ones(24) * priceDA[aux]
# plot!(priceAux)

# println("Terminou")