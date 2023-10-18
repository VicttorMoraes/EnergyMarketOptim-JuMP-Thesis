using GLPK, DataFrames, Statistics

struct  CVaR_param
    λ
    α
end

function optimalOffer(G, gRT, priceRT, offerPrice, CVaR)
    
    nScen = size(gRT)[1]
    λ = CVaR.λ    
    α = CVaR.α

    m = Model(GLPK.Optimizer)

    # qDA = Asset's Day-Ahead Generation Offered - Variable Decision 
    @variable(m, 0 <= qDA[h in 1:24] <= G)

    # Variáveis do CVaR
    @variable(m, δ[h in 1:24] >= 0)
    @variable(m, z[h in 1:24])
    
    # Restrição do CVaR
    @constraint(m, [h in 1:24], δ .>= z .- 1/nScen * sum((priceRT[s,h] * (gRT[s,h] - qDA[h])) for s in 1:nScen))
    
    @objective(m, Max, sum(offerPrice * qDA[:] .+ (1 - λ) * 1/nScen * sum((priceRT[s,:] .* (gRT[s,:] .- qDA[:])) for s in 1:nScen) .+ λ * (z .- δ / (1-α))))

    optimize!(m)
    termination_status(m)
    objFct = objective_value(m)
    
    return qDA, objFct
end

function calcRevenue(genRT, priceRT, priceDA, priceDAOffer, offerCurve_1)
    # Calculates the final revenue considering 

    nScen = size(priceRT)[1]
    nHours = size(priceRT)[2]
    revenue = zeros(nScen, nHours);
    for s in 1:nScen
        for ih in 1:nHours
            revenue[s, ih] += sum(offerCurve_1[ih,:] .* transpose(priceDAOffer .<= priceDA[s, ih])) * priceDA[s,ih] +
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

function sumMatrix(matrixData, x, y)
    # Matrix data must be (x, y). It returns the sum of x scenarios per y columns.
    sumMatrix = zeros(x)
    for d in 1:x
        sumMatrix[d] = sum(matrixData[d, h] for h in 1:y)
    end
    
    return sumMatrix
end