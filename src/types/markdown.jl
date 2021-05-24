# generally, Documenter.jl assumes markdown files ends with `.md`
const markdown_exts = [".md",]
const markdown_footer = raw"""


---

*This page was generated using [DemoCards.jl](https://github.com/johnnychen94/DemoCards.jl).*


"""

"""
    struct MarkdownDemoCard <: AbstractDemoCard
    MarkdownDemoCard(path::String)

Constructs a markdown-format demo card from existing markdown file `path`.

# Fields

Besides `path`, this struct has some other fields:

* `path`: path to the source markdown file
* `cover`: path to the cover image
* `id`: cross-reference id
* `title`: one-line description of the demo card
* `author`: author(s) of this demo.
* `date`: the update date of this demo.
* `description`: multi-line description of the demo card
* `hidden`: whether this card is shown in the generated index page

# Configuration

You can pass additional information by adding a YAML front matter to the markdown file.
Supported items are:

* `cover`: an URL or a relative path to the cover image. If not specified, it will use the first available image link, or all-white image if there's no image links.
* `description`: a multi-line description to this file, will be displayed when the demo card is hovered. By default it uses `title`.
* `id`: specify the `id` tag for cross-references. By default it's infered from the filename, e.g., `simple_demo` from `simple demo.md`.
* `title`: one-line description to this file, will be displayed under the cover image. By default, it's the name of the file (without extension).
* `author`: author name. If there are multiple authors, split them with semicolon `;`.
* `date`: any string contents that can be passed to `Dates.DateTime`. For example, `2020-09-13`.
* `hidden`: whether this card is shown in the layout of index page. The default value is `false`.

An example of the front matter:

```text
---
title: passing extra information
cover: cover.png
id: non_ambiguious_id
author: Jane Doe; John Roe
date: 2020-01-31
description: this demo shows how you can pass extra demo information to DemoCards package. All these are optional.
hidden: false
---
```

See also: [`JuliaDemoCard`](@ref DemoCards.JuliaDemoCard), [`DemoSection`](@ref DemoCards.DemoSection), [`DemoPage`](@ref DemoCards.DemoPage)
"""
mutable struct MarkdownDemoCard <: AbstractDemoCard
    path::String
    cover::Union{String, Nothing}
    id::String
    title::String
    description::String
    author::String
    date::DateTime
    hidden::Bool
    function MarkdownDemoCard(
        path::String,
        cover::Union{String, Nothing},
        id::String,
        title::String,
        description::String,
        author::String,
        date::DateTime,
        hidden::Bool
    )
        isfile(path) || throw(ArgumentError("$(path) is not a valid file"))
        new(path, cover, id, title, description, author, date, hidden)
    end
end

function MarkdownDemoCard(path::String)::MarkdownDemoCard
    # first consturct an incomplete democard, and then load the config
    card = MarkdownDemoCard(path, "", "", "", "", "", DateTime(0), false)

    config = parse(card)
    card.cover = load_config(card, "cover"; config=config)
    card.title = load_config(card, "title"; config=config)
    card.date = load_config(card, "date"; config=config)
    card.author = load_config(card, "author"; config=config)

    # Unlike JuliaDemoCard, Markdown card doesn't accept `julia` compat field. This is because we
    # generally don't know the markdown processing backend. It might be Documenter, but who knows.
    # More generally, any badges can just be manually added by demo writter, if they want.
    # `date` and `author` fields are added just for convinience.

    # default id requires a title
    card.id    = load_config(card, "id"; config=config)
    # default description requires a title
    card.description = load_config(card, "description"; config=config)
    card.hidden = load_config(card, "hidden"; config=config)
    return card
end


"""
    save_democards(card_dir::String, card::MarkdownDemoCard)

process the original markdown file and save it.

The processing pipeline is:

1. strip the front matter
2. insert a level-1 title and id
"""
function save_democards(card_dir::String,
                        card::MarkdownDemoCard;
                        credit,
                        kwargs...)
    isdir(card_dir) || mkpath(card_dir)

    markdown_path = joinpath(card_dir, basename(card))

    _, _, body = split_frontmatter(read(card.path, String))
    config = parse(Val(:Markdown), body)
    need_header = !haskey(config, "title")
    # @ref syntax: https://juliadocs.github.io/Documenter.jl/stable/man/syntax/#@ref-link-1
    header = need_header ? "# [$(card.title)](@id $(card.id))\n" : "\n"

    footer = credit ? markdown_footer : "\n"
    write(markdown_path, header, make_badges(card)*"\n\n", body, footer)
end
