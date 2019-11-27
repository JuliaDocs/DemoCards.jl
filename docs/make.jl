using Documenter, DemoCards


theme = cardtheme()
simplest_demopage = makedemos("demos/simplest_demopage")
gallery_of_packages = makedemos("demos/gallery_of_packages")

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

deploydocs(repo = "github.com/johnnychen94/DemoCards.jl.git")
