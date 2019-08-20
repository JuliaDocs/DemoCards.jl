# generally, Documenter.jl assumes markdown files ends with `.md`
const markdown_exts = [".md",]

"""
    struct MarkdownDemoCard <: AbstractDemoCard
    MarkdownDemoCard(path::String)

Constructs a markdown-format demo card from existing markdown file `path`.

# Fields

Besides `path`, this struct has some other fields:

* `path`: path to the source markdown file
* `cover`: cover image of the demo card
* `title`: one-line description of the demo card

# Configuration

You can pass additional information by adding a YAML front matter to the markdown file.
Supported items are:

* 🚧`cover`: relative path to the cover image. By default, it's the first image link in this file or an all-white image if there's no image link available.
* 🚧`description`: a multi-line description to this file, will be displayed when the demo card is hovered. By default it's empty string `""`.
* 🚧`title`: one-line description to this file, will be displayed under the cover image. By default, it's the name of the file (without extension).

An example of the front matter:

```text
---
title: passing extra information
cover: cover.png
description: this demo shows how you can pass extra demo information to DemoCards package.
---
```

See also: [`DemoSection`](@ref DemoCards.DemoSection), [`DemoPage`](@ref DemoCards.DemoPage)
"""
struct MarkdownDemoCard <: AbstractDemoCard
    path::String
    # storing image content enables preprocessing on it
    cover::Array{<:Colorant, 2}
    title::String

    function MarkdownDemoCard(path::String,
                              cover::AbstractArray{<:Colorant, 2},
                              title::String)
        # TODO: we can beautify cover image here
        new(path, RGB.(cover), title)
    end
end

function MarkdownDemoCard(path::String)::MarkdownDemoCard
    # first consturct an incomplete democard, and then load the config
    card = MarkdownDemoCard(path, RGB.(Gray.(ones(128, 128))), "")

    cover = load_config(card, "cover")
    title = load_config(card, "title")
    MarkdownDemoCard(path, cover, title)
end

function load_config(card::MarkdownDemoCard, key)
    if key == "title"
        get_default_title(card)
    elseif key == "cover"
        get_default_cover(card)
    else
        throw("Unrecognized key $(key) for MarkdownDemoCard")
    end
end

function get_default_title(card::MarkdownDemoCard)
    uppercasefirst(splitext(basename(card))[1])
end

get_default_cover(demofile::MarkdownDemoCard) =
    RGB.(Gray.(ones(128, 128)))
