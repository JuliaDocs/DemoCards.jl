![juliadocs](assets/juliadocs.png)

This demo show you what `DemoCards.jl` does to a markdown demo.

`DemoCards.jl` is a plugin package to [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).
Hence, in general, demos written in markdown format are directly passed to `Documenter.jl` without much
preprocessing.

`DemoCards.jl` extracts some meta information from your demos:

* The first title is extracted as the card title: the filename `simple_markdown_demo.md` gives the
  title "Simple markdown demo"
* The first image link to `Documenter.jl`'s logo is extracted as the cover image
* The first paragraph is extracted as the description

When your mouse hover over the card, a description shows up, for example:

![](assets/description.png)

This becomes the simplest markdown demo!
