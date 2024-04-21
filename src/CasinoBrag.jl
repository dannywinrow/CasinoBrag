module CasinoBrag

using Cards
using Combinatorics

include("utils.jl")
include("constants.jl")
include("calcs.jl")
include("ev.jl")

function init()
    createLookup()
end

end