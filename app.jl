using JuMP, GLPK, CSV, DataFrames, Plots, Distributions

include("inputs.jl")
include("functions.jl")

# Análise 1 - Com o objetivo de maximar a quantidade ofertada olhando a media de geracao horaria no Real-Time 
    revenue_1    = zeros(nScen, nBids)
    revenue_2    = zeros(nScen, nBids)
    offerCurve_1 = zeros(24, nBids)

    for iOffer in 1:nBids

        qDA = optimalOffer(G, avgGenRT, priceRT, priceDA, iOffer)
        offerCurve_1[:,iOffer] = JuMP.value.(qDA[:])
        revenue_1[:, iOffer] = sum(
            (
                priceDA[iOffer] .* (priceDA[iOffer] .<= priceRT[:,ih]) .* JuMP.value(qDA[ih]) .+ 
                priceRT[:,ih] .* (avgGenRT[:,ih] .- JuMP.value(qDA[ih]))
            ) 
            for ih in 1:24)
                
        revenue_2[:, iOffer] = revenueOnlyRT(revenue_2, priceRT, genRT, iOffer)
    end
#

# Análise 2 - Com o objetivo de maximar a quantidade ofertada olhando a geracao horaria no Real-Time 
    revenue_3    = zeros(nScen, nBids)
    revenue_4    = zeros(nScen, nBids)

    offerCurve_2 = zeros(24, nBids)

    for iOffer in 1:nBids

        qDA = optimalOffer(G, genRT, priceRT, priceDA, iOffer)
        offerCurve_2[:,iOffer] = JuMP.value.(qDA[:])
        revenue_3[:, iOffer] = sum(
            (
                priceDA[iOffer] .* (priceDA[iOffer] .<= priceRT[:,ih]) .* JuMP.value(qDA[ih]) .+ 
                priceRT[:,ih] .* (genRT[:,ih] .- JuMP.value(qDA[ih]))
            ) 
            for ih in 1:24)

        revenue_4[:, iOffer] = revenueOnlyRT(revenue_4, priceRT, genRT, iOffer)
    end
#

# # Plots
#     aux = 7
#     plot(offerCurve_1[:,aux])
#     plot!(offerCurve_2[:,aux])
    
#     histogram(revenue_1[:,4],xlims=(-5*10^5,5*10^5))
#     histogram!(revenue_2[:,4],xlims=(-5*10^5,5*10^5))
#     histogram!(revenue_3[:,4])

# Results
    results_1 = describeStatistcs(revenue_1)
    results_2 = describeStatistcs(revenue_2)
    results_3 = describeStatistcs(revenue_3)
    results_4 = describeStatistcs(revenue_4)
#