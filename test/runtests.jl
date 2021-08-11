using DemoCards
using DemoCards: democard, MarkdownDemoCard, JuliaDemoCard, DemoSection, DemoPage
using DemoCards: generate
using HTTP
using Test, ReferenceTests, Suppressor
using Dates

include("compat.jl")
include("testutils.jl")

# support both `include("runtests.jl")` and `include("test/runtests.jl")`
proj_root = basename(pwd()) == "test" ? abspath(pwd(), "..") : pwd()
test_root = joinpath(proj_root, "test")

cd(test_root) do
    include("types/card.jl")
    include("types/section.jl")
    include("types/page.jl")

    include("generate.jl")
    include("preview.jl")
    include("show.jl")
    include("utils.jl")

    include("configurations.jl")
end

nothing
