using DemoCards
using DemoCards: democard, MarkdownDemoCard, DemoSection, DemoPage
using DemoCards: generate
using Test, ReferenceTests, Suppressor

# support both `include("runtests.jl")` and `include("test/runtests.jl")`
test_root = basename(pwd()) == "test" ? "" : "test"

cd(test_root) do
    include("types/card.jl")
    include("types/section.jl")
    include("types/page.jl")

    include("generate.jl")
    include("show.jl")
    include("utils.jl")
end

nothing
