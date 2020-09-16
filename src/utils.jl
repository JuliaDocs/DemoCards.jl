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

"""
    walkpage([f=identity], page; flatten=true, max_depth=Inf)

Walk through the page structure and apply function f to each of the item.

By default, the page structure is not preserved in the result. To preserve that, you could pass
`flatten=false` to the function.

# Examples

This is particulaly useful to generate information for the page structure. For example:

```julia
julia> page = DemoPage("docs/quickstart/");

julia> walkpage(page; flatten=true) do item
    basename(item.path)
end

"Quick Start" => [
    "simple_markdown_demo.md",
    "configure_card.md",
    "configure_sec_and_page.md",
    "hide_your_card_from_index.md",
    "hidden_card.jl",
    "1.julia_demo.jl",
    "2.cover_on_the_fly.jl"
]
```

If `flatten=false`, then it gives you something like this:

```
"Quick Start" => [
    "Usage example" => [
        "Basics" => [
            "simple_markdown_demo.md",
            "configure_card.md",
            "configure_sec_and_page.md",
            "hide_your_card_from_index.md",
            "hidden_card.jl"
        ],
        "Julia demos" => [
            "1.julia_demo.jl",
            "2.cover_on_the_fly.jl"
        ]
    ]
]
```
"""
walkpage(page::DemoPage; kwargs...) = walkpage(identity, page; kwargs...)
function walkpage(f, page::DemoPage; flatten=true, kwargs...)
    nodes = _walkpage.(f, page.sections, 1; flatten=flatten, kwargs...)
    if flatten
        nodes = reduce(vcat, nodes)
        # compensate back to a vector when the first level section has only one section and one card
        nodes isa AbstractArray || (nodes = [nodes])
    end
    page.title => nodes
end

function _walkpage(f, sec::DemoSection, depth; max_depth=Inf, flatten=true)
    depth+1 > max_depth && return flatten ? f(sec) : [f(sec), ]
    if !isempty(sec.cards)
        return flatten ? mapreduce(f, vcat, sec.cards) : sec.title => f.(sec.cards)
    else
        map_fun(section) =  _walkpage(f, section, depth+1; max_depth=max_depth, flatten=flatten)
        return flatten ? mapreduce(map_fun, vcat, sec.subsections) : sec.title => map_fun.(sec.subsections)
    end
end

### regexes and configuration parsers

"""regex that capture the URL of Edit On GitHub button from Documenter generated html files"""
const regex_edit_on_github = r"\<a class=\"docs-edit-link\" href=\"(.*)\"\s*title=..*Edit on GitHub\</span\>\</a\>"

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

        # Note: return the complete one first
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

        # Note: return the complete one first
        return (regex_title, regex_simple_title)
    elseif regex_type == :content
        # lines that are not title, image, link, list
        # FIXME: list is also captured by this regex
        return r"^\s*#!?\w*\s+(?<content>[^#\-\*!]+.*)"
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
    header, frontmatter, body = split_frontmatter(readlines(card.path))
    config = parse(T, body)
    # frontmatter has higher priority
    if !isempty(frontmatter)
        merge!(config, YAML.load(join(frontmatter, "\n")))
    end

    return config
end
parse(card::JuliaDemoCard) = parse(Val(:Julia), card)
parse(card::MarkdownDemoCard) = parse(Val(:Markdown), card)


function parse(T::Val, contents::String)
    # if we just check isfile then it's likely to complain that filename is too long
    # compat: for Julia > 1.1 `endswith` supports regex as well
    if match(r"\.(\w+)$", contents) isa RegexMatch && isfile(contents)
        contents = readlines(contents)
    else
        contents = split(contents, "\n")
    end
    parse(T, contents)
end
function parse(T::Val, contents::AbstractArray{<:AbstractString})::Dict
    config = Dict()
    # only parse relevant information from the main contents body
    _, _, contents = split_frontmatter(contents)

    # it's too complicated to regex title correctly from body contents, so a simple
    # strategy is to limit possible titles to lines before the contents
    body_matches = map(contents) do line
        re = get_regex(T, :content)
        m = match(re, line)
    end
    body_lines = findall(map(x->x isa RegexMatch, body_matches))
    start_of_body = isempty(body_lines) ? 1 : minimum(body_lines)

    # The first title line in markdown format is parse out as the title
    title_matches = map(contents[1:start_of_body-1]) do line
        # try to match the most complete pattern first
        for re in get_regex(T, :title)
            m = match(re, line)
            m isa RegexMatch && return m
        end
        return nothing
    end
    title_lines = findall(map(x->x isa RegexMatch, title_matches))

    if !isempty(title_lines)
        m = title_matches[title_lines[1]]
        config["title"] = m["title"]
        if length(m.captures) == 2
            config["id"] = m["id"]
        end
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
    header, frontmatter, body = split_frontmatter(split(contents, "\n"))
    return join(header, "\n"), join(frontmatter, "\n"), join(body, "\n")
end
function split_frontmatter(contents::AbstractArray{<:AbstractString})
    offsets = map(contents) do line
        m = match(regex_yaml, line)
        m isa RegexMatch
    end
    offsets = findall(offsets)
    
    length(offsets) < 2 && return "", "", contents
    if offsets[1] != 1 && !all(x->isempty(strip(x)) || startswith(strip(x), "#"), contents[1:offsets[1]-1])
        # For julia demo, comments and empty lines are allowed before frontmatter
        # For markdown demo, only empty lines are allowed before frontmatter
        return "", "", contents
    end

    # infer how many spaces we need to trim from the start line. E.g.,  "# ---" => 1
    start_line = contents[offsets[1]]
    m = match(r"^#?(\s*)", start_line)
    # make sure we strip the same amount of whitespaces -- preserve indentation
    indent_spaces = isnothing(m) ? "" : m.captures[1]
    frontmatter = map(contents[offsets[1]: offsets[2]]) do line
        m = match(Regex("^#?$(indent_spaces)(.*)"), line)
        if isnothing(m)
            @warn "probably incorrect YAML syntax or indentation" line
            # we don't know much about what `line` is, so do nothing here and let YAML complain about it
            line
        else
            m.captures[1]
        end
    end

    return contents[1:offsets[1]-1], frontmatter, contents[offsets[2]+1:end]
end


function get_default_title(x::Union{AbstractDemoCard, DemoSection, DemoPage})
    name_without_ext = splitext(basename(x))[1]
    strip(replace(uppercasefirst(name_without_ext), r"[_-]" => " "))
end


is_remote_url(path) = !isnothing(match(r"^https?://", path))


"""
    input_bool(prompt)::Bool

Print `prompt` message and trigger user input for confirmation.
"""
function input_bool(prompt)
    while true
        println(prompt, " [y/n]")
        response = readline()
        length(response) == 0 && continue
        reply = lowercase(first(strip(response)))
        if reply == 'y'
            return true
        elseif reply =='n'
            return false
        end
        # Otherwise loop and repeat the prompt
    end
end
