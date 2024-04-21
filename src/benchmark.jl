include("Brag.jl")

using BenchmarkTools

@benchmark comboTypes(Hand("Qh6c4d"))
@benchmark comboTypesS(Hand("Qh6c4d"))