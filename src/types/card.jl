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

function validate_id(id::String, card::AbstractDemoCard)
    if occursin(' ', id)
        throw("invalid id in $(card.path), it should not contain spaces.")
    end
end

include("markdown.jl")
