
#=
My kids were talking about how to find the area and circumference of circles in math
so I talked to them about how the length of a circle is pi * diameter by definition, but
how could we estimate what pi was? And how could we estimate the area of a circle?

Of course there are various series that converge to pi but these examples all Calculate
based on finding lengths or areas of circles directly.
=#


using Random,LinearAlgebra,QuadGK,Richardson,StatsPlots

"""
Calculates the area of a circle of radius 1 (by simulating random numbers in the unit [0,1]x[0,1] and 
determining if they lie inside the circle of diameter 1, then multiplies area by 4
"""
function circlearearand(n)
    y=0
    for i in 1:n
        if norm(rand(2) .- 0.5) < 0.5
            y+=1
        end
    end
    4*(y/n)
end


"""
Calculates area of a circle of radius 1 by use of quadgk numerical integration, integrates the upper region 
and multiplies by 2
"""
function circleareaquad()
    res = quadgk(x->sqrt(1.0-x^2),-1.0,1.0; rtol=1e-10,atol=1e-10)
    res .* 2
end


"""
Calculates the circumference of a circle of diameter 1 by integration of a series of small hypotenuses of
triangles determined by inscribed polygon figure
"""
function circlecircumpi(dh)
    y = 1.0
    l = 0.0
    for x in 0.0:dh:(1.0-dh)
        ynext = sqrt(1.0-x^2)
        dy = ynext-y
        y = ynext
        dl = dh * sqrt(1.0+(dy/dh)^2)
        l += dl
    end
    2.0*l
end


#="""
Graph how the above function converges to Pi near dx = 0. It clearly has a "square root" type
shape, so we can potentially do Richardson extrapolation to dx = 0 using power=1/2

"""=#


let xvals = [0.5e-6,1e-6, 2e-6, 4e-6, 8e-6,16e-6,32e-6,64e-6,128e-6],
    yvals = [circlecircumpi(x) for x in xvals]
    p1 = (plot(xvals,yvals; title="Circumference of circle with diameter 1 estimate",xlab="dx",ylab="Circumference"))
    display(p1)
end


## We do richardson extrapolation of the circlecircumpi function at dh = 0
## This accelerates the 


piest = extrapolate((x-> begin @show x; circlecircumpi(x); end),.0001; x0=0.0,rtol=1e-12,atol=1e-14,maxeval=14,power=1/2)
println(piest)
println("error is $(pi - piest[1])")

