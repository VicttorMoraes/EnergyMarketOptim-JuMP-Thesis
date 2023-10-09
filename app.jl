using JuMP, GLPK, CSV, DataFrames, Plots, Distributions

include("inputs.jl")
include("functions.jl")

# Análise 1 - Otimização de receita esperada considerando geração média do ativo na liquidação RT.
# Espera-se que, sempre que a média do preço RT for acima do preço DA, não haverá oferta de quantidade no DA, deixando toda liquidação da energia para o RT. 

    revenueDA_1    = zeros(nScen);
    revenueRT_1    = zeros(nScen);
    offerCurve_1   = zeros(nHours, nBids);
    objFct_1       = zeros(nBids)
    CVaR           = CVaR_param(0.5, 0.95)

    avgGenRT = avgMatrix(genRT, size(genRT)[1], size(genRT)[2]);

    for iOffer in 1:nBids

        # Resultado da otimização
        qDA, objFct_1[iOffer] = optimalOffer(G, avgGenRT, priceRT, priceDAOffer[iOffer], CVaR)
        
        # Curva de oferta para cada bid simulado
        offerCurve_1[:,iOffer] = JuMP.value.(qDA[:])

    end

    # Receita DA e RT da primeira análise
        revenueDA_1[:] = calcRevenue(avgGenRT, priceRT, priceDA, priceDAOffer, offerCurve_1);
        revenueRT_1[:] = calcRevenue(avgGenRT, priceRT, priceDA, zeros(nBids), zeros(nHours));

        benefit_1 = (mean(revenueDA_1) - mean(revenueRT_1)) / mean(revenueRT_1) * 100
        
        println("The benefit is: ", round(benefit_1), "%")
    #

    # Evaluating Results
        iOffer = 4
        avgPriceRT = avgMatrix(priceRT, size(priceRT)[1], size(priceRT)[2])[1,:]
        plot(ones(24).*priceDAOffer[iOffer])
        plot!(avgPriceRT)
        plot!(offerCurve_1[:,iOffer] ,seriestype = [:scatter])
        plot!(avgGenRT[1,:])
        

        # Revenue difference per scenario (sorted)
        plot(sort(revenueDA_1 .- revenueRT_1))
    #

    # Printing results

    #

#

# Análise 2 - Com o objetivo de maximar a quantidade ofertada olhando a geracao horaria no Real-Time
# Visto que a geração do RT multiplica somente o preço no RT, independetemente da correl negativa, o resultado não é alterado série a série (contudo, há um efeito de deslocamento da curva)
    revenueDA_2    = zeros(nScen)
    revenueRT_2    = zeros(nScen)
    offerCurve_2   = zeros(nHours, nBids)
    objFct_2       = zeros(nBids)
    CVaR           = CVaR_param(0.9, 0.95)

    for iOffer in 1:nBids

        # Resultado da otimização
        qDA, objFct_2[iOffer] = optimalOffer(G, genRT, priceRT, priceDAOffer[iOffer], CVaR)

        # Curva de oferta para cada bid simulado
        offerCurve_2[:,iOffer] = JuMP.value.(qDA[:])

    end

    # Receita DA e RT da segunda análise
        revenueDA_2[:] = calcRevenue(genRT, priceRT, priceDA, priceDAOffer, offerCurve_2)
        revenueRT_2[:] = calcRevenue(genRT, priceRT, priceDA, zeros(nBids), zeros(nHours))

        benefit_2 = (mean(revenueDA_2) - mean(revenueRT_2)) / mean(revenueRT_2) * 100
        
        println("The benefit is: ", round(benefit_2), "%")
    #

    # Evaluating Results
        iOffer = 4
        avgPriceRT = avgMatrix(priceRT, size(priceRT)[1], size(priceRT)[2])[1,:]
        plot(ones(24).*priceDAOffer[iOffer])
        plot!(avgPriceRT)
        plot!(offerCurve_2[:,iOffer] ,seriestype = [:scatter])
        plot!(avgGenRT[1,:])

        # Revneue difference per scenario (sorted)
        plot(sort(revenueDA_2 .- revenueRT_2))
    #

    # Auxiliar: Cálculo de Correlação 
    correl = zeros(24)
    ruido_gen   = genRT - avgGenRT
    ruido_preco = priceRT - avgMatrix(priceRT, size(genRT)[1], size(genRT)[2])
    for ih in 1:24
        correl[ih] = sum((ruido_gen[:,ih] .- mean(ruido_gen[:,ih])).*(ruido_preco[:,ih] .- mean(ruido_preco[:,ih]))) / (std(ruido_gen[:,ih]) * std(ruido_preco[:,ih])) / nScen    
    end
#

# Results
    resultsDA_1 = describeStatistcs(revenueDA_1)
    resultsRT_1 = describeStatistcs(revenueRT_1)
    resultsDA_2 = describeStatistcs(revenueDA_2)
    resultsRT_2 = describeStatistcs(revenueRT_2)
#