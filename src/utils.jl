
@inline function allequal(x)
    length(x) < 2 && return true
    e1 = x[1]
    @inbounds for i in 2:length(x)
        x[i] == e1 || return false
    end
    return true
end