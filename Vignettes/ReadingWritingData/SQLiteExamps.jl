## How to interact with SQLite databases

using SQLite, DataFrames, DataFramesMeta, CSV, HTTP, Downloads, Dates

Downloads.download("https://www.fdic.gov/bank/individual/failed/banklist.csv","failedbanks.csv")
df = CSV.read("failedbanks.csv", DataFrame)

# this results in some weird names for the columns because the file has extra invalid characters in the names
# let's clean that up by dropping the last character in each string except "Fund" which has no extra character,
# and replace spaces with underscores

names(df)

rename!(x -> x == "Fund" ? x : replace(x[1:end-1]," " => "_"),df)

# the data in the Closing_Date column is crappy formatted 2 digit year garbage it's hard to believe people still do... 
# SQLite.jl will store dates as serialized objects, but what we want is printed text in YYYY-MM-DD format. Let's convert it

df.Closing_Date = string.(Date.(df.Closing_Date, dateformat"d-u-y" ) .+ Year(2000))

## Now let's create a SQLite database and upload this as a table

rm("temp.db")
db = SQLite.DB("temp.db")

SQLite.load!(df, db,"failedbanks")

# check to see if the table is there... it is
println(SQLite.tables(db))

## select the number of banks that closed between 2008-10-1 and 2009-10-1

res = DBInterface.execute(db,"select count(*) from failedbanks where Closing_Date > '2008-10-01' and Closing_Date < '2009-10-01'")
count = res |> DataFrame



