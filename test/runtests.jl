using DemoCards
using DemoCards: DemoPage, generate
using Test
using ReferenceTests

# use include("runtests.jl") instead of include("test/runtests.jl")

@testset "DemoCards.jl" begin
    @test_nowarn page = DemoPage("demos_1")
    @test_nowarn DemoPage("demos_2")

    @testset "render result" begin
        page = DemoPage("demos_1")
        # .md format isn't supported by FileIO
        @test_reference "references/section.txt" page.sections[1]
        @test_reference "references/page.txt" page
        @test_reference "references/generate_section.txt" generate(page.sections[1])
        @test_reference "references/generate_page.txt" generate(page)
    end
end

nothing
