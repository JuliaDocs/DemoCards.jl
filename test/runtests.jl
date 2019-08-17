using DemoCards
using Test
using ReferenceTests

# use include("runtests.jl") instead of include("test/runtests.jl")

@testset "DemoCards.jl" begin
    @test_nowarn page = DemoPage("demos_1")
    @test_nowarn DemoPage("demos_2")

    page = DemoPage("demos_1")
    @testset "api" begin
        # generate(io, page) == generate(file, page)
        mktemp() do path, io
            generate(path, page)
            @test_reference "references/generate_page.txt" read(path, String)
            generate(io, page)
            @test_reference "references/generate_page.txt" read(path, String)
        end
    end

    @testset "render result" begin
        # .md format isn't supported by FileIO
        @test_reference "references/section.txt" page.sections[1]
        @test_reference "references/page.txt" page
        @test_reference "references/generate_section.txt" generate(page.sections[1])
        @test_reference "references/generate_page.txt" generate(page)
    end
end

nothing
