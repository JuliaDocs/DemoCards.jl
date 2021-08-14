@testset "JuliaDemoCard" begin
    # default behavior
    simplest = democard("simplest.jl")
    @test simplest.cover === nothing
    @test simplest.id == "Simplest"
    @test simplest.path == "simplest.jl"
    @test simplest.title == "Simplest"
    @test simplest.description == "This is the content"

    @testset "parse" begin
        @testset "title, id and description" begin
            # JuliaDemoCard doesn't parse title from the markdown contents
            title_1 = JuliaDemoCard("title_1.jl")
            @test title_1.id == "Custom-Title"
            @test title_1.title == "Custom Title"
            @test title_1.description == "This is the content"
            @test title_1.hidden == false
            @test title_1.author == ""
            @test title_1.date == DateTime(0)

            title_2 = JuliaDemoCard("title_2.jl")
            @test title_2.id == "custom_id_2"
            @test title_2.title == "Custom Title 2"
            @test title_2.description == "This is the content"

            title_3 = JuliaDemoCard("title_3.jl")
            @test title_3.id == "Custom-Title-3-1"
            @test title_3.title == "Custom Title 3-1"
            @test title_3.description == "This is the content"

            title_4 = JuliaDemoCard("title_4.jl")
            @test title_4.id == "Custom-Title"
            @test title_4.title == "Custom Title"
            @test title_4.description == "This is the content"

            title_5 = JuliaDemoCard("title_5.jl")
            @test title_5.id == "Custom-Title"
            @test title_5.title == "Custom Title"
            @test title_5.description == "Custom Description"

            title_6 = JuliaDemoCard("title_6.jl")
            @test title_6.id == "custom_id"
            @test title_6.title == "Custom Title"
            @test title_6.description == "This is the content"

            title_7 = JuliaDemoCard("title_7.jl")
            @test title_7.id == "custom_id"
            @test title_7.title == "Custom Title"
            @test title_7.description == "This is the content"
            @test title_7.hidden == false
            @test title_7.author == "Jane Doe; John Roe"
            @test title_7.date == DateTime("2020-01-31")
            @test title_7.cover == "https://juliaimages.org/latest/assets/logo.png"

            title_8 = JuliaDemoCard("title_8.jl")
            @test title_8.id == "custom_id"
            @test title_8.title == "Custom Title"
            @test title_8.description == "This is the content"

            description_1 = JuliaDemoCard("description_1.jl")
            @test description_1.id == "Custom-Title"
            @test description_1.title == "Custom Title"
            @test description_1.description == "this is a single line destiption that spans over multiple lines\n"
            
            description_2 = JuliaDemoCard("description_2.jl")
            @test description_2.id == "Custom-Title"
            @test description_2.title == "Custom Title"
            @test description_2.description == "this is a multi line\ndestiption that spans\nover multiple lines\n"
        end

        @testset "cover" begin
            cover_1 = JuliaDemoCard("cover_1.jl")
            @test cover_1.cover == nothing

            cover_2 = JuliaDemoCard("cover_2.jl")
            @test cover_2.cover ==  joinpath("..", "logo.png")

            cover_3 = JuliaDemoCard("cover_3.jl")
            @test cover_3.cover == "nonexistence.jpg"

            cover_4 = JuliaDemoCard("cover_4.jl")
            @test cover_4.cover == joinpath("..", "logo.png")
        end

        @testset "version" begin
            card = JuliaDemoCard("version_1.jl")
            card.julia == v"1.2.3"

            card = JuliaDemoCard("version_2.jl")
            card.julia == v"999.0.0"
            warn_msg = @capture_err preview_demos("version_2.jl"; require_html=false)
            @test occursin("The running Julia version `$(VERSION)` is older than the declared compatible version `$(card.julia)`.", warn_msg)
        end

        @testset "notebook" begin
            card = JuliaDemoCard("notebook_1.jl")
            @test card.notebook == true

            card = JuliaDemoCard("notebook_2.jl")
            @test card.notebook == false

            card = JuliaDemoCard("notebook_3.jl")
            @test card.notebook == false

            card = JuliaDemoCard("notebook_4.jl")
            @test card.notebook == nothing
            warn_msg = @capture_err JuliaDemoCard("notebook_4.jl")
            @test occursin("`notebook` option should be either `\"true\"` or `\"false\"`, instead it is: nothing. Fallback to unconfigured.", warn_msg)
        end

        @testset "generate" begin
            page_dir = @suppress_err preview_demos("title_7.jl", theme="grid", require_html=false)
            card_dir = joinpath(page_dir, "julia")

            function strip_notebook(contents)
                # the notebook contents are different in CI and non-CI cases
                # [![notebook](badge_url)](notebook_url)
                replace(contents, r"\[!\[notebook\]\(.*\)\]\(.*\.ipynb\) " => "")
            end
            isempty(DemoCards.get_nbviewer_root_url("master")) || println(read(joinpath(card_dir, "title_7.md"), String)) # for debug usage
            @test_reference joinpath(test_root, "references", "cards", "julia_md.md") strip_notebook(read(joinpath(card_dir, "title_7.md"), String)) by=ignore_CR
            @test_reference joinpath(test_root, "references", "cards", "julia_src.jl") read(joinpath(card_dir, "title_7.jl"), String) by=ignore_CR
            @test isfile(joinpath(card_dir, "title_7.ipynb"))
        end
    end
end
