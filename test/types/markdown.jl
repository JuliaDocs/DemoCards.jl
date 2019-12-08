@testset "MarkdownDemoCard" begin
    # default behavior
    simplest = democard("simplest.md")
    @test simplest.cover === nothing
    @test simplest.id == "simplest-1"
    @test simplest.path == "simplest.md"
    @test simplest.title == "Simplest"
    @test simplest.description == "This is the content"

    @testset "parse" begin
        @testset "title, id and description" begin
            # MarkdownDemoCard doesn't parse title from the markdown contents
            title_1 = MarkdownDemoCard("title_1.md")
            @test title_1.id == "custom-title-1"
            @test title_1.title == "Custom Title"
            @test title_1.description == "This is the content"

            title_2 = MarkdownDemoCard("title_2.md")
            @test title_2.id == "custom_id_2"
            @test title_2.title == "Custom Title 2"
            @test title_2.description == "This is the content"

            title_3 = MarkdownDemoCard("title_3.md")
            @test title_3.id == "custom-title-3-1-1"
            @test title_3.title == "Custom Title 3-1"
            @test title_3.description == "This is the content"

            title_4 = MarkdownDemoCard("title_4.md")
            @test title_4.id == "custom-title-1"
            @test title_4.title == "Custom Title"
            @test title_4.description == "This is the content"

            title_5 = MarkdownDemoCard("title_5.md")
            @test title_5.id == "custom-title-1"
            @test title_5.title == "Custom Title"
            @test title_5.description == "Custom Description"

            title_6 = MarkdownDemoCard("title_6.md")
            @test title_6.id == "custom_id"
            @test title_6.title == "Custom Title"
            @test title_6.description == "This is the content"
        end

        @testset "cover" begin
            cover_1 = MarkdownDemoCard("cover_1.md")
            @test cover_1.cover == nothing

            cover_2 = MarkdownDemoCard("cover_2.md")
            @test cover_2.cover == joinpath("..", "logo.png")

            cover_3 = MarkdownDemoCard("cover_3.md")
            @test cover_3.cover == "nonexistence.jpg"

            cover_4 = MarkdownDemoCard("cover_4.md")
            @test cover_4.cover == joinpath("..", "logo.png")
        end
    end
end
