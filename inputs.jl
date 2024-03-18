using CSV, DataFrames

# Inputs Manuais
    G = 100                                                            # Maximum Generation/Quantity | Unit: MW
    priceDAOffer = [-1.8 5.3 15.3 19.6 22.7 26.2 31.8 40.1 53.2 96]    # Day Ahead Price - Biddings  | Unit: $/MWh    
    root_folder = "inputs"
    cluster = "365"

    # root_folder = "clusterizacao"
    # priceDAOffer = [-4.2 -1.6 0.2 3.4 8.9 14.2 17.8 21.6 25.9 37.2]                  # Day Ahead Price - Biddings  | Unit: $/MWh     
    # priceDAOffer = [5.7 16.3 19.5 21.6 23.9 26.3 29.9 35.3 44.2 68.2]              # Day Ahead Price - Biddings  | Unit: $/MWh     
    # priceDAOffer = [15.9 21.8 26.1 32.5 38.6 45.3 52.6 62.1 82.5 346.7]    # Day Ahead Price - Biddings  | Unit: $/MWh    
    # cluster = "Cluster3"
#

# Real-Time Price - DataFrame
    priceRT_file = "$root_folder/Price-Real-Time-$cluster.csv"
    priceRT_df   = CSV.read(priceRT_file, DataFrame; drop=[:1])
    priceRT_df   = coalesce.(priceRT_df, 0)
    priceRT      = Matrix(priceRT_df)
#

# Day-Ahead Price - DataFrame
    priceDA_file = "$root_folder/Price-Day-Ahead-$cluster.csv"
    priceDA_df   = CSV.read(priceDA_file, DataFrame; drop=[:1])
    priceDA_df   = coalesce.(priceDA_df, 0)
    priceDA      = Matrix(priceDA_df)
#

# Number of scenarios, bids, hours    
    nScen  = size(priceDA)[1]           # Number of scenarios | Unit: Scalar (One-Dimensional)
    nHours = size(priceDA)[2]           # Number of bids      | Unit: Scalar (One-Dimensional)
    nBids  = size(priceDAOffer)[2]      # Number of bids      | Unit: Scalar (One-Dimensional)
#

# Real-Time Price - Average 
    # avgPriceRT = zeros(24)
    # for ih in 1:24
    #     avgPriceRT[ih]     = sum((priceRT_df[s,ih]) for s in 1:nScen) ./ nScen
# end

# Real-Time Generation - DataFrame
    genRT_file = "$root_folder/Generation-Real-Time-$cluster.csv"
    genRT_df   = CSV.read(genRT_file, DataFrame; drop=[:1])
    genRT_df   = coalesce.(genRT_df, 0)
    genRT      = Matrix(genRT_df)
    # Normalizando
    genRT = genRT .* 100 ./ maximum(vec(genRT))
#

# Real-Time Generation - Average
    avgGenRT = zeros(nScen,24)
    for ih in 1:24
        avgGenRT[:,ih] .= sum((genRT[s,ih]) for s in 1:size(genRT)[1]) ./ size(genRT)[1]
    end 
#