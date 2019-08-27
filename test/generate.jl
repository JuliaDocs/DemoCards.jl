@testset "generate" begin
    root = "assets"

    sec = DemoSection(joinpath(root, "section", "default"))
    @test_reference joinpath("references", "generate_section.txt") generate(sec)

    page = DemoPage(joinpath(root, "page", "default"))
    @test_reference joinpath("references", "generate_page.txt") generate(page)

    abs_root = joinpath(pwd(), root, "page", "default")
    mktempdir() do root
        @test @suppress_err makedemos(abs_root, root=root) == joinpath("democards", "default", "index.md")
        @test cardtheme(root=root) == joinpath("democards", "cardtheme.css")
    end
end
