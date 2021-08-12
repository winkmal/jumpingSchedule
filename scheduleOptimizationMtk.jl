# Script to test ModelingToolkit/Optimization in Julia on schedule optimization problem (MILP)
# The idea here is to build the (nonlinear) model with ModelingToolkit (MTK), than pass it to another package for optimization. Probably cannot be done as mixed-integer.
# Main difference is that efficiency will be a function of x, rather than a constant parameter!
using ModelingToolkit, LinearAlgebra, Plots
import CSV, DataFrames, Tables

const problemSize   = 24*3                          # can go up to 216

# Assumptions about CHP(s)
P_inst_chpus        = [250; 500]                    # kW
P_inst              = sum(P_inst_chpus)             # kW          
P_bem               = 375                           # kW
eta_el              = [0.38; 0.41]                  # Only under full-load! Gives weighted average of 0.40
heatValMeth         = 9.97                          # kWh/m³
q_ch4_mean_nom      = P_bem/eta_el[2]/heatValMeth   # m³/h, assuming bigger CHP is more efficient
#powerQuotient       = P_inst/P_bem 
numOfChps           = length(P_inst_chpus)          # Assuming n *unequally* sized CHPs

# Define constraints
meanStorageTime     = 4  # h
V_ch4_gross_nrm     = q_ch4_mean_nom*meanStorageTime  # Gross norm. CH4 volume
V_ch4_min           = 0.05*1.19*V_ch4_gross_nrm     # m³
V_ch4_max           = 0.85*1.19*V_ch4_gross_nrm     # m³
V_ch4_lim           = [V_ch4_min V_ch4_max]         # m³
initMethVol 	    = 0.23*V_ch4_gross_nrm          # m³  

@variables V_ch4_GS[1:problemSize] revenue 
@parameters x[1:problemSize*numOfChps] epexPrices[1:problemSize*numOfChps]

# Objective for this optimization comes from European Power Exchange (EPEX) prices
epexPriceT          = CSV.read("Input_Output_Plots/epexPrices2019.csv", DataFrames.DataFrame, delim=";", header=false, dateformat="d-model-Y")
cols                = 3:3+problemSize-1
# Using line=2 or 14 as it contains also negative prices!!!
epexPriceVect       = [epexPriceT[12, col] for col in cols] # DataFrameRow to Vector

# Define objective function: Prices scaled according to each CHP's power
epexPriceVectMilp   = reshape((epexPriceVect*reshape(P_inst_chpus, 1, :))/P_inst, :, 1)

eqs = [revenue      ~ sum(epexPrices.*x),
       V_ch4_GS     ~ initMethVol .+ cumsum(ones(problemSize)*q_ch4_mean_nom - chpuOptMatrix*methFlowrateChpus)]

#lossFun             = -sum(epexPriceVectMilp.*x)

