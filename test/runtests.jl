using DemoCards
using Test
using ReferenceTests

@testset "DemoCards.jl" begin
    demo_root = "demos"
    page = DemoPage(demo_root)

    # .md format isn't supported by FileIO
    @test_reference "references/section.txt" page.sections[1]
    @test_reference "references/page.txt" page
    @test_reference "references/generate_section.txt" generate(page.sections[1])
    @test_reference "references/generate_page.txt" generate(page)
end

nothing
