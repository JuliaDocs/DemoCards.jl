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

# YAML frontmatter
# 1. markdown: ---
# 2. julia: # ---
const regex_yaml = r"^#?\s*---"

# markdown title syntax:
# 1. # title
# 2. # [title](@id id)
const regex_md_simple_title = r"^\s*#\s*([^\[\]\n\r]+)"
const regex_md_title = r"^\s*#\s*\[([^\]]+)\]\(\@id\s+([^\s\)\n\r]+)\)"

# markdown content
# lines that are not title, image, link, list
const regex_md_content = r"^\s*(?<content>[^#-*!<\d\.>].*)"
const regex_jl_content = r"^\s*#\s*(?<content>[^#-\*!<\d\.>][^#]+)"

# markdown URL: [text](url)
const regex_md_url = r"\[(?<text>[^\]]*)\]\((?<url>[^\)]*)\)"

"""
    parse_markdown(contents::String)
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

function get_default_title(x::Union{AbstractDemoCard, DemoSection, DemoPage})
    name_without_ext = splitext(basename(x))[1]
    strip(replace(uppercasefirst(name_without_ext), r"[_-]" => " "))
end


get_default_description(card::MarkdownDemoCard) = get_default_description(card, regex_md_content)
get_default_description(card::JuliaDemoCard) = get_default_description(card, regex_jl_content)
function get_default_description(card::AbstractDemoCard, regex_content)
    # description as the first paragraph that is not a title, image, list or codes
    _, body = split_frontmatter(readlines(card.path))
    m = findall(map(x->match(regex_content, x) isa RegexMatch, body))
    isempty(m) && return card.title

    paragraph_line = findall(x->x!=1, diff(m))
    offset = isempty(paragraph_line) ? length(m) : paragraph_line[1]
    description = join(map(x->lstrip(x, ('#', ' ')), body[m[1:offset]]), " ")
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
