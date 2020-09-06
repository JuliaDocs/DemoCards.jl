if v"1.0" <= VERSION < v"1.1"
    isnothing(x) = x===nothing
end

if VERSION < v"1.4"
    pkgdir(pkg) = abspath(@__DIR__, "..")
end
