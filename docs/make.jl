using Documenter, DemoCards


# 1. generate a DemoCard theme
theme = cardtheme()

# 2. generate demo files
simplest_demopage, postprocess_cb1 = makedemos("demos/simplest_demopage")
gallery_of_packages, postprocess_cb2 = makedemos("demos/gallery_of_packages")

# 3. normal Documenter usage
format = Documenter.HTML(edit_link = "master",
                         prettyurls = get(ENV, "CI", nothing) == "true",
                         assets = [theme])

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            "QuickStart" => "quickstart.md",
            "Concepts" => "concepts.md",
            "Examples" => [
                "Simplest Demopage" => simplest_demopage,
                "Gallery of Packages" => gallery_of_packages,
            ],
            "Package References" => "references.md"
         ],
         sitename = "DemoCards.jl")

# 4. postprocess after makedocs
postprocess_cb1()
postprocess_cb2()

# 5. deployment
deploydocs(repo = "github.com/johnnychen94/DemoCards.jl.git")
