@testset "MarkdownDemoCard" begin
    root = joinpath(test_root, "assets", "card", "markdown")

    # default behavior
    simplest = democard(joinpath(root, "simplest.md"))
    @test simplest == MarkdownDemoCard(joinpath(root, "simplest.md"))
    @test simplest.cover === nothing
    @test simplest.id == "simplest-1"
    @test simplest.path == joinpath(root, "simplest.md")
    @test simplest.title == "Simplest"
    @test simplest.description == "Simplest"

    @testset "parse" begin
        @testset "title, id and description" begin
            # MarkdownDemoCard doesn't parse title from the markdown contents
            title_1 = MarkdownDemoCard(joinpath(root, "title_1.md"))
            @test title_1.id == "title_1-1"
            @test title_1.title == "Title 1"
            @test title_1.description == "Title 1"

            title_2 = MarkdownDemoCard(joinpath(root, "title_2.md"))
            @test title_2.id == "title_2-1"
            @test title_2.title == "Title 2"
            @test title_2.description == "Title 2"

            title_3 = MarkdownDemoCard(joinpath(root, "title_3.md"))
            @test title_3.id == "title_3-1"
            @test title_3.title == "Title 3"
            @test title_3.description == "Title 3"

            title_4 = MarkdownDemoCard(joinpath(root, "title_4.md"))
            @test title_4.id == "title_4-1"
            @test title_4.title == "Custom Title"
            @test title_4.description == "Custom Title"

            title_5 = MarkdownDemoCard(joinpath(root, "title_5.md"))
            @test title_5.id == "title_5-1"
            @test title_5.title == "Custom Title"
            @test title_5.description == "Custom Description"

            title_6 = MarkdownDemoCard(joinpath(root, "title_6.md"))
            @test title_6.id == "custom_id"
            @test title_6.title == "Custom Title"
            @test title_6.description == "Custom Title"
        end

        @testset "cover" begin
            cover_1 = MarkdownDemoCard(joinpath(root, "cover_1.md"))
            @test cover_1.cover == nothing

            cover_2 = MarkdownDemoCard(joinpath(root, "cover_2.md"))
            @test cover_2.cover == joinpath(root, "..", "logo.png")

            cover_3 = MarkdownDemoCard(joinpath(root, "cover_3.md"))
            @test cover_3.cover == joinpath(root, "..", "logo.png")

            cover_4 = MarkdownDemoCard(joinpath(root, "cover_4.md"))
            @test cover_4.cover == joinpath(root, "..", "logo.png")

            @test_throws ArgumentError MarkdownDemoCard(joinpath(root, "cover_5.md"))
        end
    end
end
