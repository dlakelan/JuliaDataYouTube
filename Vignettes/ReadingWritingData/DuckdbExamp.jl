using DuckDB, CSV, DataFrames, DataFramesMeta, Dates, StatsPlots, Downloads

## we'll read in the same stuff from CSVArrowExamples but we'll do some SQL queries on the data

if !ispath("NWSSSarsCov2WastewaterConc.csv")
    Downloads.download("https://data.cdc.gov/api/views/g653-rqe2/rows.csv?accessType=DOWNLOAD","NWSSSarsCov2WastewaterConc.csv")
    Downloads.download("https://data.cdc.gov/api/views/2ew6-ywp6/rows.csv?accessType=DOWNLOAD","NWSSSarsCov2WastewaterMetr.csv")
end

@time wwdat = CSV.read("NWSSSarsCov2WastewaterConc.csv",DataFrame; types=[String,Date,Float64,String])


# create a duckdb connection to an in-memory database

con = DBInterface.connect(DuckDB.DB,":memory:")

# add the wwdat dataframe as a data source for the database (does not copy)

DuckDB.register_data_frame(con,wwdat,"wastewater")

# run query directly against wwdat dataframe, get result and convert to 
# data frame for further use

res = DBInterface.execute(con,"select * from wastewater where date > '2022-11-01' and pcr_conc_smoothed not NULL") |> DataFrame

# plot based on the returned data.

@df res scatter(:date,:pcr_conc_smoothed)

