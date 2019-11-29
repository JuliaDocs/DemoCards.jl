@testset "AbstractDemoCard" begin
    for cardtype in ("markdown", "julia")
        cd(joinpath("assets", "card", cardtype)) do
            include("$(cardtype).jl")
        end
    end
end
