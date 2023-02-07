const pluto_footer = raw"""

---

*This page was generated using [DemoCards.jl](https://github.com/johnnychen94/DemoCards.jl). and [PlutoStaticHTML.jl](https://github.com/rikhuijzer/PlutoStaticHTML.jl)*


"""

"""
    struct PlutoDemoCard <: AbstractDemoCard
    PlutoDemoCard(path::AbstractString)

Constructs a markdown-format demo card from a pluto notebook.


# Fields

Besides `path`, this struct has some other fields:

* `path`: path to the source markdown file
* `cover`: path to the cover image
* `id`: cross-reference id
* `title`: one-line description of the demo card
* `author`: author(s) of this demo.
* `date`: the update date of this demo.
* `julia`: Julia version compatibility
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
* `julia`: Julia version compatibility. Any string that can be converted to `VersionNumber`
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

See also: [`PlutoDemoCard`](@ref DemoCards.PlutoDemoCard), [`DemoSection`](@ref DemoCards.DemoSection), [`DemoPage`](@ref DemoCards.DemoPage)
"""
mutable struct PlutoDemoCard <: AbstractDemoCard
    path::String
    cover::Union{String,Nothing}
    id::String
    title::String
    description::String
    author::String
    date::DateTime
    julia::Union{Nothing,VersionNumber}
    hidden::Bool
end
