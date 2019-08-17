const demo_card_template = mt"""
```@raw html
<div class="cards">
```

```@raw html
<div class="card-200">
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
    open(file, "w") do f
        generate(f, page::DemoPage)
    end
end
function generate(io::IO, page::DemoPage)
    save_covers(page)
    write(io, generate(page))
end
function generate(page::DemoPage)
    # TODO: Important: we need to render section by section
    items = Dict("sections" => generate(page.sections))
    Mustache.render(page.template, items)
end

# TODO: make a grid of cards instead of directly join them
generate(cards::AbstractVector{DemoCard}) =
    reduce(*, map(generate, cards); init="")

generate(secs::AbstractVector{DemoSection}; level=1) =
    reduce(*, map(x->generate(x;level=level), secs); init="")

function generate(sec::DemoSection; level=1)
    head = repeat("#", level) * " $(get_name(sec))\n"
    foot = "\n\n---\n\n"
    # either cards or subsections are empty
    head * generate(sec.cards) * generate(sec.subsections; level=level+1) * foot
end

function generate(card::DemoCard)
    items = Dict(
        "name" => lowercase(card.title),
        "title" => card.title
    )
    Mustache.render(demo_card_template, items)
end


save_covers(page::DemoPage) = save_covers.(page.sections)
function save_covers(sec::DemoSection)
    save_covers.(sec.subsections)
    save_covers.(sec.cards)
end
function save_covers(card::DemoCard)
    # TODO: we need to remove the *absolute* path "docs/src/demofiles"
    mkpath("docs/src/demopages/covers/")
    cover_path = "docs/src/demopages/covers/" * lowercase(card.title) * ".png"
    save(cover_path, card.cover)
end
