import Base: show

const indent_spaces = "  "

function show(io::IO, card::DemoCard)
    println(io, card.title)
end

function show(io::IO, sec::DemoSection; level=1)
    print(io, repeat(indent_spaces, level-1))
    println(io, repeat("#", level), " ", sec.title)

    # a section either holds cards or subsections
    # here it's a mere coincident to show cards first
    foreach(sec.cards) do x
        print(io, repeat(indent_spaces, level))
        show(io, x)
    end

    foreach(x->show(io, x; level=level+1), sec.subsections)
end

function show(io::IO, page::DemoPage)
    println(io, "# ", page.title)
    isempty(page.head) || println(io, page.head)
    foreach(x->show(io, x; level=2), page.sections)
    isempty(page.foot) || println(io, page.foot)
end
