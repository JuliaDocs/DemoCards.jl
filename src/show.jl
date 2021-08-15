import Base: show

const indent_spaces = "  "

function show(io::IO, card::AbstractDemoCard)
    print(io, basename(card))
end

function show(io::IO, sec::AbstractDemoSection; level=1)
    print(io, repeat(indent_spaces, level-1))
    println(io, repeat("#", level), " ", compact_title(sec))

    # a section either holds cards or subsections
    # here it's a mere coincident to show cards first
    foreach(cards(sec)) do x
        print(io, repeat(indent_spaces, level))
        show(io, x)
        println(io)
    end

    foreach(x->show(io, x; level=level+1), subsections(sec))
end

function show(io::IO, page::DemoPage)
    page_root = replace(page.root, "\\" => "/")
    println(io, "DemoPage(\"", page_root, "\"):\n")
    println(io, "# ", page.title)
    foreach(x->show(io, x; level=2), subsections(page))
end
