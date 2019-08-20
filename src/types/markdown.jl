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
* `title`: one-line description of the demo card

# Configuration

You can pass additional information by adding a YAML front matter to the markdown file.
Supported items are:

* `cover`: relative path to the cover image. If not specified, it will use the first available image link, or all-white image if there's no image links.
* 🚧`description`: a multi-line description to this file, will be displayed when the demo card is hovered. By default it's empty string `""`.
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
end

function MarkdownDemoCard(path::String)::MarkdownDemoCard
    # first consturct an incomplete democard, and then load the config
    card = MarkdownDemoCard(path, "", "", "")

    cover = load_config(card, "cover")
    id    = load_config(card, "id")
    title = load_config(card, "title")
    MarkdownDemoCard(path, cover, id, title)
end

# markdown image syntax: ![title](path)
const regex_md_img = r"!\[[^\s]*\]\(([^\s]*)\)"

function load_config(card::MarkdownDemoCard, key)
    config = parse(card)

    if key == "cover"
        root = dirname(card.path)
        if haskey(config, key)
            cover_path = joinpath(root, config[key])
            isfile(cover_path) || throw("$(cover_path) isn't a valid image file for cover.")
            return cover_path
        else
            # load the first valid image path
            # only markdown syntax is supported now
            contents = read(card.path, String)
            image_paths = map(eachmatch(regex_md_img, contents)) do m
                joinpath(root, m.captures[1])
            end
            filter!(isfile, image_paths)

            return isempty(image_paths) ? nothing : first(image_paths)
        end
    elseif key == "id"
        haskey(config, key) || return get_default_id(card)

        id = config[key]
        validate_id(id, card)
        return id
    elseif key == "title"
        return get(config, key) do
            name_without_ext = splitext(basename(card))[1]
            uppercasefirst(name_without_ext)
        end
    else
        throw("Unrecognized key $(key) for MarkdownDemoCard")
    end
end

function get_default_id(card::MarkdownDemoCard)
    name_without_ext = splitext(basename(card))[1]
    replace(lowercase(name_without_ext), ' ' => '_')
end

function parse(card::MarkdownDemoCard)
    # TODO: we don't actually need to read the whole file
    contents = split(read(card.path, String), "---\n")
    length(contents) == 1 ? Dict() : YAML.load(strip(contents[2]))
end
