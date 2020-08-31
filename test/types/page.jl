using DemoCards: infer_pagedir, is_demosection, is_democard

@testset "DemoPage" begin
    root = joinpath("assets", "page")

    # default DemoPage behavior
    page = DemoPage(joinpath(root, "default"))
    @test page.title == "Default"
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

    # template
    page = DemoPage(joinpath(root, "template_2"))
    @test page.title == "Custom Title"

    # template has higher priority
    page = DemoPage(joinpath(root, "suppressed_title"))
    @test page.title == "Custom Title"
end

@testset "infer_pagedir" begin
    for pagename in ["default", "suppressed_title", "template", "template_2", "title_and_order"]
        page_dir = joinpath("assets", "page", pagename)

        for (root, dirs, files) in walkdir(page_dir)
            for dir in dirs
                secdir = joinpath(root, dir)
                is_demosection(secdir) && @test infer_pagedir(secdir) == page_dir
            end
            for file in files
                cardpath = joinpath(root, file)
                is_democard(cardpath) && @test infer_pagedir(cardpath) == page_dir
            end
        end
    end

    # when no page structure is detected, return nothing
    @test infer_pagedir("assets") |> isnothing
    @test infer_pagedir(joinpath("assets", "regexes")) |> isnothing
    @test infer_pagedir(joinpath("assets", "regexes", "example_1.jl")) |> isnothing
end
