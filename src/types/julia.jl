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
    card.title = load_config(card, "title")
    # default id requires a title
    card.id    = load_config(card, "id")
    # default description requires a title
    card.description = load_config(card, "description")
    return card
end


"""
    save_democards(card_dir::String, card::JuliaDemoCard;
                   project_dir,
                   src,
                   credit,
                   nbviewer_root_url)

process the original julia file and save it.

The processing pipeline is:

1. preprocess and copy source file
2. generate ipynb file
3. generate markdown file
4. insert header and footer to generated markdown file
"""
function save_democards(card_dir::String,
                        card::JuliaDemoCard;
                        credit,
                        nbviewer_root_url,
                        project_dir=Base.source_dir(),
                        src="src",
                        kwargs...)
    isdir(card_dir) || mkpath(card_dir)
    cardname = splitext(basename(card.path))[1]
    md_path = joinpath(card_dir, "$(cardname).md")
    nb_path = joinpath(card_dir, "$(cardname).ipynb")
    src_path = joinpath(card_dir, "$(cardname).jl")

    # 1. generating assets
    cp(card.path, src_path; force=true)
    cd(card_dir) do
        try
            foreach(ignored_dirnames) do x
                isdir(x) || mkdir(x)
            end

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
            # throw warnings when generating notebooks
            err isa LoadError || rethrow(err)
        end
    end

    # remove YAML frontmatter
    _, body = split_frontmatter(read(src_path, String))

    # insert header badge
    if !isempty(nbviewer_root_url)
        # reach here in CI environment
        # remove root/src prefix
        _card_dir = replace(card_dir, Base.Filesystem.path_separator => "/") # windows CI support
        _, nbviewer_folder = split(_card_dir, "$project_dir/$src"; limit=2)
        nbviewer_folder = strip(nbviewer_folder, '/')
        nbviewer_url = "$(nbviewer_root_url)/$(nbviewer_folder)/$(cardname).ipynb"
    else
        # local build
        nbviewer_url = "$(cardname).ipynb"
    end
    header = "#md # [![]($download_badge)]($(cardname).jl) [![]($nbviewer_badge)]($nbviewer_url)"
    header *= "\n\n"

    write(src_path, header, body)

    # 2. notebook
    try
        @suppress Literate.notebook(src_path, card_dir; credit=credit)
    catch err
        @warn err.msg
    end

    # 3. markdown
    @suppress Literate.markdown(src_path, card_dir; credit=false) # manually add credit later
    # remove meta info generated by Literate.jl
    contents = readlines(md_path)
    offsets = findall(x->startswith(x, "```"), contents)
    body = join(contents[offsets[2]+1:end], "\n")

    # 4. insert header and footer to generated markdown file
    config = parse(Val(:Julia), body)
    need_header = !haskey(config, "title")
    # @ref syntax: https://juliadocs.github.io/Documenter.jl/stable/man/syntax/#@ref-link-1
    header = need_header ? "# [$(card.title)](@id $(card.id))\n" : ""
    footer = credit ? julia_footer : ""
    write(md_path, header, body, footer)

    # 5. filter out source file
    @suppress Literate.script(src_path, card_dir; credit=credit)
end
