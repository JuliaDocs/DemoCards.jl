const julia_exts = [".jl",]

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
    contents = readlines(card.path)
    offsets = map(contents) do line
        m = match(regex_jl_yaml, line)
        m isa RegexMatch
    end
    if !isempty(offsets) && offsets[1]==1
        offset = findall(offsets)[2]
        frontmatter = map(x->lstrip(x, '#'), contents[2:offset-1])
        config = YAML.load(join(frontmatter, "\n"))
        haskey(config, "cover") && isfile(config["cover"]) || delete!(config, "cover")

        body = contents[offset+1:end]
    else
        config = Dict()
        body = contents
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
    save_democards(root::String, card::JuliaDemoCard)

process the original julia file and save it.

The processing pipeline is:

1. preprocess and copy source file
2. generate ipynb file
3. generate markdown file
4. insert header and footer to generated markdown file
"""
function save_democards(root::String, card::JuliaDemoCard)
    isdir(root) || mkpath(root)
    cardname = splitext(basename(card.path))[1]
    md_path = joinpath(root, "$(cardname).md")
    nb_path = joinpath(root, "$(cardname).ipynb")
    src_path = joinpath(root, "$(cardname).jl")


    # 1. generating assets
    cp(card.path, src_path; force=true)
    project_dir = joinpath(pwd(), "docs")
    cd(root) do
        # TODO: this requires documentation build in a standard way, i.e., 
        # `julia --project=docs/ docs/make.jl`
        if Sys.isunix()
            cmd = `julia --project=$(project_dir) $(cardname).jl`
        elseif Sys.iswindows()
            cmd = `julia.exe --project=$(project_dir) $(cardname).jl`
        else
            error("path primitives for this OS need to be defined")
        end
        # trigger an independent process to generate assets, and reconfigure cards
        # WARNING: card.path is modified here
        try
            run(cmd)
            card.path = cardname*".jl"
            card.cover = load_config(card, "cover")
            card.path = src_path
        catch err
            @warn "Executing demo $(card.path) fails."
        end
    end

    # remove YAML frontmatter
    contents = readlines(src_path)
    offsets = map(contents) do line
        m = match(regex_jl_yaml, line)
        m isa RegexMatch
    end
    if !isempty(offsets) && offsets[1]==1
        offset = findall(offsets)[2]+1
        body = join(contents[offset:end], "\n")
    else
        body = join(contents, "\n")
    end
    write(src_path, body)

    # trigger an independent julia process and generate potential assets
    project_dir = joinpath(pwd(), "docs")
    cd(root) do
        if Sys.isunix()
            cmd = `julia --project=$(project_dir) $(cardname).jl`
        elseif Sys.iswindows()
            cmd = `julia.exe --project=$(project_dir) $(cardname).jl`
        else
            error("path primitives for this OS need to be defined")
        end
        run(cmd)
    end

    # 2. notebook
    @suppress Literate.notebook(src_path, root)

    # 3. markdown
    @suppress Literate.markdown(src_path, root) # output filename is md_path
    # remove meta info and footer generated by Literate.jl
    contents = readlines(md_path)
    offsets = findall(x->startswith(x, "```"), contents)
    body = join(contents[offsets[2]+1:end-2], "\n") # TODO: make index less magical

    # 4. insert header and footer to generated markdown file

    # @ref syntax: https://juliadocs.github.io/Documenter.jl/stable/man/syntax/#@ref-link-1
    header = "# [$(card.title)](@id $(card.id))\n"

    footer = "\n---\n"
    footer *= "\nDownload: " *
              "[source]($(cardname).jl), " *
              "[notebook]($(cardname).ipynb)" * "\n"
    footer *= "\n*This page was generated using " *
              "[DemoCards.jl](https://github.com/johnnychen94/DemoCards.jl)" *
              " and " *
              "[Literate.jl](https://github.com/fredrikekre/Literate.jl).*\n"
    write(md_path, header, body, footer)

    # 5. filter out source file
    @suppress Literate.script(src_path, root)
end
