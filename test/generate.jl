@testset "generate" begin
    root = "assets"

    for theme in ("grid", )
        templates = DemoCards.cardtheme(Val(Symbol(theme)))[1]

        sec = DemoSection(joinpath(root, "section", "default"))
        @test_reference joinpath("references", "generate_section_$theme.txt") generate(sec, templates) by=ignore_CR

        page = DemoPage(joinpath(root, "page", "default"))
        @test_reference joinpath("references", "generate_page_$theme.txt") generate(page, templates) by=ignore_CR
    end

    abs_root = joinpath(pwd(), root, "page", "default")
    mktempdir() do root
        tmp_root = joinpath(root, "page", "default")
        mkpath(tmp_root)
        cp(abs_root, tmp_root, force=true)
        templates, theme = cardtheme(root=root)
        path, post_process_cb = @suppress_err makedemos(tmp_root, templates, root=root)
        @test @suppress_err path == joinpath("default", "index.md")
        @test theme == joinpath("democards", "gridtheme.css")
    end

    @testset "hidden" begin
        page_dir = @suppress_err preview_demos(joinpath(root, "page", "hidden"); theme="grid", require_html=false)
        md_index = joinpath(page_dir, "index.md")
        # test only one card is shown in index.md
        @test_reference joinpath("references", "hidden_index.txt") read(md_index, String)

        # check that assets are still normally generated even if they are hidden from index.md
        @test readdir(page_dir) == ["covers", "index.md", "sec"]
        @test readdir(joinpath(page_dir, "covers")) == ["democards_logo.svg"]
        @test readdir(joinpath(page_dir, "sec")) == ["hidden1.ipynb", "hidden1.jl", "hidden1.md", "hidden2.md", "normal.md"]
    end

    @testset "throw_error" begin
        @suppress_err @test_throws LoadError preview_demos(joinpath(root, "broken_demo.jl"); throw_error=true)
    end
end
