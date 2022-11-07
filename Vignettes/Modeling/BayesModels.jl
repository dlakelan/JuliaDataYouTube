
## Someone on the Julia Discourse asked if they have two data sets and each one is 
## a function y = f(x)  or in the second case y = a*f(x) + b, how to find the a,b to "stitch" the 
## two datasets together


using StatsPlots, Turing, LinearAlgebra,Random

Random.set_global_seed!(1)

f(x) = exp(-x^2)
x1 = randn(50) .- 1.0
x2 = randn(30) .+ 1.0
y1 = f.(x1) .+ rand(Normal(0.0,.05),length(x1))
y2 = 1.5*f.(x2) .+ 0.5 .+ rand(Normal(0.0,0.05),length(x2)) ## true values of a = 1.5 and b = 0.5

p1 = plot([x1, x2], [y1, y2]; seriestype=:scatter) # don't line up


display(p1)

## how to determine a,b if we don't know f()?

@model function stitchdata(xbase,ybase,xtform,ytform)
    a ~ Gamma(5,1.0/4) # a is of order 1
    b ~ Gamma(5,1.0/4) # b is of order 1
    m ~ MvNormal(repeat([0.0],4),100.0^2*I(4))
    c ~ MvNormal(repeat([0.0],4),100.0^2*I(4))
    xbneighs = Vector{eltype(xbase)}[]
    ybneighs = Vector{eltype(ybase)}[]
    xtneighs = Vector{eltype(xbase)}[]
    ytneighs = Vector{eltype(ybase)}[]
    centers = (-1.0,-0.5,.5,1.0)
    for (i,dx) in enumerate(centers)
        f = x -> x > dx - .25 && x < dx + 0.25
        xneighindex = findall(f, xbase)
        #@show xneighindex
        push!(xbneighs, xbase[xneighindex])
        push!(ybneighs, ybase[xneighindex])
        tneighindex = findall(f,xtform)
        push!(xtneighs, xtform[tneighindex])
        push!(ytneighs, ytform[tneighindex])
    end
    for (i,(x,y)) in enumerate(zip(xbneighs,ybneighs))
        Turing.@addlogprob!(logpdf(MvNormal(m[i].*(x .- centers[i]) .+ c[i], 0.05^2*I(length(y))), y))
    end
    for (i,(x,y)) in enumerate(zip(xtneighs,ytneighs))
        Turing.@addlogprob!(logpdf(MvNormal(a.*(m[i].*(x .- centers[i]) .+ c[i]) .+ b, 0.05^2*I(length(y))), y))
    end
end

mm = stitchdata(x1,y1,x2,y2)

s = sample(mm,NUTS(400,0.8),200)

plot(s[:,[:a,:b],1])


bumpfun(x) = x > -one(x) && x < one(x) ? exp(one(x) - one(x)/(one(x) - x^2)) : zero(x)


rbf(coefs,centers,scale,x) = sum(coef * bumpfun((x-c)/scale) for (coef,c) in zip(coefs,centers))



@model function stitchdata2(xbase,ybase,xtform,ytform,centers,s)
    err ~ Gamma(3.0,0.1/2.0)
    a ~ Normal(0.0,10.0)
    b ~ Normal(0.0,10.0)
    coefs ~ MvNormal(repeat([0.0],length(centers)),50.0^2*I(length(centers)))
    y1pred = rbf.(Ref(coefs),Ref(centers),s,xbase)
    y2pred = rbf.(Ref(coefs),Ref(centers),s,xtform)
    ybase ~ MvNormal(y1pred,err^2*I(length(ybase)))
    ytform ~ MvNormal(a.*y2pred .+ b,err^2*I(length(ytform)))
end


mod2 = stitchdata2(x1,y1,x2,y2,collect(-5:0.5:5),2.5)

s2 = sample(mod2,NUTS(400,0.8),200)


plot(s2[:,[:a,:b],1])

(meana , meanb) = (mean(s2[:,:a,1]),mean(s2[:,:b,1]))

scatter(x1,y1)
scatter!(x2,(y2 .- meanb)./meana)

