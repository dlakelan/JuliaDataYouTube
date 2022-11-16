
using CSV, DataFrames, DataFramesMeta, Downloads, StatsPlots, Dates, StatsBase


if !ispath("NWSSSarsCov2WastewaterConc.csv")
    Downloads.download("https://data.cdc.gov/api/views/g653-rqe2/rows.csv?accessType=DOWNLOAD","NWSSSarsCov2WastewaterConc.csv")
    Downloads.download("https://data.cdc.gov/api/views/2ew6-ywp6/rows.csv?accessType=DOWNLOAD","NWSSSarsCov2WastewaterMetr.csv")
end

wwdat = CSV.read("NWSSSarsCov2WastewaterConc.csv",DataFrame; types=[String,Date,Float64,String])

dropmissing!(wwdat)
#wwdat = @orderby(wwdat,:date)

# plots borks on the "SentinelArrays" produced by CSV.read, we convert these to simple vectors
wwdat = copy(wwdat) ## causes the columns to be copied to vectors


wwbydat = @orderby(@by(wwdat,:date,:meanconc = mean(:pcr_conc_smoothed)),:date)


@df wwbydat plot(:date,:meanconc/1e6; xlab="Date",ylab="Millions Copies/ml", title="Mean Concentration of Virus across Active Sites",legend=false)


@df wwbydat plot(:date,:meanconc/1e6; xlab="Date",ylab="Millions Copies/ml", 
    title="Mean Concentration of Virus across Active Sites", legend=false,
    xticks =  let ds =Date(2020,01,01):Month(2):Date(2022,10,1)
            (ds, Dates.format.(ds,"yyyy-mm-dd"))
    end,
    xrotation = 90)


