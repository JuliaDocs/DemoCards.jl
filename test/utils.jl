using DemoCards: democard, walkpage, DemoPage

@testset "regexes" begin
    root = joinpath("assets", "regexes")

    @testset "title" begin
        config_1_files = ("example_1.md",
                          "example_3.md",
                          "example_4.md",
                          "example_6.md",
                          "example_7.md",
                          "example_8.md",
                          "example_1.jl",
                          "example_4.jl",
                          "example_5.jl",
                          "example_6.jl",
                          "example_8.jl",
                          "example_9.jl",
                          "example_10.jl",
                          "example_11.jl",
                          "example_12.jl",
                          "example_13.jl")
        foreach(config_1_files) do filename
            card = democard(joinpath(root, filename))
            @test card.title == "This is a title"
            @test card.id == "This-is-a-title"
            @test card.description == "This is a description"
        end

        config_2_files =  ("example_2.md", "example_2.jl", "example_3.jl")
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
            @test card.id == "This-is-a-title"
            @test card.description == "This is a description that spreads along multiple lines"
        end
    end

    # only lines before body contents can be potential titles
    config = DemoCards.parse(Val(:Julia), joinpath(root, "title_before_body.jl"))
    @test haskey(config, "description")
    @test config["description"] == "This is parsed as a description line --- [1]"
    @test !haskey(config, "title")
    @test !haskey(config, "id")
    @test !haskey(config, "cover")

    config = DemoCards.parse(Val(:Markdown), joinpath(root, "title_before_body.md"))
    @test haskey(config, "description")
    @test config["description"] == "This is parsed as a description line --- [1]"
    @test !haskey(config, "title")
    @test !haskey(config, "id")
    @test !haskey(config, "cover")


    # check if upstream changes on "Edit On GitHub" button breaks the redirect_url logic
    try
        example_url = "https://juliadocs.github.io/Documenter.jl/stable/"
        regex_url = r"http[s]?://.*index\.md"

        contents = String(HTTP.get(example_url; readtimeout=3, retry=false).body)

        m = match(DemoCards.regex_edit_on_github, contents)
        @test isa(m, RegexMatch)
        if m isa RegexMatch
            @test isa(match(regex_url, m.captures[1]), RegexMatch)
        end
    catch err
        # if network is down...
        @warn err
    end
end

@testset "url_redirect" begin
    source = "quickstart"
    build_url = "https://github.com/johnnychen94/DemoCards.jl/blob/master/docs/src/quickstart/usage_example/julia_demos/2.cover_on_the_fly.md"
    src_url = "https://github.com/johnnychen94/DemoCards.jl/blob/master/docs/quickstart/usage_example/julia_demos/2.cover_on_the_fly.jl"
    @test src_url == DemoCards.get_source_url(build_url, source, "2.cover_on_the_fly.jl", "src")

    source = joinpath("theme_gallery", "grid")
    build_url = "https://github.com/johnnychen94/DemoCards.jl/blob/master/docs/src/grid/grid_section_1/grid_subsection_1/grid_card_1.md"
    src_url = "https://github.com/johnnychen94/DemoCards.jl/blob/master/docs/theme_gallery/grid/grid_section_1/grid_subsection_1/grid_card_1.md"
    @test src_url == DemoCards.get_source_url(build_url, source, "grid_card_1.md", "src")
end

@testset "walkpage" begin
    page = DemoPage(joinpath("assets", "page", "hidden"))
    reference = "Hidden" => ["hidden1.jl", "hidden2.md", "normal.md"]
    @test reference == walkpage(page) do dir, item
        basename(item.path)
    end
    reference = "Hidden" => ["Sec" => ["hidden1.jl", "hidden2.md", "normal.md"]]
    @test reference == walkpage(page; flatten=false) do dir, item
        basename(item.path)
    end

    page = DemoPage(joinpath("assets", "page", "one_card"))
    reference = "One card" => ["card.md"]
    @test reference == walkpage(page) do dir, item
        basename(item.path)
    end
    reference = "One card" => ["Section" => ["Subsection" => ["card.md"]]]
    @test reference == walkpage(page; flatten=false) do dir, item
        basename(item.path)
    end
end
