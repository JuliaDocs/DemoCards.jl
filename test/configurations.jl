# test various page configuration
@testset "configurations" begin
    root = joinpath("assets", "configurations")
    @testset "notebook" begin
        src_page_dir = joinpath(root, "without_notebook")
        page = DemoPage(src_page_dir)

        sec1 = page.sections[1]
        @test sec1.title == "Sec1"
        @test sec1.properties["notebook"] == "true"
        sec2 = page.sections[2]
        @test sec2.title == "Sec2"
        @test isempty(sec2.properties)

        @test isnothing(sec1.cards[1].notebook) # This might become `true` in the future
        @test sec1.cards[2].notebook == false

        page_dir = @suppress_err preview_demos(src_page_dir, require_html=false)
        if basename(page_dir) == "configurations"
            page_dir = joinpath(page_dir, "without_notebook")

            sec1_files = readdir(joinpath(page_dir, "sec1"))
            @test Set(filter(x->startswith(x, "demo1"), sec1_files)) == Set(["demo1.ipynb", "demo1.jl", "demo1.md"])
            @test Set(filter(x->startswith(x, "demo2"), sec1_files)) == Set(["demo2.jl", "demo2.md"])
            @test filter(x->startswith(x, "demo3"), sec1_files) == ["demo3.md"]

            sec2_files = readdir(joinpath(page_dir, "sec2"))
            @test Set(filter(x->startswith(x, "demo4"), sec2_files)) == Set(["demo4.jl", "demo4.md"])
            @test Set(filter(x->startswith(x, "demo5"), sec2_files)) == Set(["demo5.ipynb", "demo5.jl", "demo5.md"])
        else
            @warn "Inferred page dir for $src_page_dir is no longer \"configurations/\""
            @test_broken false
        end
    end

end
