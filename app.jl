using JuMP, CSV, DataFrames, Plots, Distributions

include("inputs.jl")
include("functions.jl")

# Análise 1 - Otimização de receita esperada considerando geração média do ativo na liquidação RT.
# Espera-se que, sempre que a média do preço RT for acima do preço DA, não haverá oferta de quantidade no DA, deixando toda liquidação da energia para o RT. 

    objFct_1       = Array{AffExpr}(undef, nBids)
    revenueDA_1    = zeros(nScen, nHours);
    revenueRT_1    = zeros(nScen, nHours);
    offerCurve_1   = zeros(nHours, nBids);
    objValue_1     = zeros(nBids);
    CVaR           = CVaR_param(0.5, 0.5)

    avgGenRT = avgMatrix(genRT, size(genRT)[1], size(genRT)[2]);

    for iOffer in 1:nBids

        # Resultado da otimização
        qDA, objFct_1[iOffer], objValue_1[iOffer] = optimalOffer(G, avgGenRT, priceRT, priceDAOffer[iOffer], CVaR)
        
        # Curva de oferta para cada bid simulado
        offerCurve_1[:,iOffer] = JuMP.value.(qDA[:])

    end

    # Receita DA e RT da primeira análise
        revenueDA_1[:,:] =  calcRevenue(avgGenRT, priceRT, priceDA, priceDAOffer, offerCurve_1);
        revenueRT_1[:,:] =  calcRevenue(avgGenRT, priceRT, priceDA, zeros(nBids), zeros(nHours));

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
        
        revDA_1 = sumMatrix(revenueDA_1, nScen, nHours)
        revRT_1 = sumMatrix(revenueRT_1, nScen, nHours)
            
        # Revenue difference per scenario (sorted)
        plot(sort(revDA_1 .- revRT_1))
    #

    # Printing results
    # CSV.write("revenueDA_1.csv", DataFrame(revenueDA_1, :auto))
    # CSV.write("revenueRT_1.csv", DataFrame(revenueRT_1, :auto))
    #

#

# Análise 2 - Com o objetivo de maximar a quantidade ofertada olhando a geracao horaria no Real-Time
# Visto que a geração do RT multiplica somente o preço no RT, independetemente da correl negativa, o resultado não é alterado série a série (contudo, há um efeito de deslocamento da curva)
    objFct_2       = Array{AffExpr}(undef, nBids)
    revenueDA_2    = zeros(nScen, nHours);
    revenueRT_2    = zeros(nScen, nHours);
    offerCurve_2   = zeros(nHours, nBids);
    objValue_2     = zeros(nBids);
    CVaR           = CVaR_param(0.5, 0.90)

    for iOffer in 1:nBids

        # Resultado da otimização
        qDA, objFct_2[iOffer], objValue_2[iOffer] = optimalOffer(G, genRT, priceRT, priceDAOffer[iOffer], CVaR)

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
        iOffer = 7
        avgPriceRT = avgMatrix(priceRT, size(priceRT)[1], size(priceRT)[2])[1,:]
        plot(ones(24).*priceDAOffer[iOffer])
        plot!(avgPriceRT)
        plot!(offerCurve_2[:,iOffer] ,seriestype = [:scatter])
        plot!(avgGenRT[1,:])

        revDA_2 = sumMatrix(revenueDA_2, nScen, nHours)
        revRT_2 = sumMatrix(revenueRT_2, nScen, nHours)
        
        # Revenue difference per scenario (sorted)
        plot(sort(revDA_2 .- revRT_2))
    #

    # Printing results
    # CSV.write("revenueDA_2.csv", DataFrame(revenueDA_2, :auto))
    # CSV.write("revenueRT_2.csv", DataFrame(revenueRT_2, :auto))
    #

    # Auxiliar: Cálculo de Correlação 
    correl = zeros(24)
    ruido_gen   = genRT - avgGenRT
    ruido_preco = priceRT - avgMatrix(priceRT, size(genRT)[1], size(genRT)[2])
    for ih in 1:24
        correl[ih] = sum((ruido_gen[:,ih] .- mean(ruido_gen[:,ih])).*(ruido_preco[:,ih] .- mean(ruido_preco[:,ih]))) / (std(ruido_gen[:,ih]) * std(ruido_preco[:,ih])) / nScen    
    end
#

# Exporting all results
excelFileName = "results_cvar_50_50_20_Scen"
exportExcel(excelFileName, genRT, priceRT, priceDA, priceDAOffer, offerCurve_1, offerCurve_2, revenueDA_1, revenueRT_1, revenueDA_2, revenueRT_2, objValue_1, objValue_2)

# Results summary
    resultsDA_1 = describeStatistcs(revenueDA_1)
    resultsRT_1 = describeStatistcs(revenueRT_1)
    resultsDA_2 = describeStatistcs(revenueDA_2)
    resultsRT_2 = describeStatistcs(revenueRT_2)
#
