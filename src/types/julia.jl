const julia_exts = [".jl",]
const nbviewer_badge = "https://img.shields.io/badge/show-nbviewer-579ACA.svg"
const download_badge = "https://img.shields.io/badge/download-julia-brightgreen.svg"
const julia_footer = raw"""
---

*This page was generated using [DemoCards.jl](https://github.com/johnnychen94/DemoCards.jl) and [Literate.jl](https://github.com/fredrikekre/Literate.jl).*


"""


"""
    struct JuliaDemoCard <: AbstractDemoCard
    JuliaDemoCard(path::String)

Constructs a julia-format demo card from existing julia file `path`.

The julia file is written in [Literate syntax](https://fredrikekre.github.io/Literate.jl/stable/fileformat).

# Fields

Besides `path`, this struct has some other fields:

* `path`: path to the source julia file
* `cover`: path to the cover image
* `id`: cross-reference id
* `title`: one-line description of the demo card
* `description`: multi-line description of the demo card

# Configuration

You can pass additional information by adding a YAML front matter to the julia file.
Supported items are:

* `cover`: relative path to the cover image. If not specified, it will use the first available image link, or all-white image if there's no image links.
* `description`: a multi-line description to this file, will be displayed when the demo card is hovered. By default it uses `title`.
* `id`: specify the `id` tag for cross-references. By default it's infered from the filename, e.g., `simple_demo` from `simple demo.md`.
* `title`: one-line description to this file, will be displayed under the cover image. By default, it's the name of the file (without extension).

An example of the front matter (note the leading `#`):

```julia
# ---
# title: passing extra information
# cover: cover.png
# id: non_ambiguious_id
# description: this demo shows how you can pass extra demo information to DemoCards package.
# ---
```

See also: [`MarkdownDemoCard`](@ref DemoCards.MarkdownDemoCard), [`DemoSection`](@ref DemoCards.DemoSection), [`DemoPage`](@ref DemoCards.DemoPage)
"""
mutable struct JuliaDemoCard <: AbstractDemoCard
    path::String
    cover::Union{String, Nothing}
    id::String
    title::String
    description::String
end

function JuliaDemoCard(path::String)::JuliaDemoCard
    # first consturct an incomplete democard, and then load the config
    card = JuliaDemoCard(path, "", "", "", "")

    card.cover = load_config(card, "cover")
    card.id    = load_config(card, "id")
    card.title = load_config(card, "title")

    # default description requires a title
    card.description = load_config(card, "description")
    return card
end

function parse(card::JuliaDemoCard)
    frontmatter, body = split_frontmatter(readlines(card.path))
    if !isempty(frontmatter)
        config = YAML.load(join(frontmatter, "\n"))
        haskey(config, "cover") && isfile(config["cover"]) || delete!(config, "cover")
    else
        config = Dict()
    end

    if !haskey(config, "cover")
        # set the first valid image path as cover
        # TODO: only markdown syntax is supported now
        image_paths = map(body) do line
            m = match(regex_jl_img, line)
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
    save_democards(root::String, card::JuliaDemoCard; credit, nbviewer_root_url)

process the original julia file and save it.

The processing pipeline is:

1. preprocess and copy source file
2. generate ipynb file
3. generate markdown file
4. insert header and footer to generated markdown file
"""
function save_democards(root::String,
                        card::JuliaDemoCard;
                        credit,
                        nbviewer_root_url,
                        kwargs...)
    isdir(root) || mkpath(root)
    cardname = splitext(basename(card.path))[1]
    md_path = joinpath(root, "$(cardname).md")
    nb_path = joinpath(root, "$(cardname).ipynb")
    src_path = joinpath(root, "$(cardname).jl")


    # 1. generating assets
    cp(card.path, src_path; force=true)
    project_dir = joinpath(pwd(), "docs")
    cd(root) do
        try
            # run scripts in a sandbox
            m = Module(gensym())
            # modules created with Module() does not have include defined
            # abspath is needed since this will call `include_relative`
            Core.eval(m, :(include(x) = Base.include($m, abspath(x))))
            Core.eval(m, :(include($cardname * ".jl")))

            # WARNING: card.path is modified here
            card.path = cardname*".jl"
            card.cover = load_config(card, "cover")
            card.path = src_path
        catch err
            @warn "Executing demo $(card.path) fails."
        end
    end

    # remove YAML frontmatter
    _, body = split_frontmatter(read(src_path, String))

    # insert header badge
    if !isempty(nbviewer_root_url)
        nbviewer_folder = join(splitpath(root)[3:end], "/") # remove docs/src prefix
        nbviewer_url = "$(nbviewer_root_url)/$(nbviewer_folder)/$(cardname).ipynb"
    else
        nbviewer_url = "$(cardname).ipynb"
    end
    header = "#md # [![]($download_badge)]($(cardname).jl) [![]($nbviewer_badge)]($nbviewer_url)"
    header *= "\n\n"

    write(src_path, header, body)

    # 2. notebook
    @suppress Literate.notebook(src_path, root; credit=credit)

    # 3. markdown
    @suppress Literate.markdown(src_path, root; credit=false) # manually add credit later
    # remove meta info generated by Literate.jl
    contents = readlines(md_path)
    offsets = findall(x->startswith(x, "```"), contents)
    body = join(contents[offsets[2]+1:end], "\n")

    # 4. insert header and footer to generated markdown file

    # @ref syntax: https://juliadocs.github.io/Documenter.jl/stable/man/syntax/#@ref-link-1
    header = "# [$(card.title)](@id $(card.id))\n"
    footer = credit ? julia_footer : ""
    write(md_path, header, body, footer)

    # 5. filter out source file
    @suppress Literate.script(src_path, root; credit=credit)
end
