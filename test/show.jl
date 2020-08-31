@testset "show" begin
    root = "assets"

    sec = DemoSection(joinpath(root, "section", "default"))
    @test_reference joinpath("references", "section.txt") sec by=ignore_CR

    page = DemoPage(joinpath(root, "page", "default"))
    @test_reference joinpath("references", "page.txt") page by=ignore_CR
end
