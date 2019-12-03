abstract type AbstractDemoCard end

"""
    democard(path::String)::T

Constructs a concrete AbstractDemoCard instance.

The return type `T` is determined by the extension of the path
to your demofile. Currently supported types are:

* [`MarkdownDemoCard`](@ref)
"""
function democard(path::String)::AbstractDemoCard
    validate_file(path)
    _, ext = splitext(path)
    if ext in markdown_exts
        return MarkdownDemoCard(path)
    elseif ext in julia_exts
        return JuliaDemoCard(path)
    else
        throw(ArgumentError("unrecognized democard format $(path)"))
    end
end

basename(x::AbstractDemoCard) = basename(x.path)

function get_default_id(card::AbstractDemoCard)
    name_without_ext = splitext(basename(card))[1]
    # default documenter id has -1 suffix
    replace(name_without_ext, r"[ _]" => '-') * "-1"
end

function validate_id(id::AbstractString, card::AbstractDemoCard)
    if occursin(' ', id)
        throw(ArgumentError("invalid id in $(card.path), it should not contain spaces."))
    end
end

function load_config(card::T, key) where T <: AbstractDemoCard
    config = parse(card)

    if key == "cover"
        root = dirname(card.path)
        haskey(config, key) || return nothing

        cover_path = config[key]
        return cover_path
    elseif key == "id"
        haskey(config, key) || return get_default_id(card)

        id = config[key]
        validate_id(id, card)
        return id
    elseif key == "title"
        return get(config, key, get_default_title(card))
    elseif key == "description"
        return get(config, key, get_default_description(card))
    else
        throw(ArgumentError("Unrecognized key $(key) for $(T)"))
    end
end


### load concrete implementations

include("markdown.jl")
include("julia.jl")
