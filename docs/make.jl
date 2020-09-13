using Documenter, DemoCards, JSON


# 1. generate demo files
quickstart, postprocess_cb, quickstart_assets = makedemos("quickstart")
themeless_demopage, themeless_cb, themeless_assets = makedemos(joinpath("theme_gallery", "themeless"))
grid_demopage, grid_cb, grid_assets = makedemos(joinpath("theme_gallery", "grid"))
list_demopage, list_cb, list_assets = makedemos(joinpath("theme_gallery", "list"))

assets = collect(filter(x->!isnothing(x), Set([quickstart_assets, themeless_assets, grid_assets, list_assets])))

# 2. normal Documenter usage
format = Documenter.HTML(edit_link = "master",
                         prettyurls = get(ENV, "CI", nothing) == "true",
                         assets = assets)

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            quickstart,
            "Concepts" => "concepts.md",
            "Advanced Usages" => [
               "Preview only one demo" => "preview.md",
            ],
            "Theme Gallery" => [
               themeless_demopage,
               grid_demopage,
               list_demopage
            ],
            "Package References" => "references.md"
         ],
         sitename = "DemoCards.jl")

# 3. postprocess after makedocs
postprocess_cb()
themeless_cb()
grid_cb()
list_cb()

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
deploydocs(repo = "github.com/johnnychen94/DemoCards.jl.git",
            push_preview = should_push_preview())
