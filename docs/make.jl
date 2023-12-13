using Documenter, DemoCards, JSON
using PlutoStaticHTML # add the docstring for Pluto notebooks


# 1. generate demo files
quickstart, postprocess_cb, quickstart_assets = makedemos("quickstart")
themeless_demopage, themeless_cb, themeless_assets = makedemos(joinpath("theme_gallery", "themeless"))
grid_demopage, grid_cb, grid_assets = makedemos(joinpath("theme_gallery", "grid"))
list_demopage, list_cb, list_assets = makedemos(joinpath("theme_gallery", "list"))
nocoverlist_demopage, nocoverlist_cb, nocoverlist_assets = makedemos(joinpath("theme_gallery", "nocoverlist"))
bulmagrid_demopage, bulmagrid_cb, bulmagrid_assets = makedemos(joinpath("theme_gallery", "bulmagrid"))
transitiongrid_demopage, transitiongrid_cb, transitiongrid_assets = makedemos(joinpath("theme_gallery", "transitiongrid"))
bokehlist_demopage, bokehlist_cb, bokehlist_assets = makedemos(joinpath("theme_gallery", "bokehlist"))

assets = collect(filter(x->!isnothing(x), Set([quickstart_assets, themeless_assets, grid_assets, list_assets, nocoverlist_assets, bulmagrid_assets, transitiongrid_assets, bokehlist_assets])))

# 2. normal Documenter usage
format = Documenter.HTML(edit_link = "master",
                         prettyurls = get(ENV, "CI", nothing) == "true",
                         assets = assets,
                         size_threshold=1024 * 1024)

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            quickstart,
            "Concepts" => "concepts.md",
            "Partial build" => "preview.md",
            "Structure manipulation" => "structure.md",
            "Pluto.jl support" => "pluto.md",
            "Theme Gallery" => [
               themeless_demopage,
               grid_demopage,
               bulmagrid_demopage,
               transitiongrid_demopage,
               list_demopage,
               nocoverlist_demopage,
               bokehlist_demopage,
            ],
            "Package References" => "references.md"
         ],
         sitename = "DemoCards.jl")

# 3. postprocess after makedocs
postprocess_cb()
themeless_cb()
bulmagrid_cb()
transitiongrid_cb()
bokehlist_cb()
grid_cb()
list_cb()
nocoverlist_cb()

# a workdaround to github action that only push preview when PR has "push_preview" labels
# issue: https://github.com/JuliaDocs/Documenter.jl/issues/1225
function should_push_preview(event_path = get(ENV, "GITHUB_EVENT_PATH", nothing))
   event_path === nothing && return false
   event = JSON.parsefile(event_path)
   haskey(event, "pull_request") || return false
   labels = [x["name"] for x in event["pull_request"]["labels"]]
   return "push_preview" in labels
end

# 4. deployment
deploydocs(repo = "github.com/JuliaDocs/DemoCards.jl.git",
            push_preview = should_push_preview())
