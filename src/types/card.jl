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
    else
        throw("unrecognized democard format $(path)")
    end
end

basename(x::AbstractDemoCard) = basename(x.path)

function validate_id(id::AbstractString, card::AbstractDemoCard)
    if occursin(' ', id)
        throw("invalid id in $(card.path), it should not contain spaces.")
    end
end

function load_config(card::T, key) where T <: AbstractDemoCard
    config = parse(card)

    if key == "cover"
        root = dirname(card.path)
        haskey(config, key) || return nothing

        cover_path = joinpath(dirname(card.path), config[key])
        isfile(cover_path) || throw("$(cover_path) isn't a valid image file for cover.")
        return cover_path
    elseif key == "id"
        haskey(config, key) || return get_default_id(card)

        id = config[key]
        validate_id(id, card)
        return id
    elseif key == "title"
        return get(config, key) do
            name_without_ext = splitext(basename(card))[1]
            strip(replace(uppercasefirst(name_without_ext), "_" => " "))
        end
    elseif key == "description"
        return get(config, key, card.title)
    else
        throw("Unrecognized key $(key) for $(T)")
    end
end


### load concrete implementations

include("markdown.jl")
