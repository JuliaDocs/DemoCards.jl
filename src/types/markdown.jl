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
* `description`: multi-line description of the demo card

# Configuration

You can pass additional information by adding a YAML front matter to the markdown file.
Supported items are:

* `cover`: relative path to the cover image. If not specified, it will use the first available image link, or all-white image if there's no image links.
* `description`: a multi-line description to this file, will be displayed when the demo card is hovered. By default it uses `title`.
* `id`: specify the `id` tag for cross-references. By default it's infered from the filename, e.g., `simple_demo` from `simple demo.md`.
* `title`: one-line description to this file, will be displayed under the cover image. By default, it's the name of the file (without extension).

An example of the front matter:

```text
---
title: passing extra information
cover: cover.png
id: non_ambiguious_id
description: this demo shows how you can pass extra demo information to DemoCards package.
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
end

function MarkdownDemoCard(path::String)::MarkdownDemoCard
    # first consturct an incomplete democard, and then load the config
    card = MarkdownDemoCard(path, "", "", "", "")

    card.cover = load_config(card, "cover")
    card.id    = load_config(card, "id")
    card.title = load_config(card, "title")

    # default description requires a title
    card.description = load_config(card, "description")
    return card
end

"""
    parse(card::MarkdownDemoCard)

parse out configuration of markdown files and return it as a `Dict`.

Possible configuration resources are:

* YAML front matter
* image links

!!! note

    Users of this function need to use `haskey` to check if keys are existed.
    They also need to validate the values.
"""
function parse(card::MarkdownDemoCard)
    contents = readlines(card.path)
    offsets = findall(map(x->match(r"^---\s*", x) isa RegexMatch, contents))

    if isempty(offsets)
        config = Dict()
        body_offset = 1
    else
        frontmatter = join(contents[offsets[1]:offsets[2]], "\n")
        config = YAML.load(frontmatter)
        haskey(config, "cover") && isfile(config["cover"]) || delete!(config, "cover")
        body_offset = offsets[2]+1
    end
    body = contents[body_offset:end]

    if !haskey(config, "cover")
        # set the first valid image path as cover
        # TODO: only markdown syntax is supported now
        image_paths = map(body) do line
            m = match(regex_md_img, line)
            m isa RegexMatch || return nothing
            return m.captures[1]
        end
        filter!(image_paths) do x
            !isnothing(x) && isfile(dirname(card.path), x)
        end
        if !isempty(image_paths)
            config["cover"] = first(image_paths)
        end
    end

    if haskey(config, "cover")
        config["cover"] = replace(config["cover"],
                                  r"[/\\]" => Base.Filesystem.path_separator) # windows compatibility
    end

    return config
end


"""
    save_democards(root::String, card::MarkdownDemoCard)

process the original markdown file and save it.

The processing pipeline is:

1. strip the front matter
2. insert a level-1 title and id
"""
function save_democards(root::String,
                        card::MarkdownDemoCard;
                        credit,
                        kwargs...)
    isdir(root) || mkpath(root)

    markdown_path = joinpath(root, basename(card))

    contents = split(read(card.path, String), "---\n")
    body = length(contents) == 1 ? contents[1] : join(contents[3:end])

    # @ref syntax: https://juliadocs.github.io/Documenter.jl/stable/man/syntax/#@ref-link-1
    header = "# [$(card.title)](@id $(card.id))\n"
    footer = credit ? markdown_footer : ""
    write(markdown_path, header, body, footer)
end
