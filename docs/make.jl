using Documenter, DemoCards


# 1. generate a DemoCard theme
theme = cardtheme()

# 2. generate demo files
quickstart, postprocess_cb = makedemos("quickstart")
# Juno.@enter makedemos("quickstart")

# 3. normal Documenter usage
format = Documenter.HTML(edit_link = "master",
                         prettyurls = get(ENV, "CI", nothing) == "true",
                         assets = [theme])

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            "QuickStart" => quickstart,
            "Concepts" => "concepts.md",
            "Package References" => "references.md"
         ],
         sitename = "DemoCards.jl")

# 4. postprocess after makedocs
postprocess_cb()

# 5. deployment
deploydocs(repo = "github.com/johnnychen94/DemoCards.jl.git")
