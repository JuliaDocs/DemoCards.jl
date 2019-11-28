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
        offset = findall(x->x=="# ---", contents)[2]
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