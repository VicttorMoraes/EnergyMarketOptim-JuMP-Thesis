using GLPK

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