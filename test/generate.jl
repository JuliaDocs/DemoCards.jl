@testset "generate" begin
    root = "assets"

    sec = DemoSection(joinpath(root, "section", "default"))
    @test_reference joinpath("references", "generate_section.txt") generate(sec)

    page = DemoPage(joinpath(root, "page", "default"))
    @test_reference joinpath("references", "generate_page.txt") generate(page)

    abs_root = joinpath(pwd(), root, "page", "default")
    mktempdir() do root
        path, post_process_cb = @suppress_err makedemos(abs_root, root=root)
        @test @suppress_err path == joinpath("democards", "default", "index.md")
        @test cardtheme(root=root) == joinpath("democards", "cardtheme.css")
    end
end
