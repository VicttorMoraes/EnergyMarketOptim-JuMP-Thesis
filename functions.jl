using GLPK, DataFrames, Statistics

function optimalOffer(G, gRT, priceRT, offerPrice)
    
    m = Model(GLPK.Optimizer)
    
    nScen = size(gRT)[1]

    # qDA = Asset's Day-Ahead Generation Offered - Variable Decision 
    @variable(m, 0 <= qDA[h in 1:24] <= G)

    @objective(m, Max, sum((offerPrice * qDA[h] + 1/nScen * sum((priceRT[s,h] * (gRT[s,h] - qDA[h])) for s in 1:nScen)) for h in 1:24))

    optimize!(m)
    termination_status(m)
    objective_value(m)
    
    return qDA, objFct
end

function calcRevenue(genRT, priceRT, priceDA, priceDAOffer, offerCurve_1)
    # Calculates the final revenue considering 

    nScen = size(priceRT)[1]
    revenue = zeros(nScen);
    for s in 1:nScen
        for ih in 1:24
            revenue[s] += sum(offerCurve_1[ih,:] .* transpose(priceDAOffer .<= priceDA[s, ih])) * priceDA[s,ih] +
                priceRT[s, ih] * (genRT[s,ih] - sum(offerCurve_1[ih,:] .* transpose(priceDAOffer .<= priceDA[s, ih])))
        end
    end

    return revenue
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


function avgMatrix(matrixData, x, y)
    # Matrix data must be (x, y). It returns the average of x scenarios per y columns.
    
    avgMatrix = zeros(x, y)
    for ih in 1:y
        avgMatrix[:,ih] .= sum((matrixData[s, ih]) for s in 1:x) ./ x
    end

    return avgMatrix
end

