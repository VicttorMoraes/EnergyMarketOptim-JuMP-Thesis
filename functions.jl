using GLPK, DataFrames, Statistics

function optimalOffer(G, genRT, priceRT, priceDA, iOffer)

    m = Model(GLPK.Optimizer)
    
    # qDA = Asset's Day-Ahead Generation Offered - Variable Decision 
    @variable(m, 0 <= qDA[h in 1:24] <= G)
    @objective(m, Max, sum((priceDA[iOffer] * qDA[h] + 1/nScen * sum((priceRT[s,h] * (genRT[s,h] - qDA[h])) for s in 1:nScen)) for h in 1:24))

    optimize!(m)
    termination_status(m)
    objective_value(m)
    
    return qDA
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