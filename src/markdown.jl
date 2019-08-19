const markdown_exts = [".md",]

"""
    MarkdownDemoCard(path [,cover] [,title])

A demo card consists of cover image `cover` and card description `title`.

* `demo` can be an `AbstractDemoCard` object, or a complete path to demo file
* `cover` can be a image object(e.g., `Array{RGB, 2}`) or a path to image file
* `title`::String is the one-line description under the cover image. By default it's the filename of `demo` (without extension).
"""
struct MarkdownDemoCard <: AbstractDemoCard
    path::String
    # storing image content helps generate a better cover page
    cover::Array{<:Colorant, 2}
    title::String

    function MarkdownDemoCard(path::String,
                              cover::AbstractArray{<:Colorant, 2},
                              title::String)
        # TODO: we can beautify cover image here
        new(path, RGB.(cover), title)
    end
end

function MarkdownDemoCard(path::String)::MarkdownDemoCard
    # first consturct an incomplete democard, and then load the config
    card = MarkdownDemoCard(path, RGB.(Gray.(ones(128, 128))), "")

    cover = load_config(card, "cover")
    title = load_config(card, "title")
    MarkdownDemoCard(path, cover, title)
end

function load_config(card::MarkdownDemoCard, key)
    if key == "title"
        get_default_title(card)
    elseif key == "cover"
        get_default_cover(card)
    else
        throw("Unrecognized key $(key) for MarkdownDemoCard")
    end
end

function get_default_title(card::MarkdownDemoCard)
    uppercasefirst(splitext(get_name(card))[1])
end

get_default_cover(demofile::MarkdownDemoCard) =
    RGB.(Gray.(ones(128, 128)))
