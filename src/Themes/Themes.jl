module CardThemes

# Notes for adding new card theme
#
# Steps to write new card theme:
#   1. specialize `cardtheme`, it should return two items:
#     * `templates`: a tuple of Mustache templates (card_template, section_template)
#     * `stylesheet_path`: absolute filepath to the stylesheet.
#   2. add the new theme name to `themelists`
#
# available placeholders for section template:
#   * `cards`: the card table/list/whatever contents
#   * (WIP)`description`: section description contents
#
# available placeholders for card template:
#  * `description`: card description
#  * `covername`: the name of the card cover image
#  * `id`: reference id that reads by Documenter
#  * `title`: card title
#
using Mustache

"""
    cardtheme(theme = "grid";
              root = "<current-directory>",
              destination = "democards") -> templates, stylesheet_path

For given theme, return the templates and path to stylesheet.

`root` and `destination` should have the same value to that passed to [`makedemos`](@ref).
"""
function cardtheme(theme::AbstractString="grid";
                   root::AbstractString = Base.source_dir(),
                   destination::String = "democards")
    templates, src_stylesheet_path = cardtheme(Val(Symbol(theme)))

    # a copy is needed because Documenter only support relative path inside root
    absolute_root = joinpath(root, "src", destination)
    filename = "$(theme)theme.css"
    out_stylesheet_path = joinpath(absolute_root, filename)
    isdir(absolute_root) || mkpath(absolute_root)
    cp(src_stylesheet_path, out_stylesheet_path; force=true)

    return templates, joinpath(destination, filename)
end

# fallback if the theme name doesn't exist
function cardtheme(theme::Val{T}) where T
    themes_str = join(themelists, ", ")
    error("unrecognized card theme: $T\nAvaiable theme options are: $themes_str")
end

"""
A list of DemoCards theme presets
"""
const themelists = ["grid", "list"]

# TODO: don't hardcode this
const max_coversize = (220, 200)

# add themes
include("grid/grid.jl")
include("list/list.jl")


export cardtheme, max_coversize

end
