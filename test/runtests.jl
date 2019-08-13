using DemoCards
using Test
using ReferenceTests

# use include("runtests.jl") instead of include("test/runtests.jl")
demo_root = "demos"

@testset "DemoCards.jl" begin
    page = DemoPage(demo_root)

    # .md format isn't supported by FileIO
    @test_reference "references/section.txt" page.sections[1]
    @test_reference "references/page.txt" page
    @test_reference "references/generate_section.txt" generate(page.sections[1])
    @test_reference "references/generate_page.txt" generate(page)

    mktemp() do path, io
        generate(path, page)
        @test_reference "references/generate_page.txt" read(path, String)
        generate(io, page)
        @test_reference "references/generate_page.txt" read(path, String)
    end
end

nothing
