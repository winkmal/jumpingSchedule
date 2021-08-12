# Small script to test Cbc in Julia on schedule optimization problem (MILP)
# Learning directly from the JuMP tutorials how things are done
using JuMP, LinearAlgebra, Plots
import Cbc, CSV, DataFrames, Tables

const problemSize   = 24*3                          # can go up to 216

# Preparing an optimization model
model               = Model(optimizer_with_attributes(Cbc.Optimizer, "maxNodes" => problemSize*1000))
set_optimizer_attribute(model, "threads", 4)

# Objective for this optimization comes from European Power Exchange (EPEX) prices
epexPriceT          = CSV.read("Input_Output_Plots/epexPrices2019.csv", DataFrames.DataFrame, delim=";", header=false, dateformat="d-model-Y")
cols                = 3:3+problemSize-1
# Using line=2 or 14 as it contains also negative prices!!!
epexPriceVect       = [epexPriceT[12, col] for col in cols] # DataFrameRow to Vector

# Assumptions about CHP(s)
P_inst_chpus        = [250; 500]                    # kW
P_inst              = sum(P_inst_chpus)             # kW          
P_bem               = 375                           # kW
eta_el              = [0.38; 0.41]                  # gives weighted average of 0.40
heatValMeth         = 9.97                          # kWh/m³
q_ch4_mean_nom      = P_bem/eta_el[2]/heatValMeth   # m³/h, assuming bigger CHP is more efficient
#powerQuotient       = P_inst/P_bem 
#methFlowrateChpuMax = q_ch4_mean_nom*powerQuotient  # m³/h
numOfChps           = length(P_inst_chpus)          # Assuming n *unequally* sized CHPs
@variable(model, 0 <= x[1:problemSize*numOfChps] <= 1, Int)   # Binary decision variable vector

methFlowrateChpus   = P_inst_chpus./eta_el/heatValMeth
# Define constraints
meanStorageTime     = 4  # h
V_ch4_gross_nrm     = q_ch4_mean_nom*meanStorageTime  # Gross norm. CH4 volume
V_ch4_min           = 0.05*1.19*V_ch4_gross_nrm     # m³
V_ch4_max           = 0.85*1.19*V_ch4_gross_nrm     # m³
V_ch4_lim           = [V_ch4_min V_ch4_max]         # m³

# Heuristic assumption for initial methane volume of MILP: Only 23 % of gross volume
initMethVol 	    = 0.23*V_ch4_gross_nrm          # m³  
# Inequality Constraint: Lower + upper gasholder volume
A_milp_lgl          = hcat(methFlowrateChpus[1]*tril(ones(problemSize,problemSize)), methFlowrateChpus[2]*tril(ones(problemSize,problemSize)))
A_milp_ugl          = -A_milp_lgl  
b_milp_lgl          = cumsum(ones(problemSize)*q_ch4_mean_nom) .+ initMethVol .- V_ch4_lim[1] 
b_milp_ugl          = V_ch4_lim[2] .- initMethVol .- cumsum(ones(problemSize)*q_ch4_mean_nom)  
# Summarize all inequality constraints
A_milp              = [A_milp_lgl;  A_milp_ugl]  
b_milp              = [b_milp_lgl;  b_milp_ugl]  
# Add constraint to optimization problem
@constraint(model, constraint[j=1:problemSize],  A_milp*x .<= b_milp)
# Define objective function: Prices scaled according to each CHP's power
epexPriceVectMilp   = reshape((epexPriceVect*reshape(P_inst_chpus, 1, :))/P_inst, :, 1)

@objective(model, Max, sum(epexPriceVectMilp.*x)) # sum(epexPriceVect[i]*x[i] for i=1:problemSize))
 
# Call the optimizer
optimize!(model)
chpuOptMatrix       = reshape(value.(x), :, numOfChps)
# Plot the solution 
plot(epexPriceVect)                                     #, label="EPEX price (€/MWh)")
plot!(chpuOptMatrix*P_inst_chpus, linetype=:steppre)    #, label="CHP schedule")
plot!(initMethVol .+ cumsum(ones(problemSize)*q_ch4_mean_nom - chpuOptMatrix*methFlowrateChpus)) #, label="V_ch4_GS") 
# Additional: Write results to CSV file, so they can be easily diffed
resultsMatrix       = hcat(chpuOptMatrix, initMethVol .+ cumsum(ones(problemSize)*q_ch4_mean_nom - chpuOptMatrix*methFlowrateChpus), epexPriceVect)
CSV.write("Input_Output_Plots/resultsMatrix.csv", Tables.table(resultsMatrix), delim=";")
