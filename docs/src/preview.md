# Preview only one demo

Typically, when you write up examples and demos using `DemoCards`, you'll need to do
`include("docs/make.jl)` to trigger a rebuild for many times. This is okay, just not that fast as
you need to rebuild the whole documentation even if you are just making some trivial typo checks.
This page shows how you could make this experience smoother, especially for julia demos.

`DemoCards` uses [`Literate.jl`][Literate] as the backend to transform your julia files to markdown
and jupyter notebook. This means that you can code up your example file with whatever programming
environment you like. For example, you can use `Ctrl-Enter` to execute your codes line by line in
Juno/VSCode, check the output, add comments, and so on; all these can be done without the need to
build the documentation. 

For example, assume that you are writing a `demos/sec1/demo1.jl`

```julia
# demos/sec1/demo1.jl

using Images # you can `Ctrl-Enter` in VSCode to execute this line

img = testimage("camera") # `Ctrl-Enter` again, and see the output in the plot panel

# and add more example codes in a REPL way
```

This REPL workflow works pretty well and responsive until you start to building the documentation.
For example, There are a lot of demos in [JuliaImages demos] and it takes several minutes to build
the documentation. If we're only to make many some small modifications to one of the demo, then it
would be pretty painful to wait the whole build pipeline ends. Fortunately, `DemoCards` provides a
sandbox environment for you to preview your demos without doing so.

Assume that your `docs/make.jl` is written up like the following:

```julia
# 1. generate a DemoCard theme
templates, theme = cardtheme("grid")

# 2. generate demo files
demopage, postprocess_cb = makedemos("demos", templates) # relative path to docs/

# 3. normal Documenter usage
format = Documenter.HTML(edit_branch = "master",
                         assets = [theme, ])
makedocs(format = format,
         pages = [
            "Home" => "index.md",
            "Examples" => demopage,
         ],
         sitename = "Awesome demos")

# 4. postprocess after makedocs
postprocess_cb()
```

To preview only one demo in `demos` folder, say, `demos/sec1/demo1.jl`, what you need to do is:

```julia
preview_demos("docs/demos/sec1/demo1.jl")
```

It will output the path to the generated `index.html` file, for example, it might be something like
this:

```julia
"/var/folders/c0/p23z1x6x3jg_qtqsy_r421y40000gn/T/jl_5sc8fM/build/democards/demos/index.html"
```

Open this file in your favorite browser, and you'll see a reduced version of the demo page, which
only contains one demo file. Other unrelated contents are not included in this page.

`preview_demos` does not do anything magic, it simply copies the single demo file and its assets into a
sandbox folder, and trigger the `Documenter.makedocs` in that folder. Because it doesn't contain any
other files, this process becomes way faster than `include("docs/make.jl")` workflow.

Compared to rebuild the whole documentation, building a preview version only adds about 1 extra second
to `include("demo1.jl")`.

If the file is placed in a typical demo page folder structure, `preview_demos(file)` will preserve that
structure. In cases that demo page folder structure is not detected, it will instead create such a
folder structure.

This `preview_demos` function is not reserved for single file, it works for folders, too. For
example, you could use it with `preview_demos("demos/sec1")`, or `preview_demos("demos")`.

!!! note
    `preview_demos` does not include any other part of the documentation in the preview, hence
    reflinks are very likely to be broken and you will receieve warnings about that. In this case,
    you still need to `include("docs/make.jl")` to rebuild the whole documentation if reflinks are
    what you concern about.

[Literate]: https://github.com/fredrikekre/Literate.jl
[Literate Syntax]: https://fredrikekre.github.io/Literate.jl/v2/fileformat
[JuliaImages demos]: https://juliaimages.org/latest/democards/examples/
