# Small script to test Cbc in Julia on schedule optimization problem (MILP)
# Learning directly from the JuMP tutorials how things are done
using JuMP, Plots
import Cbc, CSV, DataFrames

# Preparing an optimization model
model       = Model(Cbc.Optimizer)

problemSize = 24  # can go up to 216
@variable(model, 0 <= x[1:problemSize] <= 1, Int) # Binary decision variable vector

# Objective for this optimization comes from European Power Exchange (EPEX) prices
epexPriceT  = CSV.read("epexPrices2019.csv", DataFrames.DataFrame, delim=";", header=false, dateformat="d-model-Y")
cols        = 3:3+problemSize-1
# Using line=2 or 14 (for the trivial example) as it contains also negative prices!!!
epexPriceVect = [epexPriceT[14, col] for col in cols] # DataFrameRow to Vector

@objective(model, Max, sum(epexPriceVect.*x)) # sum(epexPriceVect[i]*x[i] for i=1:problemSize))

# Without the proper constraints, the solution to this example it trivial!
# It will just choose all hours with prices > 0
# @constraint(model, constraint[j=1:2], sum(A[j,i]*x[i] for i=1:3) <= b[j])
# @constraint(model, bound, x[1] <= 10)
 
# Call the optimizer
optimize!(model)
# Plot the (trivial) solution 
plot(value.(x), linetype=:steppre)
