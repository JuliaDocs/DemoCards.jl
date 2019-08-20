"""
    makedemos(source::String) -> path

Make a demo page file and return the path to it.

`source` is the root path to the demos folder, by default it's relative path to `docs`.

Processing pipeline:

1. analyze the folder structure `source` and loading all available configs.
2. preprocess demo files and save it
3. save/copy cover images

!!! note
    By default, the source demo files are read, processed and save to `docs/src/demopages`,
    so if you put all source demo files in `docs/src`, there will be a duplication of files and assets.

# Keywords

* `root::String`: root path to the whole documentaion. By default `docs`.
* `destination::String`: By default `demopages`.

# Examples

You only need to call this function before `Documenter.makedocs`, and pass
the result to it.

```julia
format = Documenter.HTML(edit_branch = "master",
                         assets = [joinpath("assets", "style.css")])

examples = makedemos("examples")

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            "Examples" => examples,
         ])
```

!!! warning

    Currently, there's no guarantee that this function works for unconventional
    documentation folder structure. By *convention*, it is:

    ```text
    .
    ├── Project.toml
    ├── docs
    │   ├── make.jl
    │   └── src
    ├── src
    └── test
    ```
"""
function makedemos(source::String;
                   root::String = "docs",
                   destination::String = "demopages")::String
    page = DemoPage(joinpath(root, source))

    relative_root = joinpath(destination, basename(page))
    absolute_root = joinpath(root, "src", relative_root)

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

save_cover(path::String, page::DemoPage) = save_cover.(path, page.sections)
function save_cover(path::String, sec::DemoSection)
    # TODO: we can perserve the folder structure when creating covers
    save_cover.(path, sec.subsections)
    save_cover.(path, sec.cards)
end

"""
    save_cover(path::String, card::AbstractDemoCard)

process the cover image and save it.
"""
function save_cover(path::String, card::AbstractDemoCard)
    ext = ".png" # consistent to card_template
    cover_path = joinpath(path, splitext(basename(card))[1] * ext)

    if isfile(cover_path)
        @warn("$(cover_path) already exists, perhaps you have demos of the same filename")
    end

    cover = load_cover(card)

    save(cover_path, cover)
end

function load_cover(card::MarkdownDemoCard)::AbstractArray{<:Colorant}
    if !isnothing(card.cover)
        return load(card.cover)
    end

    # TODO: we can load the first available image path as the cover image

    # fallback
    return Gray.(ones(128, 128))
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
