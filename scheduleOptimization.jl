# Small script to test Cbc in Julia on schedule optimization problem (MILP)
# Learning directly from the JuMP tutorials how things are done
using JuMP, LinearAlgebra, Plots
import Cbc, CSV, DataFrames

# Preparing an optimization model
model               = Model(Cbc.Optimizer)

const problemSize   = 24                            # can go up to 216
@variable(model, 0 <= x[1:problemSize] <= 1, Int)   # Binary decision variable vector

# Objective for this optimization comes from European Power Exchange (EPEX) prices
epexPriceT          = CSV.read("epexPrices2019.csv", DataFrames.DataFrame, delim=";", header=false, dateformat="d-model-Y")
cols                = 3:3+problemSize-1
# Using line=2 or 14 as it contains also negative prices!!!
epexPriceVect       = [epexPriceT[14, col] for col in cols] # DataFrameRow to Vector
# Define objective function
@objective(model, Max, sum(epexPriceVect.*x)) # sum(epexPriceVect[i]*x[i] for i=1:problemSize))

# Assumptions about CHP(s)
q_ch4_mean_nom      = 85.15                         # m³/h
powerQuotient       = 2
methFlowrateChpuMax = q_ch4_mean_nom*powerQuotient  # m³/h

# Define constraints
meanStorageTime   	= 8  # h
V_ch4_gross_nrm    	= q_ch4_mean_nom*meanStorageTime  # Gross norm. CH4 volume
V_ch4_min        	= 0.05*V_ch4_gross_nrm          # m³
V_ch4_max           = 0.85*V_ch4_gross_nrm          # m³
V_ch4_lim           = [V_ch4_min V_ch4_max]         # m³

# Heuristic assumption for initial methane volume of MILP: Only 23 % of gross volume
initMethVol 	    = 0.23*V_ch4_gross_nrm          # m³  
# Inequality Constraint: Lower + upper gasholder volume
A_milp_lgl          = methFlowrateChpuMax*tril(ones(problemSize,problemSize))
A_milp_ugl          = -A_milp_lgl  
b_milp_lgl          = cumsum(ones(problemSize)*q_ch4_mean_nom) .+ initMethVol .- V_ch4_lim[1] 
b_milp_ugl          = V_ch4_lim[2] .- initMethVol .- cumsum(ones(problemSize)*q_ch4_mean_nom)  
# Summarize all inequality constraints
A_milp              = [A_milp_lgl;  A_milp_ugl]  
b_milp              = [b_milp_lgl;  b_milp_ugl]  
# Add constraint to optimization problem
@constraint(model, constraint[j=1:problemSize],  A_milp*x .<= b_milp)
 
# Call the optimizer
optimize!(model)
# Plot the solution 
plot!(methFlowrateChpuMax.*value.(x), linetype=:steppre)
plot!(initMethVol .+ cumsum(ones(problemSize)*q_ch4_mean_nom - methFlowrateChpuMax.*value.(x))) 
