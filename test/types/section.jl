@testset "DemoSection" begin
    root = joinpath("assets", "section")

    # default section behavior
    sec = DemoSection(joinpath(root, "default"))
    @test sec.title == "default"
    @test sec.cards == []
    subsec1, subsec2 = sec.subsections
    @test subsec1.title == "subsection_1"
    @test subsec2.title == "subsection_2"
    @test subsec1.subsections == []
    @test subsec2.subsections == []
    card1, card2 = subsec1.cards
    card3, card4 = subsec2.cards
    @test card1.path == joinpath(subsec1.root, "card_1.md")
    @test card2.path == joinpath(subsec1.root, "card_2.md")
    @test card3.path == joinpath(subsec2.root, "card_3.md")
    @test card4.path == joinpath(subsec2.root, "card_4.md")

    # only config subsection_1
    sec = DemoSection(joinpath(root, "partial_config"))
    @test sec.title == "Partial Config"
    @test sec.cards == []
    subsec1, subsec2 = sec.subsections
    @test subsec1.title == "Subsection 1"
    @test subsec2.title == "subsection_2"
    @test subsec1.subsections == []
    @test subsec2.subsections == []
    card1, card2 = subsec1.cards
    card3, card4 = subsec2.cards
    @test card1.path == joinpath(subsec1.root, "card_2.md")
    @test card2.path == joinpath(subsec1.root, "card_1.md")
    @test card3.path == joinpath(subsec2.root, "card_3.md")
    @test card4.path == joinpath(subsec2.root, "card_4.md")

    # invalid cases
    @test_throws ArgumentError @suppress_err DemoSection(joinpath(root, "partial_order"))
    @test_throws ArgumentError @suppress_err DemoSection(joinpath(root, "cards_and_subsections"))
end
