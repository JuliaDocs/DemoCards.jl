@testset "DemoPage" begin
    root = joinpath(test_root, "types", "assets", "page")

    # default DemoPage behavior
    page = DemoPage(joinpath(root, "default"))
    @test page.title == "default"
    sec1, sec2 = page.sections
    @test sec1.root == joinpath(page.root, "subsection_1")
    @test sec2.root == joinpath(page.root, "subsection_2")

    # title and order
    page = DemoPage(joinpath(root, "title_and_order"))
    @test page.title == "Custom Title"
    sec1, sec2 = page.sections
    @test sec1.root == joinpath(page.root, "subsection_2")
    @test sec2.root == joinpath(page.root, "subsection_1")

    # template
    page = DemoPage(joinpath(root, "template"))
    @test page.title == "Custom Title"

    # template has higher priority
    @suppress_err page = DemoPage(joinpath(root, "suppressed_title"))
    @test page.title == "Custom Title"
end
