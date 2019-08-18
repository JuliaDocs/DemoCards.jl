using Documenter, DemoCards

format = Documenter.HTML(edit_branch = "master",
                         assets = [joinpath("assets", "style.css")])


simplest_demopage = makedemos("simplest_demopage")
custom_demopage = makedemos("custom_demopage")
custom_demo_orders = makedemos("custom_demo_orders")

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            "Simplest demepage" => simplest_demopage,
            "Custom demopage" => custom_demopage,
            "Custom demo orders" => custom_demo_orders
         ],
         sitename = "DemoCards")

deploydocs(repo = "github.com/johnnychen94/DemoCards.jl.git")
