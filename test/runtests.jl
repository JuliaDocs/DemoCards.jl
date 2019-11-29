using DemoCards
using DemoCards: democard, MarkdownDemoCard, JuliaDemoCard, DemoSection, DemoPage
using DemoCards: generate
using Test, ReferenceTests, Suppressor

# support both `include("runtests.jl")` and `include("test/runtests.jl")`
test_root = basename(pwd()) == "test" ? "." : "test"

cd(test_root) do
    include("types/card.jl")
    include("types/section.jl")
    include("types/page.jl")

    include("generate.jl")
    include("show.jl")
    include("utils.jl")
end

@test_nowarn begin
    # increase test coverage
    @info "test documentation generation"
    cd(joinpath(test_root, "..")) do
        if Sys.isunix()
            @suppress rum(`julia --project=docs/ docs/make.jl`)
        elseif Sys.iswindows()
            @suppress run(`julia.exe --project=docs/ docs/make.jl`)
        end
    end
end

nothing
