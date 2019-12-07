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
const regex_md_img = r"^\s*!\[(?<title>[^\]]*)\]\((?<path>[^\s]*)\)"

# markdown image format in Literate: # ![title](path)
const regex_jl_img = r"^#!?[<src><jl><nb><md>]?\s+!\[(?<title>[^\]]*)\]\((?<path>[^\s]*)\)"

# YAML frontmatter
# 1. markdown: ---
# 2. julia: # ---
const regex_yaml = r"^#?\s*---"

# markdown title syntax:
# 1. # title
# 2. # [title](@id id)
const regex_md_simple_title = r"\s*#+\s*(?<title>[^\[\]]+)"
const regex_md_title = r"\s*#+\s*\[(?<title>[^\]]+)\]\(\@id\s+(?<id>[^\s\)]+)\)"

# markdown title syntax for julia:
# 1. # # title
# 2. #md # title
# 3. #!jl # title
const regex_jl_simple_title = r"\s*#!?[<src><jl><nb><md>]?\s+#+\s*(?<title>[^#\[\]]+)"
const regex_jl_title = r"\s*#!?[<src><jl><nb><md>]?\s+#+\s*\[(?<title>[^\]]+)\]\(\@id\s+(?<id>[^\s\)]+)\)"

# markdown content
# lines that are not title, image, link, list
const regex_md_content = r"^\s*(?<content>[^#-*!<\d\.>].*)"
const regex_jl_content = r"^\s*#\s+(?<content>[^#-\*!<\d\.>][^#]+)"

# markdown URL: [text](url)
const regex_md_url = r"\[(?<text>[^\]]*)\]\((?<url>[^\)]*)\)"

"""
    parse_markdown(contents)
    parse_markdown(path::String)

parse markdown contents and return a configuration dict.

Currently supported items are: `title`, `id`, `cover`, `description`.
"""
function parse_markdown(contents::String)
    contents = isfile(contents) ? read(contents, String) : contents
    parse_markdown(split(contents, "\n"))
end

function parse_markdown(contents::AbstractArray{<:AbstractString})::Dict
    config = Dict()
    _, contents = split_frontmatter(contents) # drop frontmatter

    # The first title line in markdown format is parse out as the title
    title_matches = map(contents) do line
        # try to match the most complicated pattern first
        m = match(regex_md_title, line)
        m isa RegexMatch && return m
        m = match(regex_md_simple_title, line)
        m isa RegexMatch && return m
        return nothing
    end
    title_lines = findall(map(x->x isa RegexMatch, title_matches))
    if !isempty(title_lines)
        m = title_matches[title_lines[1]]
        title = m["title"]
        if length(m.captures) == 1
            # default documenter id has -1 suffix
            id = replace(title, ' ' => '-') * "-1"
        elseif length(m.captures) == 2
            id = m.captures[2]
        else
            error("Unrecognized regex format $(m.regex)")
        end
        merge!(config, Dict("title"=>title, "id"=>id))
    end

    # The first valid image link is parsed out as card cover
    image_matches = map(contents) do line
        m = match(regex_md_img, line)
        m isa RegexMatch && return m
        return nothing
    end
    image_lines = findall(map(x->x isa RegexMatch, image_matches))
    if !isempty(image_lines)
        config["cover"] = image_matches[image_lines[1]]["path"]
    end

    description = parse_description(contents, regex_md_content)
    if !isnothing(description)
        config["description"] = description
    end

    return config
end


function parse_julia(contents::String)
    contents = isfile(contents) ? read(contents, String) : contents
    parse_julia(split(contents, "\n"))
end

function parse_julia(contents::AbstractArray{<:AbstractString})::Dict
    config = Dict()
    _, contents = split_frontmatter(contents) # drop frontmatter

    # The first title line in markdown format is parse out as the title
    title_matches = map(contents) do line
        # try to match the most complicated pattern first
        m = match(regex_jl_title, line)
        m isa RegexMatch && return m
        m = match(regex_jl_simple_title, line)
        m isa RegexMatch && return m
        return nothing
    end
    title_lines = findall(map(x->x isa RegexMatch, title_matches))
    if !isempty(title_lines)
        m = title_matches[title_lines[1]]
        title = m["title"]
        if length(m.captures) == 1
            # default documenter id has -1 suffix
            id = replace(title, ' ' => '-') * "-1"
        elseif length(m.captures) == 2
            id = m.captures[2]
        else
            error("Unrecognized regex format $(m.regex)")
        end
        merge!(config, Dict("title"=>title, "id"=>id))
    end

    # The first valid image link is parsed out as card cover
    image_matches = map(contents) do line
        m = match(regex_jl_img, line)
        m isa RegexMatch && return m
        return nothing
    end
    image_lines = findall(map(x->x isa RegexMatch, image_matches))
    if !isempty(image_lines)
        config["cover"] = image_matches[image_lines[1]]["path"]
    end

    description = parse_description(contents, regex_jl_content)
    if !isnothing(description)
        config["description"] = description
    end

    return config
end

function get_default_title(x::Union{AbstractDemoCard, DemoSection, DemoPage})
    name_without_ext = splitext(basename(x))[1]
    strip(replace(uppercasefirst(name_without_ext), r"[_-]" => " "))
end


get_default_description(card::AbstractDemoCard) = card.title

function parse_description(contents::AbstractArray{<:AbstractString}, regex)
    # description as the first paragraph that is not a title, image, list or codes
    content_lines = map(x->match(regex, x) isa RegexMatch, contents)
    code_lines = findall(map(x->startswith(lstrip(x), "```"), contents))
    for (i,j) in zip(code_lines[1:2:end], code_lines[2:2:end])
        # mark code lines as non-content lines
        content_lines[i:j] .= 0
    end
    m = findall(content_lines)
    isempty(m) && return nothing

    paragraph_line = findall(x->x!=1, diff(m))
    offset = isempty(paragraph_line) ? length(m) : paragraph_line[1]
    description = join(map(x->lstrip(x, ('#', ' ')), contents[m[1:offset]]), " ")
    return replace(description, regex_md_url => s"\g<text>")
end


"""
    split_frontmatter(contents) -> frontmatter, body

splits the YAML frontmatter out from markdown and julia source code. Leading `# ` will be
stripped for julia codes.

`contents` can be `String` or vector of `String`. Outputs have the same type of `contents`.
"""
function split_frontmatter(contents::String)
    frontmatter, body = split_frontmatter(split(contents, "\n"))
    return join(frontmatter, "\n"), join(body, "\n")
end
function split_frontmatter(contents::AbstractArray{<:AbstractString})
    offsets = map(contents) do line
        m = match(regex_yaml, line)
        m isa RegexMatch
    end
    offsets = findall(offsets)
    if !isempty(offsets)
        # anything before frontmatter is thrown away
        frontmatter = map(x->lstrip(x, ('#', ' ')), contents[offsets[1]: offsets[2]])
        body = contents[offsets[2]+1:end]
    else
        frontmatter = ""
        body = contents
    end
    return frontmatter, body
end
