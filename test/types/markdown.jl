@testset "MarkdownDemoCard" begin
    # default behavior
    simplest = democard("simplest.md")
    @test simplest.cover === nothing
    @test simplest.id == "Simplest"
    @test simplest.path == "simplest.md"
    @test simplest.title == "Simplest"
    @test simplest.description == "This is the content"

    @testset "parse" begin
        @testset "title, id and description" begin
            # MarkdownDemoCard doesn't parse title from the markdown contents
            title_1 = MarkdownDemoCard("title_1.md")
            @test title_1.id == ".-Custom-Title"
            @test title_1.title == "1. Custom Title"
            @test title_1.description == "This is the content"
            @test title_1.hidden == false
            @test title_1.author == ""
            @test title_1.date == DateTime(0)

            title_2 = MarkdownDemoCard("title_2.md")
            @test title_2.id == "custom_id_2"
            @test title_2.title == "Custom Title 2"
            @test title_2.description == "This is the content"

            title_3 = MarkdownDemoCard("title_3.md")
            @test title_3.id == "Custom-Title-3-1"
            @test title_3.title == "Custom Title 3-1"
            @test title_3.description == "This is the content"

            title_4 = MarkdownDemoCard("title_4.md")
            @test title_4.id == "Custom-Title"
            @test title_4.title == "Custom Title"
            @test title_4.description == "This is the content"

            title_5 = MarkdownDemoCard("title_5.md")
            @test title_5.id == "Custom-Title"
            @test title_5.title == "Custom Title"
            @test title_5.description == "Custom Description"

            title_6 = MarkdownDemoCard("title_6.md")
            @test title_6.id == "custom_id"
            @test title_6.title == "Custom Title"
            @test title_6.description == "This is the content"
            @test title_6.hidden == false
            @test title_6.author == "Jane Doe; John Roe"
            @test title_6.date == DateTime("2020-01-31")
            @test title_6.cover == "https://juliaimages.org/latest/assets/logo.png"

            title_7 = MarkdownDemoCard("title_7.md")
            @test title_7.id == "custom_id"
            @test title_7.title == "Custom Title"
            @test title_7.description == "This is the content"

            description_1 = MarkdownDemoCard("description_1.md")
            @test description_1.id == "Custom-Title"
            @test description_1.title == "Custom Title"
            @test description_1.description == "this is a single line destiption that spans over multiple lines\n"
            
            description_2 = MarkdownDemoCard("description_2.md")
            @test description_2.id == "Custom-Title"
            @test description_2.title == "Custom Title"
            @test description_2.description == "this is a multi line\ndestiption that spans\nover multiple lines\n"
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

        @testset "generate" begin
            page_dir = @suppress_err preview_demos("title_6.md", theme="grid", require_html=false)
            card_path = joinpath(page_dir, "markdown", "title_6.md")
            @test_reference joinpath(test_root, "references", "cards", "markdown.md") read(card_path, String) by=ignore_CR
        end
    end
end
