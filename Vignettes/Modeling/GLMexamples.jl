using DataFrames, DataFramesMeta, GLM, MixedModels, RDatasets, StatsPlots, CategoricalArrays

RDatasets.datasets("lme4")

ss = RDatasets.dataset("lme4","sleepstudy")

@df ss scatter(:Days,:Reaction)


## Run a basic linear regression using GLM.lm 

mm = lm(@formula(Reaction ~ 1+Days),ss)


## consider each subject separately using a MixedModels

mm2 = LinearMixedModel(@formula(Reaction ~ 1+Days + (1+Days|Subject)),ss)
fit!(mm2)

p = @df ss plot(:Days,:Reaction,group=:Subject, title="Reaction time vs Days sleep deprived",xlab="Days",ylab="Reaction Time",legend=false)

subs = unique(ss.Subject)

p = plot(;title="Reaction time vs Days sleep deprived",legend=false)
for s in subs
    preds = predict(mm2,DataFrame(Days=[0,8],Reaction=[1.0,1.0],Subject=CategoricalVector([s,s])))
    p=plot!([0,8],preds; linewidth=3)
end
display(p)

fixef(mm2)
rane