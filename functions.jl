using GLPK, DataFrames, Statistics

function optimalOffer(G, genRT, priceRT, priceDAOffer, iOffer)

    m = Model(GLPK.Optimizer)
    
    # qDA = Asset's Day-Ahead Generation Offered - Variable Decision 
    @variable(m, 0 <= qDA[h in 1:24] <= G)
    @objective(m, Max, sum((priceDAOffer[iOffer] * qDA[h] + 1/nScen * sum((priceRT[s,h] * (genRT[s,h] - qDA[h])) for s in 1:nScen)) for h in 1:24))

    optimize!(m)
    termination_status(m)
    objective_value(m)
    
    return qDA
end

function calcRevenue(revenue, priceRT, genRT, priceDAOffer, qDA, iOffer, priceDA)

    revenue[:, iOffer] = sum(
        (
            qDA[iOffer]  .* (priceDAOffer[iOffer] .<= priceRT[:,ih]) .* JuMP.value(qDA[ih]) .+ 
            priceRT[:,ih] .* (genRT[:,ih] .- JuMP.value(qDA[ih]))
        ) 
        for ih in 1:24)
    a = zeros(24)
    for ih = 1:24
        a[ih] = sum((priceDAOffer .<= priceDA[1,:])[ih,:])
    end

    return revenue[:, iOffer]
end

function describeStatistcs(matrix)
    # Creating a DataFrame to hold the descriptive statistics
    stats_df = DataFrame(
        Mean = mean(matrix, dims=1)[:],
        Minimum = minimum(matrix, dims=1)[:],
        Maximum = maximum(matrix, dims=1)[:],
        Std_Dev = std(matrix, dims=1)[:],
        P5 = [quantile(matrix[:, i], 0.05) for i = 1:size(matrix, 2)],
        P95 = [quantile(matrix[:, i], 0.95) for i = 1:size(matrix, 2)]
    )

    return stats_df
end