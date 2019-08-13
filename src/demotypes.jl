const markdown_exts = [".md",]
const julia_exts = [".jl",]

# we don't load the demo contents for AbstractDemoFile here since
# we directly pass it to Documenter or Literate
abstract type AbstractDemoFile end

""" demo written as markdown file, directly pass to Documenter"""
struct MarkdownDemo <: AbstractDemoFile
    path::String
end

""" demo written as julia file, preprocessed by Literate first"""
struct JuliaDemo <:AbstractDemoFile
    path::String
end

""" recognize and generate a demofile"""
function demofile(path::String)::AbstractDemoFile
    validate_file(path)
    _, ext = splitext(path)
    if ext in markdown_exts
        return MarkdownDemo(path)
    elseif ext in julia_exts
        return JuliaDemo(path)
    else
        @warn("unrecognized file format $(ext)")
    end
end

"""
    DemoCard(demo, [cover], [title])

A demo card consists of `demo`, cover image `cover` and card description `title`.

* `demo` can be an `AbstractDemoFile` object, or a complete path to demo file
* `cover` can be a image object(e.g., `Array{RGB, 2}`) or a path to image file
* `title`::String is the one-line description under the cover image. By default it's the filename of `demo` (without extension).
"""
struct DemoCard{T<:AbstractDemoFile}
    demo::T
    # storing image content helps generate a better cover page
    cover::Array{<:Colorant, 2}
    title::String

    function DemoCard{T}(demo::T,
                      cover::AbstractArray{<:Colorant, 2},
                      title) where T<:AbstractDemoFile
        # TODO: we can beautify cover image here
        new(demo, RGB.(cover), title)
    end
end
DemoCard(demo::T, cover, title) where T<:AbstractDemoFile =
    DemoCard{T}(demo, cover, title)

DemoCard(demo_path::String) = DemoCard(demofile(demo_path))
function DemoCard(demo::AbstractDemoFile)::DemoCard
    # first consturct an incomplete democard, and then load the config
    card = DemoCard(demo, fallback_cover, "")

    cover = load_config(card, "cover")
    title = load_config(card, "title")
    DemoCard(demo, cover, title)
end



struct DemoSection
    root::String
    cards::Vector{DemoCard}
    subsections::Vector{DemoSection}
    # we don't need a title field, that is defined by the page template
end

function DemoSection(root::String)::DemoSection
    isdir(root) || throw("section root should be a valid dir, instead it's $(root)")

    path = joinpath.(root, readdir(root))
    card_paths = filter(x->isfile(x) && !endswith(x, config_filename), path)
    section_paths = filter(isdir, path)

    if !xor(isempty(card_paths), isempty(section_paths))
        throw("a demo section only holds either cards or subsections")
    end

    # first consturct an incomplete section, and then load the config
    section = DemoSection(root,
                          map(DemoCard, card_paths),
                          map(DemoSection, section_paths))

    ordered_paths = joinpath.(root, load_config(section, "order"))
    if !isempty(section.cards)
        cards = map(DemoCard, ordered_paths)
        subsections = []
    else
        cards = []
        subsections = map(DemoSection, ordered_paths)
    end

    DemoSection(root, cards, subsections)
end

struct DemoPage
    root::String
    sections::Vector{DemoSection}
    template::String
    title::String
end

function DemoPage(root::String)::DemoPage
    isdir(root) || throw("page root should be a valid dir, instead it's $(root)")

    section_paths = filter(isdir, joinpath.(root, readdir(root)))
    sections = map(DemoSection, section_paths)


    # first consturct an incomplete page, and then load the config
    page = DemoPage(root, sections, "", "")

    section_paths = joinpath.(root, load_config(page, "order"))
    ordered_sections = map(DemoSection, section_paths) # TODO: technically, we don't need to regenerate sections here

    template = load_config(page, "template")
    title = load_config(page, "title")
    DemoPage(root, ordered_sections, template, title)
end


### helpers
