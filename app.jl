using JuMP, GLPK, CSV, DataFrames, Plots, Distributions

include("inputs.jl")
include("functions.jl")

# Análise 1 - Com o objetivo de maximar a quantidade ofertada olhando a media de geracao horaria no Real-Time 
    revenueDA_1    = zeros(nScen,  nBids)
    revenueRT_1    = zeros(nScen,  nBids)
    offerCurve_1   = zeros(nHours, nBids)

    for iOffer in 1:nBids

        # Resultado da otimização
        qDA = optimalOffer(G, avgGenRT, priceRT, priceDAOffer[iOffer])
        
        # Curva de oferta para cada bid simulado
        offerCurve_1[:,iOffer] = JuMP.value.(qDA[:])

        # Receita DA e RT da primeira análise
        revenueDA_1[:, iOffer] = calcRevenue(avgGenRT, priceRT, priceDA, priceDAOffer[iOffer], qDA)
        revenueRT_1[:, iOffer] = calcRevenue(avgGenRT, priceRT, priceDA, zeros(nBids)[iOffer], zeros(nHours))

    end
#

# Análise 2 - Com o objetivo de maximar a quantidade ofertada olhando a geracao horaria no Real-Time 
    revenueDA_2    = zeros(nScen,  nBids)
    revenueRT_2    = zeros(nScen,  nBids)
    offerCurve_2   = zeros(nHours, nBids)

    for iOffer in 1:nBids

        # Resultado da otimização
        qDA = optimalOffer(G, genRT, priceRT, priceDAOffer[iOffer])

        # Curva de oferta para cada bid simulado
        offerCurve_2[:,iOffer] = JuMP.value.(qDA[:])

        # Receita DA e RT da segunda análise
        revenueDA_2[:, iOffer] = calcRevenue(genRT, priceRT, priceDA, priceDAOffer[iOffer], qDA)
        revenueRT_2[:, iOffer] = calcRevenue(genRT, priceRT, priceDA, zeros(nBids)[iOffer], zeros(nHours))

    end
#

# Results
    resultsDA_1 = describeStatistcs(revenueDA_1)
    resultsRT_1 = describeStatistcs(revenueRT_1)
    resultsDA_2 = describeStatistcs(revenueDA_2)
    resultsRT_2 = describeStatistcs(revenueRT_2)
#