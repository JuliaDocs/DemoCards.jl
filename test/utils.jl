using DemoCards: parse_markdown

@testset "regexes" begin
    root = joinpath("assets", "regexes")

    @testset "title" begin
        ref_config_1 = Dict("title" => "This is a title",
                        "id" => "This-is-a-title-1")
        ref_config_2 = Dict("title" => "This is a title",
                        "id" => "custom_id")

        config = parse_markdown(joinpath(root, "title_1.md"))
        @test config == ref_config_1

        config = parse_markdown(joinpath(root, "title_2.md"))
        @test config == ref_config_2

        config = parse_markdown(joinpath(root, "title_3.md"))
        @test config == ref_config_2

        config = parse_markdown(joinpath(root, "title_4.md"))
        @test config == ref_config_1
    end
end
