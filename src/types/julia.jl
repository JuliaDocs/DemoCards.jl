const julia_exts = [".jl",]

struct JuliaDemoCard <: AbstractDemoCard
    path::String
    cover::Union{String, Nothing}
    id::String
    title::String
    description::String
end

function JuliaDemoCard(path::String)::JuliaDemoCard
    # first consturct an incomplete democard, and then load the config
    card = JuliaDemoCard(path, "", "", "", "")

    cover = load_config(card, "cover")
    id    = load_config(card, "id")
    title = load_config(card, "title")
    card = JuliaDemoCard(path, cover, id, title, "")

    # default description requires a title
    description = load_config(card, "description")
    JuliaDemoCard(path, cover, id, title, description)
end

function parse(card::JuliaDemoCard)
    contents = readlines(card.path)
    if contents[1] == "# ---"
        # start with a YAML format meta data
        offset = findall(x->x=="# ---", contents)[2] # TODO: support "#---"
        frontmatter = map(x->lstrip(x, '#'), contents[2:offset-1])
        config = YAML.load(join(frontmatter, "\n"))

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

    # 1. source file
    contents = readlines(card.path)
    offsets = findall(x->x=="# ---", contents) # TODO: support "#---"
    body = isempty(offsets) ? contents : contents[offsets[2]+1:end]
    body = join(body, "\n")
    write(src_path, body)

    # TODO: run source file once to generate potential assets

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
    @suppress Literate.source(src_path, root)
end