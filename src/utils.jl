function validate_file(path, filetype = :text)
    isfile(path) || throw(ArgumentError("$(path) is not a valid file"))
    check_ext(path, filetype)
end

function check_ext(path, filetype = :text)
    _, ext = splitext(path)
    if filetype == :text
        return true
    elseif filetype == :markdown
        return lowercase(ext) in markdown_exts || throw(ArgumentError("$(path) is not a valid markdown file"))
    else
        throw(ArgumentError("Unrecognized filetype $(filetype)"))
    end
end

### common utils for DemoPage and DemoSection

function validate_order(order::AbstractArray, x::Union{DemoPage, DemoSection})
    default_order = get_default_order(x)
    if intersect(order, default_order) == union(order, default_order)
        return true
    else
        config_filepath = joinpath(x.root, config_filename)

        entries = join(string.(setdiff(order, default_order)), "\n")
        isempty(entries) || @warn("The following entries in $(config_filepath) are not used anymore:\n$(entries)")

        entries = join(string.(setdiff(default_order, order)), "\n")
        isempty(entries) || @warn("The following entries in $(config_filepath) are missing:\n$(entries)")

        throw(ArgumentError("incorrect order in $(config_filepath), please check the previous warning message."))
    end
end

"""return a flattened list of democards"""
flatten(page::DemoPage) = vcat(flatten.(page.sections)...)
function flatten(sec::DemoSection)
    if isempty(sec.cards)
        return vcat(flatten.(sec.subsections)...)
    else
        return sec.cards
    end
end

### regexes

# markdown image syntax: ![title](path)
const regex_md_img = r"^\s*\!\[[^\]]*\]\(([^\s]*)\)"

# markdown image format in Literate: # ![title](path)
const regex_jl_img = r"^[#\w*\s*]*\!\[[^\]]*\]\(([^\s]*)\)"

# markdown title syntax:
# 1. # title
# 2. # [title](@id id)
const regex_md_simple_title = r"^\s*#\s*([^\[\]\n]+)"
const regex_md_title = r"^\s*#\s*\[([^\]]+)\]\(\@id\s+([^\s\)\n]+)\)"


"""
    parse_markdown(contenst::String)
    parse_markdown(path::String)

parse the template file of page and return a configuration dict.

Currently supported items are: `title`, `id`.
"""
function parse_markdown(contents::String)::Dict
    # TODO: this function isn't good; it just works
    if isfile(contents)
        contents = read(contents, String)
    end

    m = match(regex_md_title, contents)
    if !isnothing(m)
        return Dict("title"=>m.captures[1], "id"=>m.captures[2])
    end

    m = match(regex_md_simple_title, contents)
    if !isnothing(m)
        title = m.captures[1]
        # default documenter id has -1 suffix
        id = replace(title, ' ' => '-') * "-1"
        # id = replace(id, '\`' => '')
        # id = strip(id, '-')
        return Dict("title"=>title, "id"=>id)
    end

    return Dict()
end
