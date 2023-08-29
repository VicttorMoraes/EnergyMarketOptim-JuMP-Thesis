# Real-Time Price - DataFrame
    priceRT_file = "Price-Real-Time-2023.csv"
    priceRT_df   = CSV.read(priceRT_file, DataFrame; drop=[:1])
    priceRT_df   = coalesce.(priceRT_df, 0)
    priceRT      = Matrix(priceRT_df)
#

# Inputs
    G = 100                                     # Maximum Generation/Quantity | Unit: MW
    priceDA = [0 10 20 30 40 50 60 70 80 90]    # Day Ahead Price - Biddings  | Unit: $/MWh         
    nScen = size(priceRT)[1]                    # Number of scenarios         | Unit: Scalar (One-Dimensional)
    nBids = size(priceDA)[2]                    # Number of bids              | Unit: Scalar (One-Dimensional)
#

# Real-Time Price - Average 
    # avgPriceRT = zeros(24)
    # for ih in 1:24
    #     avgPriceRT[ih]     = sum((priceRT_df[s,ih]) for s in 1:nScen) ./ nScen
# end

# Real-Time Price - Hourly Average 
avgPriceRT = zeros(24,nScen)
for ih in 1:24
    avgPriceRT[:,ih]    .= sum((priceRT_df[s,ih]) for s in 1:nScen) ./ nScen
end
#

# Real-Time Generation - DataFrame
    genRT_file = "Generation-Real-Time-2023.csv"
    genRT_df   = CSV.read(genRT_file, DataFrame; drop=[:1])
    genRT_df   = coalesce.(genRT_df, 0)
    genRT      = Matrix(genRT_df)
    # Normalizando
    genRT = genRT .* 100 ./ maximum(vec(genRT))
#

