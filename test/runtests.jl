using DemoCards
using DemoCards: democard, MarkdownDemoCard, JuliaDemoCard, DemoSection, DemoPage
using DemoCards: generate
using HTTP
using Test, ReferenceTests, Suppressor

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
end


ENV["CI_TEST"] = false
mktempdir() do dirpath
    cp(joinpath(proj_root, "docs"), joinpath(dirpath, "docs"))
    chmod(dirpath, 0o777; recursive=true)
    cd(dirpath) do
        include(joinpath(dirpath, "docs/make.jl"))
    end
end

nothing
