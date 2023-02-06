abstract type AbstractDemoCard end

struct UnmatchedCard <: AbstractDemoCard
    path::String
end

"""
    democard(path::String)::T

Constructs a concrete AbstractDemoCard instance.

The return type `T` is determined by the extension of the path
to your demofile. Currently supported types are:

* [`MarkdownDemoCard`](@ref) for markdown files
* [`JuliaDemoCard`](@ref) for julia files
* [`UnmatchedCard`](@ref) for unmatched files

"""
function democard(path::String)::AbstractDemoCard
    validate_file(path)
    _, ext = splitext(path)
    if ext in markdown_exts
        return MarkdownDemoCard(path)
    elseif ext in julia_exts
        if is_pluto_notebook(path)
          return try
            PlutoDemoCard(path)
          catch e
            if isa(e, MethodError)
              # method is not imported from PlutoNotebook
              throw(
                ErrorException(
                  "You need to load PlutoStaticHTML.jl for using pluto notebooks",
                ),
              )
            else 
              throw(e)
            end
          end
        else
          return JuliaDemoCard(path)
        end
    else
        return UnmatchedCard(path)
    end
end

basename(x::AbstractDemoCard) = basename(x.path)

function get_default_id(card::AbstractDemoCard)
    # drop leading coutning numbers such as 1. 1_ 1-
    m = match(r"\d*(?<name>.*)", card.title)

    id = replace(strip(m["name"]), ' ' => '-')
end

function validate_id(id::AbstractString, card::AbstractDemoCard)
    if occursin(' ', id)
        throw(ArgumentError("invalid id in $(card.path), it should not contain spaces."))
    end
end

function is_democard(file)
    try
        @suppress_err democard(file)
        return true
    catch err
        @debug err
        return false
    end
end

function load_config(card::T, key; config=Dict()) where T <: AbstractDemoCard
    isempty(config) && (config = parse(card))

    if key == "cover"
        haskey(config, key) || return nothing

        cover_path = config[key]
        if !is_remote_url(cover_path)
            cover_path = replace(cover_path, r"[/\\]" => Base.Filesystem.path_separator) # windows compatibility
        end
        return cover_path
    elseif key == "id"
        haskey(config, key) || return get_default_id(card)

        id = config[key]
        validate_id(id, card)
        return id
    elseif key == "title"
        return get(config, key, get_default_title(card))
    elseif key == "description"
        return get(config, key, card.title)
    elseif key == "hidden"
        return get(config, key, false)
    elseif key == "author"
        return get(config, key, "")
    elseif key == "date"
        return DateTime(get(config, key, DateTime(0)))
    elseif key == "julia"
        version = get(config, key, JULIA_COMPAT)
        return version isa VersionNumber ? version : VersionNumber(string(version))
    else
        throw(ArgumentError("Unrecognized key $(key) for $(T)"))
    end
end

function make_badges(card::AbstractDemoCard)
    badges = []
    if !isempty(card.author)
        for author in split(card.author, ';')
            # TODO: also split on "and"
            isempty(author) && continue

            m = match(regex_md_url, author)
            if isnothing(m)
                author_str = HTTP.escapeuri(strip(author))
                push!(badges, "![Author](https://img.shields.io/badge/Author-$(author_str)-blue)")
            else
                # when markdown url is detected, create a link for it
                # author: [Johnny Chen](https://github.com/johnnychen94)
                name, url = strip.(m.captures)
                name = HTTP.escapeuri(name)
                badge_str = "[![Author](https://img.shields.io/badge/Author-$(name)-blue)]($url)"
                push!(badges, badge_str)
            end
        end
    end
    if card.date != DateTime(0)
        date_str = string(round(Int, datetime2unix(card.date)))
        push!(badges, "![Update time](https://img.shields.io/date/$(date_str))")
    end
    isempty(badges) ? "" : join(badges, " ")
end


### load concrete implementations

include("markdown.jl")
include("julia.jl")
include("pluto.jl")
