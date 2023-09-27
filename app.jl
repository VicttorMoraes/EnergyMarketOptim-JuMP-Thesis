using JuMP, GLPK, CSV, DataFrames, Plots, Distributions

include("inputs.jl")
include("model.jl")


# Análise 1 - Com o objetivo de maximar a quantidade ofertada olhando a media de geracao horaria no Real-Time 
    revenue_1    = zeros(nScen, nBids)
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
    end
#


# Análise 2 - Com o objetivo de maximar a quantidade ofertada olhando a geracao horaria no Real-Time 
revenue_2    = zeros(nScen, nBids)
revenue_3    = zeros(nScen, nBids)

offerCurve_2 = zeros(24, nBids)

for iOffer in 1:nBids

    qDA = optimalOffer(G, genRT, priceRT, priceDA, iOffer)
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
#

# Plots
    aux = 7
    plot(offerCurve_1[:,aux])
    plot!(offerCurve_2[:,aux])
    
    histogram(revenue_1[:,4],xlims=(-5*10^5,5*10^5))
    histogram!(revenue_2[:,4],xlims=(-5*10^5,5*10^5))
    histogram!(revenue_3[:,4])

# Revenue Average
    mean(revenue_1)
    mean(revenue_2)
    mean(revenue_3)
