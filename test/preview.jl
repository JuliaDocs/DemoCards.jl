@testset "preview" begin
    root = "assets"
    abs_root = abspath(pwd(), root)

    @testset "page structure" begin
        page_dir = @suppress_err preview_demos(joinpath(abs_root, "page", "template"), theme="grid", require_html=false)
        md_index = joinpath(page_dir, "index.md")
        @test_reference joinpath("references", "preview", "index_page.md") read(md_index, String) by=ignore_CR

        @test readdir(page_dir) == ["covers", "index.md", "subsection_1", "subsection_2"]
        @test readdir(joinpath(page_dir, "subsection_2")) == ["card_3.md", "card_4.md"]

        for demo_file in filter(DemoCards.is_democard, readdir(joinpath(page_dir, "subsection_2")))
            demo_file = joinpath(joinpath(page_dir, "subsection_2"), demo_file)
            @test_reference joinpath("references", "preview", basename(demo_file)) read(demo_file, String) by=ignore_CR
        end
        @test "gridtheme.css" in readdir(joinpath(dirname(page_dir), "democards"))
    end

    @testset "section with non page structure" begin
        page_dir = @suppress_err preview_demos(joinpath(abs_root, "preview", "scripts"), theme="grid", require_html=false)
        md_index = joinpath(page_dir, "index.md")
        @test_reference joinpath("references", "preview", "index_sec_nopage.md") read(md_index, String) by=ignore_CR

        @test readdir(page_dir) == ["covers", "index.md", "scripts"]
        @test readdir(joinpath(page_dir, "covers")) == ["demo2.svg", "democards_logo.svg"]
        @test readdir(joinpath(page_dir, "scripts")) == ["assets", "demo1.ipynb", "demo1.jl", "demo1.md", "demo2.md"]
    end

    @testset "section with page structure" begin
        page_dir = @suppress_err preview_demos(joinpath(abs_root, "page", "template", "subsection_2"), theme="grid", require_html=false) 
        md_index = joinpath(page_dir, "index.md")
        @test_reference joinpath("references", "preview", "index_sec_page.md") read(md_index, String) by=ignore_CR

        @test readdir(page_dir) == ["covers", "index.md", "subsection_2"]
        @test readdir(joinpath(page_dir, "subsection_2")) == ["card_3.md", "card_4.md"]
    end

    @testset "section with invalid page structure" begin
        @test_throws ArgumentError @suppress_err preview_demos(joinpath(abs_root, "page"))
    end

    @testset "file with non page structure" begin
        page_dir = @suppress_err preview_demos(joinpath(abs_root, "preview", "scripts", "demo2.md"), theme="grid", require_html=false)
        md_index = joinpath(page_dir, "index.md")
        @test_reference joinpath("references", "preview", "index_file.md") read(md_index, String) by=ignore_CR

        @test readdir(page_dir) == ["covers", "index.md", "scripts"]
        @test readdir(joinpath(page_dir, "covers")) == ["demo2.svg"]
        @test readdir(joinpath(page_dir, "scripts")) == ["assets", "demo2.md"]
        @test readdir(joinpath(page_dir, "scripts", "assets")) == ["logo.svg"]

        page_dir = @suppress_err preview_demos(joinpath(abs_root, "preview_demo1.jl"), theme="grid", require_html=false)
        md_index = joinpath(page_dir, "index.md")
        @test_reference joinpath("references", "preview", "index_file2.md") read(md_index, String) by=ignore_CR

        @test readdir(page_dir) == ["covers", "index.md", "preview_section"]
        @test readdir(joinpath(page_dir, "covers")) == ["democards_logo.svg"]
        @test readdir(joinpath(page_dir, "preview_section")) == ["preview_demo1.ipynb", "preview_demo1.jl", "preview_demo1.md"]
    end

    @testset "file with page structure" begin
        page_dir = @suppress_err preview_demos(joinpath(abs_root, "page", "template", "subsection_2", "card_3.md"), theme="grid", require_html=false)
        md_index = joinpath(page_dir, "index.md")
        @test_reference joinpath("references", "preview", "index_file_page.md") read(md_index, String) by=ignore_CR

        @test readdir(page_dir) == ["covers", "index.md", "subsection_2"]
        @test readdir(joinpath(page_dir, "subsection_2")) == ["card_3.md"]

        page_dir = @suppress_err preview_demos(joinpath(abs_root, "page", "template", "subsection_2", "card_3.md"), theme=nothing, require_html=false)
        @test !isfile(joinpath(page_dir, "index.md"))
        @test readdir(page_dir) == ["subsection_2"]
        @test readdir(joinpath(page_dir, "subsection_2")) == ["card_3.md"]
    end

    index_page = @suppress_err @test_nowarn preview_demos(joinpath(abs_root, "preview"), theme="grid", require_html=true)
    @test isfile(index_page)
    index_page = @suppress_err @test_nowarn preview_demos(joinpath(abs_root, "preview"), require_html=true)
    @test isfile(index_page)
end
