using JuMP, GLPK, CSV, DataFrames, Plots, Distributions

include("inputs.jl")

revenue_1    = zeros(nScen, nBids)
offerCurve_1 = zeros(24, nBids)
# Análise 1 - Com o objetivo de maximar a quantidade ofertada olhando a media de geracao horaria no Real-Time 
avgGenRT = zeros(nScen,24)
for ih in 1:24
    avgGenRT[:,ih] .= sum((genRT[s,ih]) for s in 1:size(genRT)[1]) ./ size(genRT)[1]
end 
#
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
revenue_3    = zeros(nScen, nBids)

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

    revenue_3[:, iOffer] = sum(
        (
            priceRT[:,ih] .* (genRT[:,ih])
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



# offerCurve = calcOfferCurve(G, genRT, priceRT, priceDA)
# revenueRT  = calcRevenue(G, genRT, priceRT, priceDA)


# Plots
    aux = 7
    plot(offerCurve_1[:,aux])
    plot!(offerCurve_2[:,aux])
    
    histogram(revenue_1[:,4],xlims=(-5*10^5,5*10^5))
    histogram(revenue_2[:,4],xlims=(-5*10^5,5*10^5))
    histogram!(revenue_3[:,4])

# Revenue Average
    mean(revenue_2)
    mean(revenue_3)
