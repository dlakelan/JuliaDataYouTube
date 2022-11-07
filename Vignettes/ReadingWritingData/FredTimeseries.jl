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
    :date = :date, :gdppc = :value, :defl = :value_1)

gdpdata = @select(leftjoin(gdpdata,cpid.data; on = :date,makeunique=true), :date,:gdppc,:defl,:cpi = :value)


gdpdata.logcpi = log.(gdpdata.cpi)
gdpdata.loggdp = log.(gdpdata.gdppc)
gdpdata.loggdpdefl = log.(gdpdata.defl)

gdpdata.years = (gdpdata.date - Date(1985,1,1))/Day(365)


## Let's make two plots, one of log(GDP/CPI) and one of log(GDP/GDP_Deflator) and show 
## the rates of increases on a decade by decade basis


coefrates = 
let rc = Float64[], cc = Float64[], rg = Float64[],cg = Float64[],
    dvals = Float64[];
    for d in 1945:10:2015
        dat = @subset(gdpdata,:date .> Date(d,1,1) .&& :date .< Date(d+10,1,1))
        @show dat
        dat.years = dat.years .- mean(dat.years)
        mod = lm(@formula((loggdp - logcpi) ~ years), dat)
        @show coef(mod)
        push!(rc,coef(mod)[2])
        push!(cc,coef(mod)[1])
        mod = lm(@formula((loggdp - loggdpdefl) ~ years),dat)
        push!(rg,coef(mod)[2])
        push!(cg,coef(mod)[1])
        push!(dvals,d)
    end
    DataFrame(days=dvals,ratescpi=rc,levelscpi=cc,ratesgdp=rg,levelsgdp=cg)
end



# now let's plot two plots, one with GDP/GDPdeflator and one GDP/CPI

tickdates = [Date(y,1,1) for y in (1945:10:2015)]
ticks =(tickdates,Dates.format.(tickdates,"yyyy")) 

p1 = @df gdpdata plot(:date,:loggdp-:logcpi;legend=:topleft,label="log(GDP/CPI)",title="GDP growth by CPI",xlab="Date",ylab="log(GDP/CPI)",xticks=ticks,left_margin=10Plots.mm)
p2 = @df gdpdata plot(:date,:loggdp-:loggdpdefl;legend=:topleft,label="log(GDP/Deflator)",title="GDP growth by Deflator",xlab="Date",ylab="log(GDP/Deflator)",xticks=ticks,left_margin=10Plots.mm)
let x = [], y1=[],y2=[];
    for r in eachrow(coefrates)
        push!(x,Date(r.days,1,1))
        push!(x,Date(r.days+10,1,1))
        push!(y1,r.levelscpi - r.ratescpi*5)
        push!(y1,r.levelscpi + r.ratescpi*5)
        push!(y2,r.levelsgdp - r.ratesgdp*5)
        push!(y2,r.levelsgdp + r.ratesgdp*5)
        push!(x,Date(r.days+10,1,1)); push!(y1,Inf); push!(y2,Inf) #creates a gap in plot
    end
    plot!(p1,x,y1; label="Rate Estimate")
    annotate!(p1,Date.(coefrates.days,1,1) .+ Year(5),coefrates.levelscpi .+ .1,[text(@sprintf("%.1f%%",v*100)) for v in coefrates.ratescpi ])
    plot!(p2,x,y2; label="Rate Estimate")
    annotate!(p2,Date.(coefrates.days,1,1) .+ Year(5),coefrates.levelsgdp .+ .1,[text(@sprintf("%.1f%%",v*100)) for v in coefrates.ratesgdp ])
    plot(p1,p2; layout=(2,1),size=(800,1000))
end
