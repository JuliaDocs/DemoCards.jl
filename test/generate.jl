@testset "generate" begin
    root = "assets"

    for theme in ("grid", )
        templates = DemoCards.cardtheme(Val(Symbol(theme)))[1]

        sec = DemoSection(joinpath(root, "section", "default"))
        @test_reference joinpath("references", "generate_section_$theme.txt") generate(sec, templates)

        page = DemoPage(joinpath(root, "page", "default"))
        @test_reference joinpath("references", "generate_page_$theme.txt") generate(page, templates)
    end

    abs_root = joinpath(pwd(), root, "page", "default")
    mktempdir() do root
        tmp_root = joinpath(root, "page", "default")
        mkpath(tmp_root)
        cp(abs_root, tmp_root, force=true)
        templates, theme = cardtheme(root=root)
        path, post_process_cb = @suppress_err makedemos(tmp_root, templates, root=root)
        @test @suppress_err path == joinpath("democards", "default", "index.md")
        @test theme == joinpath("democards", "gridtheme.css")
    end
end
