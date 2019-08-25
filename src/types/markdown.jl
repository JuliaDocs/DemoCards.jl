# generally, Documenter.jl assumes markdown files ends with `.md`
const markdown_exts = [".md",]

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

See also: [`DemoSection`](@ref DemoCards.DemoSection), [`DemoPage`](@ref DemoCards.DemoPage)
"""
struct MarkdownDemoCard <: AbstractDemoCard
    path::String
    cover::Union{String, Nothing}
    id::String
    title::String
    description::String
end

function MarkdownDemoCard(path::String)::MarkdownDemoCard
    # first consturct an incomplete democard, and then load the config
    card = MarkdownDemoCard(path, "", "", "", "")

    cover = load_config(card, "cover")
    id    = load_config(card, "id")
    title = load_config(card, "title")
    card = MarkdownDemoCard(path, cover, id, title, "")

    # default description requires a title
    description = load_config(card, "description")
    MarkdownDemoCard(path, cover, id, title, description)
end

function get_default_id(card::MarkdownDemoCard)
    name_without_ext = splitext(basename(card))[1]
    # default documenter id has -1 suffix
    replace(name_without_ext, ' ' => '-') * "-1"
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
    contents = split(read(card.path, String), "---\n")

    if length(contents) == 1
        config = Dict()
    else
        config = YAML.load(strip(contents[2]))

        # set the first valid image path as cover
        # TODO: only markdown syntax is supported now
        body = join(contents[3:end])
        image_paths = map(eachmatch(regex_md_img, body)) do m
            image_link = m.captures[1]
            joinpath(card.path, image_link)
        end
        filter!(isfile, image_paths)
        if !isempty(image_paths)
            config["cover"] = first(image_paths)
        end
    end

    return config
end
