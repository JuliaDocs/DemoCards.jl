using Documenter, DemoCards


# 1. generate a DemoCard theme
grid_templates, grid_theme = cardtheme("grid")
list_templates, list_theme = cardtheme("list")

# 2. generate demo files
quickstart, postprocess_cb = makedemos("quickstart", grid_templates)
grid_demopage, grid_cb = makedemos(joinpath("theme_gallery", "grid"), grid_templates)
list_demopage, list_cb = makedemos(joinpath("theme_gallery", "list"), list_templates)


# 3. normal Documenter usage
format = Documenter.HTML(edit_link = "master",
                         prettyurls = get(ENV, "CI", nothing) == "true",
                         assets = [grid_theme, list_theme])

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            "QuickStart" => quickstart,
            "Concepts" => "concepts.md",
            "Theme Gallery" => [
               grid_demopage,
               list_demopage
            ],
            "Package References" => "references.md"
         ],
         sitename = "DemoCards.jl")

# 4. postprocess after makedocs
postprocess_cb()
grid_cb()
list_cb()

# 5. deployment
if !haskey(ENV, "CI_TEST")
   # test stage also build the docs but not deploy it
   deploydocs(repo = "github.com/johnnychen94/DemoCards.jl.git"
              push_preview = true)
end
