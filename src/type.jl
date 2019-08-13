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
