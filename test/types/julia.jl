@testset "JuliaDemoCard" begin
    # default behavior
    simplest = democard("simplest.jl")
    @test simplest.cover === nothing
    @test simplest.id == "simplest-1"
    @test simplest.path == "simplest.jl"
    @test simplest.title == "Simplest"
    @test simplest.description == "Simplest"

    @testset "parse" begin
        @testset "title, id and description" begin
            # JuliaDemoCard doesn't parse title from the markdown contents
            title_1 = JuliaDemoCard("title_1.jl")
            @test title_1.id == "title-1-1"
            @test title_1.title == "Title 1"
            @test title_1.description == "Title 1"

            title_2 = JuliaDemoCard("title_2.jl")
            @test title_2.id == "title-2-1"
            @test title_2.title == "Title 2"
            @test title_2.description == "Title 2"

            title_3 = JuliaDemoCard("title_3.jl")
            @test title_3.id == "title-3-1"
            @test title_3.title == "Title 3"
            @test title_3.description == "Title 3"

            title_4 = JuliaDemoCard("title_4.jl")
            @test title_4.id == "title-4-1"
            @test title_4.title == "Custom Title"
            @test title_4.description == "Custom Title"

            title_5 = JuliaDemoCard("title_5.jl")
            @test title_5.id == "title-5-1"
            @test title_5.title == "Custom Title"
            @test title_5.description == "Custom Description"

            title_6 = JuliaDemoCard("title_6.jl")
            @test title_6.id == "custom_id"
            @test title_6.title == "Custom Title"
            @test title_6.description == "Custom Title"

            title_7 = JuliaDemoCard("title_7.jl")
            @test title_7.id == "custom_id"
            @test title_7.title == "Custom Title"
            @test title_7.description == "Custom Title"
        end

        @testset "cover" begin
            cover_1 = JuliaDemoCard("cover_1.jl")
            @test cover_1.cover == nothing

            cover_2 = JuliaDemoCard("cover_2.jl")
            @test cover_2.cover ==  joinpath("..", "logo.png")

            cover_3 = JuliaDemoCard("cover_3.jl")
            @test cover_3.cover == joinpath("..", "logo.png")

            cover_4 = JuliaDemoCard("cover_4.jl")
            @test cover_4.cover == joinpath("..", "logo.png")
        end
    end
end
