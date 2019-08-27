@testset "show" begin
    root = joinpath(test_root, "assets")

    sec = DemoSection(joinpath(root, "section", "default"))
    @test_reference joinpath("references", "section.txt") sec

    page = DemoPage(joinpath(root, "page", "default"))
    sys = Base.Sys.iswindows() ? "windows" : "linux"
    @test_reference joinpath("references", "page_$(sys).txt") page
end
