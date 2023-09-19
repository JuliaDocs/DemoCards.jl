const julia_exts = [".jl",]
const nbviewer_badge = "https://img.shields.io/badge/show-nbviewer-579ACA.svg"
const download_badge = "https://img.shields.io/badge/download-julia-brightgreen.svg"
const julia_footer = raw"""

---

*This page was generated using [DemoCards.jl](https://github.com/JuliaDocs/DemoCards.jl) and [Literate.jl](https://github.com/fredrikekre/Literate.jl).*


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
* `author`: author(s) of this demo.
* `date`: the update date of this demo.
* `description`: multi-line description of the demo card
* `julia`: Julia version compatibility
* `hidden`: whether this card is shown in the generated index page
* `notebook`: enable or disable the jupyter notebook generation. Valid values are `true` or `false`.
* `generate_cover` whether to generate a cover image for this demo card by executing it
* `execute`: whether to execute the demo card when generating the notebook

# Configuration

You can pass additional information by adding a YAML front matter to the julia file.
Supported items are:

* `cover`: an URL or a relative path to the cover image. If not specified, it will use the first available image link, or all-white image if there's no image links.
* `description`: a multi-line description to this file, will be displayed when the demo card is hovered. By default it uses `title`.
* `id`: specify the `id` tag for cross-references. By default it's infered from the filename, e.g., `simple_demo` from `simple demo.md`.
* `title`: one-line description to this file, will be displayed under the cover image. By default, it's the name of the file (without extension).
* `author`: author name. If there are multiple authors, split them with semicolon `;`.
* `date`: any string contents that can be passed to `Dates.DateTime`. For example, `2020-09-13`.
* `julia`: Julia version compatibility. Any string that can be converted to `VersionNumber`
* `hidden`: whether this card is shown in the layout of index page. The default value is `false`.
* `generate_cover` whether to generate a cover image for this demo card by executing it. The default value is `true` when `cover` is not given otherwise `false`. Note that `execute` must also be `true` for this to take effect.
* `execute`: whether to execute the demo card when generating the notebook. The default value is `true`.

An example of the front matter (note the leading `#`):

```julia
# ---
# title: passing extra information
# cover: cover.png
# id: non_ambiguious_id
# author: Jane Doe; John Roe
# date: 2020-01-31
# description: this demo shows how you can pass extra demo information to DemoCards package. All these are optional.
# julia: 1.0
# hidden: false
# ---
```

See also: [`MarkdownDemoCard`](@ref DemoCards.MarkdownDemoCard), [`PlutoDemoCard`](@ref DemoCards.PlutoDemoCard), [`DemoSection`](@ref DemoCards.DemoSection), [`DemoPage`](@ref DemoCards.DemoPage)
"""
mutable struct JuliaDemoCard <: AbstractDemoCard
    path::String
    cover::Union{String, Nothing}
    id::String
    title::String
    description::String
    author::String
    date::DateTime
    julia::VersionNumber
    hidden::Bool
    notebook::Union{Nothing, Bool}
    generate_cover::Bool
    execute::Bool
end

function JuliaDemoCard(path::String)::JuliaDemoCard
    # first consturct an incomplete democard, and then load the config
    card = JuliaDemoCard(path, "", "", "", "", "", DateTime(0), JULIA_COMPAT, false, nothing, true, true)

    config = parse(card)
    card.cover = load_config(card, "cover"; config=config)
    card.title = load_config(card, "title"; config=config)
    card.date = load_config(card, "date"; config=config)
    card.author = load_config(card, "author"; config=config)
    card.julia = load_config(card, "julia"; config=config)
    # default id requires a title
    card.id    = load_config(card, "id"; config=config)
    # default description requires a title
    card.description = load_config(card, "description"; config=config)
    card.hidden = load_config(card, "hidden"; config=config)

    # Because we want bottom-level cards configuration to have higher priority, figuring
    # out the default `notebook` option needs a reverse walk from top-level page to the
    # bottom-level card.
    if haskey(config, "notebook")
        notebook = config["notebook"]
        if notebook isa Bool
            card.notebook = notebook
        else
            card.notebook = try
                parse(Bool, lowercase(notebook))
            catch err
                @warn "`notebook` option should be either `\"true\"` or `\"false\"`, instead it is: $notebook. Fallback to unconfigured."
                nothing
            end
        end
    end
    card.generate_cover = load_config(card, "generate_cover"; config=config)
    card.execute = load_config(card, "execute"; config=config)

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
                        throw_error = false,
                        properties = Dict{String, Any}(),
                        kwargs...)
    isdir(card_dir) || mkpath(card_dir)
    @debug card.path
    original_card_path = card.path
    cardname = splitext(basename(card.path))[1]
    md_path = joinpath(card_dir, "$(cardname).md")
    nb_path = joinpath(card_dir, "$(cardname).ipynb")
    src_path = joinpath(card_dir, "$(cardname).jl")

    if VERSION < card.julia
        # It may work, it may not work; I hope it would work.
        @warn "The running Julia version `$(VERSION)` is older than the declared compatible version `$(card.julia)`. You might need to upgrade your Julia."
    end

    card.notebook = if isnothing(card.notebook)
        # Backward compatibility: we used to generate notebooks for all jl files
        op = get(properties, "notebook", "true")
        op = isa(op, Bool) ? op : try
            Base.parse(Bool, lowercase(op))
        catch err
            @warn "`notebook` option should be either `\"true\"` or `\"false\"`, instead it is: $op. Fallback to \"true\"."
            true
        end
    else
        card.notebook
    end
    @assert !isnothing(card.notebook)

    # 1. generating assets
    cp(card.path, src_path; force=true)
    cd(card_dir) do
        try
            foreach(ignored_dirnames) do x
                isdir(x) || mkdir(x)
            end

            if (card.generate_cover && card.execute)
                # run scripts in a sandbox
                m = Module(gensym())
                # modules created with Module() does not have include defined
                # abspath is needed since this will call `include_relative`
                Core.eval(m, :(include(x) = Base.include($m, abspath(x))))
                gen_assets() = Core.eval(m, :(include($cardname * ".jl")))
                verbose_mode() ? gen_assets() : @suppress gen_assets()
            end

            # WARNING: card.path is modified here
            card.path = cardname*".jl"
            card.cover = load_config(card, "cover")
            card.path = src_path

            foreach(ignored_dirnames) do x
                isempty(readdir(x)) && rm(x; recursive=true, force=true)
            end
        catch err
            if err isa LoadError
                # TODO: provide more informative debug message
                @warn "something wrong during the assets generation for demo $cardname.jl"
                if throw_error
                    rethrow(err)
                else
                    @warn err
                end
            else
                rethrow(err)
            end
        end
    end

    # remove YAML frontmatter
    src_header, _, body = split_frontmatter(read(src_path, String))
    isempty(strip(src_header)) || (src_header *= "\n\n")

    # insert header badge
    badges = make_badges(card;
                         src=src,
                         card_dir=card_dir,
                         nbviewer_root_url=nbviewer_root_url,
                         project_dir=project_dir,
                         build_notebook=card.notebook) 
    write(src_path, badges * "\n\n", body)

    # 2. notebook
    if card.notebook
        try
            @suppress Literate.notebook(src_path, card_dir; credit=credit, execute=card.execute)
        catch err
            nothing # There are already early warning in the assets generation
        end
    end

    # 3. markdown
    md_kwargs = Dict()
    if card.execute
        md_kwargs[:execute] = true
    else
        md_kwargs[:codefence] = ("````julia" => "````")
    end
    @suppress Literate.markdown(src_path, card_dir; credit=false, md_kwargs...) # manually add credit later
    # remove meta info generated by Literate.jl
    contents = readlines(md_path)
    offsets = findall(x->startswith(x, "```"), contents)
    body = join(contents[offsets[2]+1:end], "\n")

    # 4. insert header and footer to generated markdown file
    config = parse(Val(:Julia), body)
    need_header = !haskey(config, "title")
    # @ref syntax: https://juliadocs.github.io/Documenter.jl/stable/man/syntax/#@ref-link-1
    header = need_header ? "# [$(card.title)](@id $(card.id))\n" : "\n"
    footer = credit ? julia_footer : "\n"
    write(md_path, meta_edit_url(original_card_path), header, body, footer)

    # 5. filter out source file
    mktempdir(card_dir) do tmpdir
        @suppress Literate.script(src_path, tmpdir; credit=credit)
        write(src_path, src_header, read(joinpath(tmpdir, basename(src_path)), String))
    end
end

function make_badges(card::JuliaDemoCard; src, card_dir, nbviewer_root_url, project_dir, build_notebook)
    cardname = splitext(basename(card.path))[1]
    badges = ["#md #"]
    push!(badges, "[![Source code]($download_badge)]($(cardname).jl)")

    if build_notebook
        if !isempty(nbviewer_root_url)
            # Note: this is only reachable in CI environment
            nbviewer_folder = normpath(relpath(card_dir, "$project_dir/$src"))
            nbviewer_url = replace("$(nbviewer_root_url)/$(nbviewer_folder)/$(cardname).ipynb", Base.Filesystem.path_separator=>'/')
        else
            nbviewer_url = "$(cardname).ipynb"
        end
        push!(badges, "[![notebook]($nbviewer_badge)]($nbviewer_url)")
    end
    if card.julia != JULIA_COMPAT
        # It might be over verbose to insert a compat badge for every julia card, only add one for
        # cards that users should care about
        # Question: Is this too conservative?
        push!(badges, "![compat](https://img.shields.io/badge/julia-$(card.julia)-blue.svg)")
    end

    push!(badges, invoke(make_badges, Tuple{AbstractDemoCard}, card))

    join(badges, " ")
end
