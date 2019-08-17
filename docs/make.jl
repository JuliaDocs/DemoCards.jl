using Documenter, DemoCards

format = Documenter.HTML(edit_branch = "master",
                         assets = [joinpath("assets", "style.css")])

demo_root = joinpath("docs", "src")
generate_root = joinpath(demo_root, "demopages")

generate(joinpath(generate_root,"simplest_demos.md"),
         DemoPage(joinpath(demo_root, "simplest_demos")))
generate(joinpath(generate_root,"demos_with_template.md"),
         DemoPage(joinpath(demo_root, "demos_with_template")))
generate(joinpath(generate_root,"ordered_demos.md"),
         DemoPage(joinpath(demo_root, "ordered_demos")))

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            "Simplest demopage" => "demopages/simplest_demos.md",
            "demopage template" => "demopages/demos_with_template.md",
            "ordered demopage" => "demopages/ordered_demos.md"
         ],
         sitename = "DemoCards")

deploydocs(repo = "github.com/johnnychen94/DemoCards.jl.git")
