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


### regexes and configuration parsers

raw"""
    get_regex(card::AbstractDemoCard, regex_type)

Return regex used to parse `card`.

`regex_type` and capture fields:

* `:image`: $1=>title, $2=>path
* `:title`: $1=>title, (Optionally, $2=>id)
* `:content`: $1=>content
"""
function get_regex(::Val{:Markdown}, regex_type)
    if regex_type == :image
        # Example: ![title](path)
        return r"^\s*!\[(?<title>[^\]]*)\]\((?<path>[^\s]*)\)"
    elseif regex_type == :title
        # Example: # [title](@id id)
        regex_title = r"\s*#+\s*\[(?<title>[^\]]+)\]\(\@id\s+(?<id>[^\s\)]+)\)"
        # Example: # title
        regex_simple_title = r"\s*#+\s*(?<title>[^#]+)"
        
        # Note: return complicated one first
        return (regex_title, regex_simple_title)
    elseif regex_type == :content
        # lines that are not title, image, link, list
        # FIXME: list is also captured by this regex
        return r"^\s*(?<content>[^#\-*!].*)"
    else
        error("Unrecognized regex type: $(regex_type)")
    end
end

function get_regex(::Val{:Julia}, regex_type)
    if regex_type == :image
        # Example: #md ![title](path)
        return r"^#!?\w*\s+!\[(?<title>[^\]]*)\]\((?<path>[^\s]*)\)"
    elseif regex_type == :title
        # Example: # [title](@id id)
        regex_title = r"\s*#!?\w*\s+#+\s*\[(?<title>[^\]]+)\]\(\@id\s+(?<id>[^\s\)]+)\)"
        # Example: # title
        regex_simple_title = r"\s*#!?\w*\s+#+\s*(?<title>[^#]+)"
        
        # Note: return complicated one first
        return (regex_title, regex_simple_title)
    elseif regex_type == :content
        # lines that are not title, image, link, list
        # FIXME: list is also captured by this regex
        return r"^\s*#!?\w*\s+(?<content>[^#\-\*!]+)"
    else
        error("Unrecognized regex type: $(regex_type)")
    end
end


# YAML frontmatter
# 1. markdown: ---
# 2. julia: # ---
const regex_yaml = r"^#?\s*---"

# markdown URL: [text](url)
const regex_md_url = r"\[(?<text>[^\]]*)\]\((?<url>[^\)]*)\)"


"""
    parse([T::Val], card::AbstractDemoCard)
    parse(T::Val, contents)
    parse(T::Val, path)

Parse the content of `card` and return the configuration.

Currently supported items are: `title`, `id`, `cover`, `description`.

!!! note

    Users of this function need to use `haskey` to check if keys are existed.
    They also need to validate the values.
"""
function parse(T::Val, card::AbstractDemoCard)
    frontmatter, body = split_frontmatter(readlines(card.path))
    config = parse(T, body)
    # frontmatter has higher priority
    if !isempty(frontmatter)
        merge!(config, YAML.load(join(frontmatter, "\n")))
    end

    if haskey(config, "cover")
        config["cover"] = replace(config["cover"],
                                  r"[/\\]" => Base.Filesystem.path_separator) # windows compatibility
    end

    return config
end
parse(card::JuliaDemoCard) = parse(Val(:Julia), card)
parse(card::MarkdownDemoCard) = parse(Val(:Markdown), card)


function parse(T::Val, contents::String)
    contents = isfile(contents) ? read(contents, String) : contents
    parse(T, split(contents, "\n"))
end
function parse(T::Val, contents::AbstractArray{<:AbstractString})::Dict
    config = Dict()
    _, contents = split_frontmatter(contents) # drop frontmatter

    # The first title line in markdown format is parse out as the title
    title_matches = map(contents) do line
        # try to match the most complicated pattern first
        for re in get_regex(T, :title)
            m = match(re, line)
            m isa RegexMatch && return m
        end
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
        m = match(get_regex(T, :image), line)
        m isa RegexMatch && return m
        return nothing
    end
    image_lines = findall(map(x->x isa RegexMatch, image_matches))
    if !isempty(image_lines)
        config["cover"] = image_matches[image_lines[1]]["path"]
    end

    description = parse_description(contents, get_regex(T, :content))
    if !isnothing(description)
        config["description"] = description
    end

    return config
end

function parse_description(contents::AbstractArray{<:AbstractString}, regex)
    # description as the first paragraph that is not a title, image, list or codes
    content_lines = map(x->match(regex, x) isa RegexMatch, contents)
    code_lines = map(contents) do line
        match(r"#?!?\w*```", lstrip(line)) isa RegexMatch
    end |> findall
    for (i,j) in zip(code_lines[1:2:end], code_lines[2:2:end])
        # mark code lines as non-content lines
        content_lines[i:j] .= 0
    end
    m = findall(content_lines)
    isempty(m) && return nothing

    paragraph_line = findall(x->x!=1, diff(m))
    offset = isempty(paragraph_line) ? length(m) : paragraph_line[1]
    description = map(contents[m[1:offset]]) do line
        m = match(regex, line)
        m["content"]
    end
    description = join(description, " ")
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
    # TODO: remove magic comments
    offsets = map(contents) do line
        m = match(regex_yaml, line)
        m isa RegexMatch
    end
    offsets = findall(offsets)
    if !isempty(offsets) && offsets[1] == 1 # only first line is treated as frontmatter
        # anything before frontmatter is thrown away
        frontmatter = map(x->lstrip(x, ('#', ' ')), contents[offsets[1]: offsets[2]])
        body = contents[offsets[2]+1:end]
    else
        frontmatter = ""
        body = contents
    end
    return frontmatter, body
end


function get_default_title(x::Union{AbstractDemoCard, DemoSection, DemoPage})
    name_without_ext = splitext(basename(x))[1]
    strip(replace(uppercasefirst(name_without_ext), r"[_-]" => " "))
end
