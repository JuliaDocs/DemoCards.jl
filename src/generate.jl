function makedemos(source::String;
                   root::String = "docs/src",
                   destination::String = "demopages")::String
    page = DemoPage(joinpath(root, source))

    relative_root = joinpath(destination, basename(page))
    absolute_root = joinpath(root, relative_root)

    @info "SetupDemoCardsDirectory: setting up $(source) directory."
    rm(absolute_root; force=true, recursive=true)
    mkpath(absolute_root)
    mkpath(joinpath(absolute_root, "covers"))

    save_cover(joinpath(absolute_root, "covers"), page)
    save_markdown(absolute_root, page)
    generate(joinpath(absolute_root, "index.md"), page)

    # we can directly pass it to Documenter.makedocs
    return joinpath(relative_root, "index.md")
end

const card_section_template = mt"""
```@raw html
<div class="card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const card_template = mt"""
```@raw html
<div class="card">
<div class="card-img">
```

[![svd](covers/{{name}}.png)](@ref {{id}})

```@raw html
</div>
<div class="card-text">
```

[{{title}}](@ref {{id}})
```@raw html
</div>
</div>
```

"""

function generate(file::String, page::DemoPage)
    check_ext(file, :markdown)
    open(file, "w") do f
        generate(f, page::DemoPage)
    end
end
generate(io::IO, page::DemoPage) = write(io, generate(page))
function generate(page::DemoPage)
    # TODO: Important: we need to render section by section
    items = Dict("sections" => generate(page.sections))
    Mustache.render(page.template, items)
end

generate(cards::AbstractVector{<:AbstractDemoCard}) =
    reduce(*, map(generate, cards); init="")

generate(secs::AbstractVector{DemoSection}; level=1) =
    reduce(*, map(x->generate(x;level=level), secs); init="")

function generate(sec::DemoSection; level=1)
    header = repeat("#", level) * " $(basename(sec))\n"
    footer = "\n"
    # either cards or subsections are empty
    if isempty(sec.cards)
        body = generate(sec.subsections; level=level+1)
    else
        items = Dict("cards" => generate(sec.cards))
        body = Mustache.render(card_section_template, items)
    end
    header * body * footer
end

function generate(card::AbstractDemoCard)
    items = Dict(
        "name" => splitext(basename(card))[1],
        "id" => card.id,
        "title" => card.title
    )
    Mustache.render(card_template, items)
end

### save demo card covers

# TODO: we can lazily load those covers
save_cover(path::String, page::DemoPage) = save_cover.(path, page.sections)
function save_cover(path::String, sec::DemoSection)
    # TODO: we can perserve the folder structure when creating covers
    save_cover.(path, sec.subsections)
    save_cover.(path, sec.cards)
end
function save_cover(path::String, card::AbstractDemoCard)
    ext = ".png" # consistent to card_template
    cover_path = joinpath(path, splitext(basename(card))[1] * ext)

    if isfile(cover_path)
        @warn("$(cover_path) already exists, perhaps you have demos of the same filename")
    end

    save(cover_path, card.cover)
end

### save markdown files

save_markdown(root::String, page::DemoPage) = save_markdown.(root, page.sections)
function save_markdown(root::String, sec::DemoSection)
    save_markdown.(joinpath(root, basename(sec.root)), sec.subsections)
    save_markdown.(joinpath(root, basename(sec.root)), sec.cards)
end

"""
    save_markdown(root::String, card::MarkdownDemoCard)

process the original markdown file and save it.

The processing pipeline is:

1. strip the front matter
2. insert a level-1 title and id
"""
function save_markdown(root::String, card::MarkdownDemoCard)
    isdir(root) || mkpath(root)

    markdown_path = joinpath(root, basename(card))

    contents = split(read(card.path, String), "---\n")
    body = length(contents) == 1 ? contents[1] : join(contents[3:end])

    # @ref syntax: https://juliadocs.github.io/Documenter.jl/stable/man/syntax/#@ref-link-1
    header = "# [$(card.title)](@id $(card.id))\n"

    write(markdown_path, header, body)
end
