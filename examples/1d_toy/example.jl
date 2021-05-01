maindir = "../../"
src     = maindir * "src/"

import Pkg
Pkg.activate(maindir)

include(src * "problem.jl")
include(src * "risk_models.jl")
include(src * "algo.jl")
include(src * "ub.jl")

include("hydro_conf.jl")
include("hydro.jl")


risk      = mk_primal_avar(beta)
risk_dual = mk_copersp_avar(beta)

primal_pb = mk_primal_decomp(Hydro1d.M, nstages, risk)
dual_pb   = mk_dual_decomp(Hydro1d.M, nstages, risk_dual)


# import Gurobi
# env = Gurobi.Env()
# solver = () -> Gurobi.Optimizer(env)
import GLPK
solver = GLPK.Optimizer

for m in primal_pb
  JuMP.set_optimizer(m, solver)
end
for m in dual_pb
  JuMP.set_optimizer(m, solver)
end

println("********")
println(" PRIMAL ")
println("********")
println("Forward-backward Iterations")
for i = 1:niters
  forward(primal_pb, [inivol])
  backward(primal_pb)
  println("Iteration $i: LB = ", JuMP.objective_value(primal_pb[1]))
end
println()

println("********")
println("  DUAL  ")
println("********")
println("Forward-backward Iterations")
init_dual(dual_pb, [inivol])
for i = 1:niters
  forward_dual(dual_pb)
  backward_dual(dual_pb)
  println("Iteration $i: UB = ", -JuMP.objective_value(dual_pb[1]))
end
println()

primal_pb = mk_primal_decomp(Hydro1d.M, nstages, risk)
stages    = mk_primal_decomp(Hydro1d.M, nstages, risk)
for m in primal_pb
  JuMP.set_optimizer(m, solver)
end
for m in stages
  JuMP.set_optimizer(m, solver)
end
traj = forward_backward(primal_pb, niters, [inivol]; return_traj = true)
Ubs = convex_ub(stages,traj)
println("Recursive upper bounds on $niters trajectories")
Ubs