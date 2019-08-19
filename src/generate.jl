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

    save_covers(joinpath(absolute_root, "covers"), page)
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

[![svd](covers/{{name}}.png)](@ref {{name}})

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
        "name" => lowercase(card.title),
        "title" => card.title
    )
    Mustache.render(card_template, items)
end


save_covers(path::String, page::DemoPage) = save_covers.(path, page.sections)
function save_covers(path::String, sec::DemoSection)
    # TODO: we can perserve the folder structure when creating covers
    save_covers.(path, sec.subsections)
    save_covers.(path, sec.cards)
end
function save_covers(path::String, card::AbstractDemoCard)
    ext = ".png" # consistent to card_template
    cover_path = joinpath(path, lowercase(card.title) * ext)

    if isfile(cover_path)
        @warn("$(cover_path) already exists, perhaps you have demos of the same filename")
    end

    save(cover_path, card.cover)
end
