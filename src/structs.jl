# Helper types
State = Vector{Float64}
DualState = Tuple{Float64, Vector{Float64}}

# Multi-Stage Linear Bellman Operator
#   A,B,T,c,d are functions of (time, branch)
#   Ux, Uy are functions of time
#   lb, ub, Lip are functions of (time, Horizon)
#   prob is a function of time
struct MSLBO
  A :: Function # Ax_t + Bx_{t-1} + Ty = d
  B :: Function
  T :: Function
  c :: Function # marginal cost of y_t
  d :: Function
  Ux :: Function # upper bound on the positive state x
  Uy :: Function # upper bound on the positive control y
  lb :: Function # lower bound at each stage
  ub :: Function # upper bound on the value of the problem
  Lip :: Function # upper bound on the Lipschitz constant
  prob :: Function # reference probability over branches
end

struct PrimalCut
  value :: Float64
  slope :: Vector{Float64}
  x0    :: Vector{Float64}
end

struct DualCut
  value   :: Float64
  slope_π :: Vector{Float64}
  slope_γ :: Float64
  π0      :: Vector{Float64}
  γ0      :: Float64
end
