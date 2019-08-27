using DemoCards
using DemoCards: democard, MarkdownDemoCard, DemoSection, DemoPage
using Test
using ReferenceTests

# support both `include("runtests.jl")` and `include("test/runtests.jl")`
test_root = basename(pwd()) == "test" ? pwd() : joinpath(pwd(), "test")

include("types/card.jl")
include("types/section.jl")
include("types/page.jl")

include("generate.jl")
include("show.jl")
include("utils.jl")

nothing
