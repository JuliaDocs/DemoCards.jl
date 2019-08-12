using Documenter, DemoCards

format = Documenter.HTML(edit_branch = "master",
                         assets = [joinpath("assets", "style.css")])

# note: demo.md is added to gitignore
demo_root = joinpath("docs", "src")
generate(joinpath(demo_root,"demo.md"),
         DemoPage(joinpath(demo_root, "demos")))

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            "Demo" => "demo.md"],
         sitename = "DemoCards")

deploydocs(repo = "github.com/johnnychen94/DemoCards.jl.git")
