maindir = "../../"
src     = maindir * "src/"

import Pkg
Pkg.activate(maindir * "devel/")

include(src * "problem.jl")
include(src * "risk_models.jl")
include(src * "algo.jl")
include(src * "ub.jl")

include("hydro_hist.jl")
beta = 0.2
lambda = 0.3
niters = [50, 100, 80]

nstages = Hydro_Hist.nstages
inivol  = Hydro_Hist.inivol

risk      = mk_primal_avar(beta; lambda=lambda)
risk_dual = mk_copersp_avar(beta; lambda=lambda)

import Gurobi
env = Gurobi.Env()
solver = JuMP.optimizer_with_attributes(() -> Gurobi.Optimizer(env), "OutputFlag" => 0)
# import GLPK
# solver = GLPK.Optimizer
# 

# Solution algorithms
# Pure primal
@time primal_pb, primal_trajs, primal_lbs = primalsolve(Hydro_Hist.M, nstages, risk, solver, inivol, niters[1]; verbose=true)

# Pure dual
# Currently not working: with more scenarios does not show progress
using Random: seed!
seed!(1)
@time dual_pb, dual_ubs = dualsolve(Hydro_Hist.M, nstages, risk_dual, solver, inivol, niters[2]; verbose=true)

# Primal with interior bounds
# Currently not working: sometimes the state escapes the convex hull
#seed!(2)
#primal_pb, primal_trajs, primal_lbs, primal_aux, Ubs = primalsolve(Hydro_Hist.M, nstages, risk, solver, inivol, niters[3]; verbose=true, ub=true)

import PyPlot as plt
plt.figure(figsize=(6,4));
plt.plot(dual_ubs, label="Upper bounds");
plt.plot(primal_lbs, label="Lower bounds");
plt.xlabel("iteration #");
plt.legend();
plt.savefig("bounds.pdf");

plt.yscale("log");
plt.savefig("bounds_semilog.pdf");

plt.figure(figsize=(6,4));
plt.semilogy(dual_ubs./primal_lbs .- 1);
plt.xlabel("iteration #");
plt.title("Relative gap");
plt.savefig("gap.pdf");

import NPZ
NPZ.npzwrite("bounds.npz", lb=primal_lbs, ub=dual_ubs);
