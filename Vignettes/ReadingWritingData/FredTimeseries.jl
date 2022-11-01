using FredData, StatsPlots, GLM, DataFrames, DataFramesMeta, Dates, StatsBase, Printf

FredKey = "e84c6fe87657a98c3cc9d406e28bb6d5"

fr = Fred(FredKey)

ngdppc = get_data(fr,"A939RC0Q052SBEA") #nominal dollars GDP/capita

rgdppc = get_data(fr,"A939RX0Q048SBEA") # real gdp/capita

cpid = get_data(fr,"CPIAUCSL")

gdpdefl = get_data(fr,"GDPDEF")


@df rgdppc.data plot(:date,log.(:value))

#gdpdata = rgdppc.data
#gdpdata = @select(leftjoin(ngdppc.data,cpid.data; on = :date,makeunique = true),
#    :date = :date, :gdppc = :value, :cpi = :value_1)

gdpdata = @select(leftjoin(ngdppc.data,gdpdefl.data; on = :date,makeunique = true),
    :date = :date, :gdppc = :value, :cpi = :value_1)


gdpdata.logcpi = log.(gdpdata.cpi)
gdpdata.loggdp = log.(gdpdata.gdppc)

gdpdata.years = (gdpdata.date - Date(1985,1,1))/Day(365)

gdpdata.realloggdp = log.(gdpdata.gdppc) - log.(gdpdata.cpi)


@df gdpdata plot(:date,:realloggdp;legend=:topleft,label="log(GDP/CPI)",title="GDP growth",xlab="Date",ylab="log(GDP/CPI)")
coefrates = 
let r = Float64[], c = Float64[],
    dvals = Float64[];
    for d in 1945:10:2015
        dat = @subset(gdpdata,:date .> Date(d,1,1) .&& :date .< Date(d+10,1,1))
        @show dat
        dat.years = dat.years .- mean(dat.years)
        mod = @df dat lm(@formula(realloggdp ~ years), dat)
        @show coef(mod)
        push!(r,coef(mod)[2])
        push!(c,coef(mod)[1])
        push!(dvals,d)
    end
    DataFrame(days=dvals,rates=r,levels=c)
end

let x = [], y=[];
    for r in eachrow(coefrates)
        push!(x,Date(r.days,1,1))
        push!(x,Date(r.days+10,1,1))
        push!(y,r.levels - r.rates*5)
        push!(y,r.levels + r.rates*5)
        push!(x,Date(r.days+10,1,1)); push!(y,Inf); #creates a gap in plot
    end
    plot!(x,y; label="Rate Estimate")
    annotate!(Date.(coefrates.days,1,1) .+ Year(5),coefrates.levels .+ .1,[text(@sprintf("%.1f%%",v*100)) for v in coefrates.rates ])
    plot!()
end
