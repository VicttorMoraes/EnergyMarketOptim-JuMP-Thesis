using JuMP, GLPK, CSV, DataFrames, Plots, Distributions

include("inputs.jl")
include("functions.jl")

# Análise 1 - Com o objetivo de maximar a quantidade ofertada olhando a media de geracao horaria no Real-Time 
    revenue_1    = zeros(nScen, nBids)
    revenue_2    = zeros(nScen, nBids)
    offerCurve_1 = zeros(24, nBids)

    for iOffer in 1:nBids

        qDA = optimalOffer(G, avgGenRT, priceRT, priceDAOffer, iOffer)
        offerCurve_1[:,iOffer] = JuMP.value.(qDA[:])
        revenue_1[:, iOffer] = calcRevenue(revenue_1, priceRT, avgGenRT, priceDAOffer, qDA, iOffer, priceDA)
        revenue_2[:, iOffer] = calcRevenue(revenue_1, priceRT, avgGenRT, zeros(10), zeros(24), iOffer, priceDA)

    end
#

# Análise 2 - Com o objetivo de maximar a quantidade ofertada olhando a geracao horaria no Real-Time 
    revenue_3    = zeros(nScen, nBids)
    revenue_4    = zeros(nScen, nBids)

    offerCurve_2 = zeros(24, nBids)

    for iOffer in 1:nBids

        qDA = optimalOffer(G, genRT, priceRT, priceDAOffer, iOffer)
        offerCurve_2[:,iOffer] = JuMP.value.(qDA[:])
        revenue_3[:, iOffer] = calcRevenue(revenue_3, priceRT, genRT, priceDAOffer, qDA, iOffer)
        revenue_4[:, iOffer] = calcRevenue(revenue_4, priceRT, genRT, zeros(10), zeros(24), iOffer)

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