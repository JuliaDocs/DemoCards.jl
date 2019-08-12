module DemoCards

using Mustache

import Base: show

include("compat.jl")

const indent_spaces = "  "
const demo_card_template = mt"""
```@raw html
<div class="cards">
```

```@raw html
<div class="card-200">
<div class="card-img">
```

[![svd](assets/demos/{{name}}.jpg)](@ref {{name}})

```@raw html
</div>
<div class="card-text">
```

[{{title}}](@ref {{name}})
```@raw html
</div>
</div>
```

"""

struct DemoCard
    title::String
    path::String

    function DemoCard(title::String, path::String)
        isfile(path) || throw("path should be a valid file, instead it's {path}")
        new(title, path)
    end
end
function DemoCard(path::String)
    title = splitext(splitpath(path)[end])[1]
    DemoCard(title, path)
end

function show(io::IO, card::DemoCard)
    println(io, card.title)
end

struct DemoSection
    title::String
    cards::Vector{DemoCard}
    subsections::Vector{DemoSection}

    function DemoSection(title, cards, subsections)
        if !xor(isempty(cards), isempty(subsections))
            throw("a section should only hold cards or subsections")
        end
        new(title, cards, subsections)
    end
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

function DemoSection(root::String; file_fmt=".md")::DemoSection
    isdir(root) || throw("root should be a valid dir, instead it's $(root)")

    section_title = splitpath(root)[end]

    path = map(x->joinpath(root,x), readdir(root))
    card_path = filter(x->isfile(x) && endswith(x, file_fmt), path)

    section_path = filter(isdir, path)

    DemoSection(section_title,
                map(DemoCard, card_path),
                map(DemoSection, section_path))
end

struct DemoPage
    sections::Vector{DemoSection}
    title::String
    head::String
    foot::String
end

function show(io::IO, page::DemoPage)
    println(io, "# ", page.title)
    isempty(page.head) || println(io, page.head)
    foreach(x->show(io, x; level=2), page.sections)
    isempty(page.foot) || println(io, page.foot)
end

function DemoPage(root::String;
                  title="",
                  head="",
                  foot="",
                  order=nothing)::DemoPage
    isdir(root) || throw("root should be a valid dir, instead it's $(root)")
    root = rstrip(root, '/')
    page_title = isempty(title) ? uppercasefirst(splitdir(root)[end]) : title

    section_roots = filter(isdir, map(x->joinpath(root, x),
                                     readdir(root)))
    sections = map(DemoSection, section_roots)

    DemoPage(sections, page_title, head, foot)
end

# generate the entire demo page
function generate(file::String, page::DemoPage)
    open(file, "w") do f
        generate(f, page::DemoPage)
    end
end
generate(io::IO, page::DemoPage) =
    write(io, generate(page))
generate(page::DemoPage) =
    page.head * generate(page.sections) * page.foot

# TODO: make a grid of cards instead of directly join them
generate(cards::AbstractVector{DemoCard}) =
    reduce(*, map(generate, cards); init="")

generate(secs::AbstractVector{DemoSection}; level=1) =
    reduce(*, map(x->generate(x;level=level), secs); init="")

function generate(sec::DemoSection; level=1)
    head = repeat("#", level) * " $(sec.title)\n"
    foot = "\n\n---\n\n"
    # either cards or subsections are empty
    head * generate(sec.cards) * generate(sec.subsections; level=level+1) * foot
end

function generate(card::DemoCard)
    Mustache.render(demo_card_template, Dict(
        "name" => card.title,
        "title" => card.title
    ))
end

export DemoCard, DemoSection, DemoPage,
       generate

end # module
