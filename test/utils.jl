using DemoCards: democard

@testset "regexes" begin
    root = joinpath("assets", "regexes")

    @testset "title" begin
        config_1_files = ("example_1.md", "example_4.md", "example_6.md", "example_7.md",
                          "example_8.md", "example_1.jl", "example_4.jl", "example_5.jl",
                          "example_6.jl", "example_8.jl", "example_9.jl", "example_10.jl",
                          "example_11.jl", "example_12.jl", "example_13.jl")
        foreach(config_1_files) do filename
            card = democard(joinpath(root, filename))
            @test card.title == "This is a title"
            @test card.id == "This-is-a-title-1"
            @test card.description == "This is a description"
        end

        config_2_files =  ("example_2.md", "example_3.md", "example_2.jl", "example_3.jl")
        foreach(config_2_files) do filename
            card = democard(joinpath(root, filename))
            @test card.title == "This is a title"
            @test card.id == "custom_id"
            @test card.description == "This is a description"
        end

        config_3_files = ("example_5.md", "example_7.jl")
        foreach(config_3_files) do filename
            card = democard(joinpath(root, filename))
            @test card.title == "This is a title"
            @test card.id == "custom_id"
            @test card.description == "This is a description that spreads along multiple lines"
        end
    end
end
