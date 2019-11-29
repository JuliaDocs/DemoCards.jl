"""
    makedemos(source::String) -> path, postprocess_cb

Make a demo page file and return the path to it.

`source` is the root path to the demos folder, by default it's relative path to `docs`.

Processing pipeline:

1. analyze the folder structure `source` and loading all available configs.
2. copy assets
3. preprocess demo files and save it
4. save/copy cover images
5. generate postprocess callback function, which includes url-redirection.

!!! note
    By default, the source demo files are read, processed and save to `docs/src/democards`,
    so if you put all source demo files in `docs/src`, there will be a duplication of files and assets.


# Outputs

* `path`: path to demo page's index. You can directly pass it to `makedocs`.
* `postprocess_cb`: callback function for postprocess. You can call `postprocess_cb()` _after_ `makedocs`.

# Keywords

* `root::String`: root path to the whole documentaion. By default `docs`.
* `destination::String`: By default `democards`.

# Examples

The following is a minimal example for you to start

```julia
# 1. generate a style sheet and pass it to Documenter
theme = cardtheme()
format = Documenter.HTML(edit_branch = "master",
                         assets = [theme])

# 2. make demo files
examples, postprocess_cb = makedemos("examples")

makedocs(format = format,
         pages = [
            "Home" => "index.md",
            "Examples" => examples,
         ])

# 3. postprocessing
postprocess_cb()
```

!!! warning

    Currently, there's no guarantee that this function works for unconventional
    documentation folder structure. By *convention*, it is:

    ```text
    .
    ├── Project.toml
    ├── docs
    │   ├── make.jl
    │   └── src
    ├── src
    └── test
    ```
"""
function makedemos(source::String;
                   root::String = "docs",
                   destination::String = "democards",
                   src::String = "src",
                   build::String = "build")
    page = DemoPage(joinpath(root, source))

    relative_root = joinpath(destination, basename(page))
    absolute_root = joinpath(root, src, relative_root)

    # we can directly pass it to Documenter.makedocs
    out_path = joinpath(relative_root, "index.md")

    @info "SetupDemoCardsDirectory: setting up $(source) directory."
    rm(absolute_root; force=true, recursive=true)
    mkpath(absolute_root)
    mkpath(joinpath(absolute_root, "covers")) # consistent to card template

    # make a copy before pipeline because `save_democards` modifies card path
    source_files = map(x->x.path, flatten(page))

    # pipeline
    copy_assets(absolute_root, page)
    save_democards(absolute_root, page) # WARNING: julia cards are reconfigured here
    save_cover(joinpath(absolute_root, "covers"), page)
    generate(joinpath(absolute_root, "index.md"), page)

    # pipeline: generate postprocess callback function
    postprocess_cb = ()->begin
        @info "Redirect URL: redirect docs-edit-link for demos in $(source) directory."
        foreach(source_files) do source_file
            redirect_link(source_file, source, root, destination, src, build)
        end
    end

    return out_path, postprocess_cb
end

"""
    cardtheme(theme::AbstractString) -> path

Currently supported themes are:

* `minimal`
"""
function cardtheme(theme::AbstractString = "minimal";
                   root::AbstractString = "docs",
                   destination::String = "democards")::String
    relative_root = destination
    absolute_root = joinpath(root, "src", relative_root)
    isdir(absolute_root) || mkpath(absolute_root)

    filename = "cardtheme.css"
    write(joinpath(absolute_root, filename), read_cardtheme(theme))

    return joinpath(relative_root, filename)
end

const card_section_template = mt"""
```@raw html
<div class="card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const card_template = mt"""
```@raw html
<div class="card">
<div class="card-img">
```

[![svd](covers/{{name}}.png)](@ref {{id}})

```@raw html
</div>
<div class="card-text">
```

[{{title}}](@ref {{id}})
```@raw html
</div>
</div>
```

"""

function generate(file::String, page::DemoPage)
    check_ext(file, :markdown)
    open(file, "w") do f
        generate(f, page::DemoPage)
    end
end
generate(io::IO, page::DemoPage) = write(io, generate(page))
function generate(page::DemoPage)
    # TODO: Important: we need to render section by section
    items = Dict("democards" => generate(page.sections))
    Mustache.render(page.template, items)
end

generate(cards::AbstractVector{<:AbstractDemoCard}) =
    reduce(*, map(generate, cards); init="")

generate(secs::AbstractVector{DemoSection}; level=1) =
    reduce(*, map(x->generate(x;level=level), secs); init="")

function generate(sec::DemoSection; level=1)
    header = repeat("#", level) * " " * sec.title * "\n"
    footer = "\n"
    # either cards or subsections are empty
    if isempty(sec.cards)
        body = generate(sec.subsections; level=level+1)
    else
        items = Dict("cards" => generate(sec.cards))
        body = Mustache.render(card_section_template, items)
    end
    header * body * footer
end

function generate(card::AbstractDemoCard)
    items = Dict(
        "name" => splitext(basename(card))[1],
        "id" => card.id,
        "title" => card.title
    )
    Mustache.render(card_template, items)
end

### save demo card covers

save_cover(path::String, page::DemoPage) = save_cover.(path, page.sections)
function save_cover(path::String, sec::DemoSection)
    # TODO: we can perserve the folder structure when creating covers
    #       this helps avoid name conflicts
    save_cover.(path, sec.subsections)
    save_cover.(path, sec.cards)
end

"""
    save_cover(path::String, card::AbstractDemoCard)

process the cover image and save it.
"""
function save_cover(path::String, card::AbstractDemoCard)
    ext = ".png" # consistent to card_template
    cover_path = joinpath(path, splitext(basename(card))[1] * ext)

    if isfile(cover_path)
        @warn("$(cover_path) already exists, perhaps you have demos of the same filename")
    end

    cover = load_cover(card)

    # saving all cover images to a fixed folder cover_path
    # so that we don't need to manipulate the image path in template
    if any(size(cover) .>= max_coversize)
        cover = imresize(cover, max_coversize)
    end
    save(cover_path, cover)
end

function load_cover(card::AbstractDemoCard)
    root = dirname(card.path)
    isnothing(card.cover) ? Gray.(ones(128, 128)) : load(joinpath(root, card.cover))
end

### save markdown files

"""
    save_democards(root::String, page::DemoPage)

recursively process and save source demo file
"""
save_democards(root::String, page::DemoPage) = save_democards.(root, page.sections)
function save_democards(root::String, sec::DemoSection)
    save_democards.(joinpath(root, basename(sec.root)), sec.subsections)
    save_democards.(joinpath(root, basename(sec.root)), sec.cards)
end

### copy assets

function copy_assets(path::String, page::DemoPage)
    _copy_assets(dirname(path), page.root)
    copy_assets.(path, page.sections)
end
function copy_assets(path::String, sec::DemoSection)
    _copy_assets(path, sec.root)
    copy_assets.(joinpath(path, basename(sec.root)), sec.subsections)
end

function _copy_assets(dest_root::String, src_root::String)
    # copy assets of this section
    assets_dirs = filter(x->isdir(x)&&(basename(x) in ignored_dirnames),
                         joinpath.(src_root, readdir(src_root)))
    map(assets_dirs) do src
        dest = joinpath(dest_root, basename(src_root), basename(src))
        mkpath(dest)
        cp(src, dest; force=true)
    end
end

### postprocess

"""
    redirect_link(src_file, source, root, destination, src, build)

Redirect the "Edit On GitHub" link of generated demo files to its original url, without
this a 404 error is expected.
"""
function redirect_link(source_file, source, root, destination, src, build)
    build_file = get_build_file(source_file, source, destination, build)
    if !isfile(build_file)
        @warn "$build_file doesn't exists, skip"
        return nothing
    end
    contents = read(build_file, String)

    m = match(r"a class=\"docs-edit-link\" href=\"(.*)\" .*Edit on GitHub", contents)
    isnothing(m) && return nothing
    build_url = m.captures[1]

    # note that url is joined by / instead of \
    prefix = join([root, src, destination], "/")
    base_url = split(build_url, prefix)[1]
    src_url = replace(joinpath(base_url, source_file), "\\"=>"/")

    new_contents = replace(contents, build_url=>src_url)
    write(build_file, new_contents)
end

function get_build_file(source_file, source, destination, build)
    source_dir = splitdir(source)[1]
    build_dir = joinpath(build, destination)

    dir, name = splitdir(source_file)
    dir = replace(dir, source_dir => build_dir)
    prettyurls = isdir(joinpath(dir, splitext(name)[1]))

    # Documenter.HTML behaves differently on prettyurls
    if prettyurls
        build_file = joinpath(dir, splitext(name)[1], "index.html")
    else
        build_file = joinpath(dir, splitext(name)[1] * ".html")
    end
    return build_file
end
