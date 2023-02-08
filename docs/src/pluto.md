# [Pluto.jl notebooks support](@id pluto)

[Pluto.jl](https://plutojl.org/) is a modern interactive notebook for Julia.
The Pluto notebook content is saved as a Julia script with special syntax decorations to support features like built-in dependency management and reactive cell execution.
In this section, we will discuss how we can add demos written using Pluto as DemoCards.

DemoCards.jl natively support only Julia and markdown files.
Pluto notebooks are supported via an [extension](https://pkgdocs.julialang.org/dev/creating-packages/#Conditional-loading-of-code-in-packages-%28Extensions%29) to the existing package.
PlutoStaticHTML.jl is used for rendering of pluto notebooks to desired markdown format.
The functionality for rendering pluto notebooks is automatically loaded when PlutoStaticHTML is imported into the current environment.

!!! note

    Julia versions before julia 1.9 doesn't support the extension functionality.
    Requires.jl is used to conditional loading of code for older julia versions.


The set of functionalities supported for Julia and Markdown files are also supported for Pluto.
We can compose any number of Pluto, Julia or Markdown files together for a demo.

If one of the demos contain a pluto notebook, we just need to add PlutoStaticHTML to the list of imports.

```julia
using Documenter, DemoCards # Load functionality for markdown and julia
using PlutoStaticHTML # Import the pluto notebook functionality to DemoCards

# The tutorials folders/sub-folders can contain pluto, julia and markdown
tutorials, tutorials_cb, tutorial_assets = makedemos("tutorials")
```

!!! warning

    The pluto notebooks in DemoCards are evaluated sequentially and not in parallel.
    This was done primarily to avoid repetitive logs in CI.
    We recommend using the cache functionality with the pluto notebooks in case of heavy workloads.

## Adding frontmatter to pluto notebooks

Pluto.jl has its own GUI to manipulate the front matter of a notebook.
This makes it easier for users to create and edit frontmatter.
The pluto frontmatter is not saved in YAML format.
See this [PR](https://github.com/fonsp/Pluto.jl/pull/2104) for more details.

## Cache computationally expensive notebooks
Rendering a Pluto notebook is sometimes time and resource-consuming, especially in a CI environment.
Fortunately, PlutoStaticHTML.jl has a cache functionality that uses outputs of previous runs as a cache.
If the source pluto notebook (.jl file) or the Julia environment didn't change from the last run, the output md file of the last run is used instead of re-rendering the source.
DemoCards stores all the rendered pluto notebooks in a `pluto_output` folder under the `docs` folder.

During the demo creation process, DemoCards.jl checks for a file with a cache (filename with .md extension) in `docs/pluto_output` for each pluto notebook. For example: if the pluto notebook file name is `example_demo.jl`, it searches for cache with filename `example_demo.md`. If the cache exists and the input hash and the Julia version matches, rendering is skipped, and the cache is used as output.
For more insight into the cache mechanism, visit the [cache documentation](https://huijzer.xyz/PlutoStaticHTML.jl/dev/#Caching) on PlutoStaticHTML.

## Examples

The usage of pluto notebooks as DemoCards can be found in [GraphNeuralNetworks.jl](https://github.com/CarloLucibello/GraphNeuralNetworks.jl).

## References

```@docs
DemoCards.PlutoDemoCard
DemoCards.save_democards(card_dir::AbstractString, card::DemoCards.PlutoDemoCard;
                   project_dir,
                   src,
                   credit,
                   nbviewer_root_url)
```
