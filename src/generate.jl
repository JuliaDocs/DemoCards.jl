"""
    makedemos(source::String;
              root = "<current-directory>",
              src = "src",
              build = "build",
              branch = "gh-pages",
              edit_branch = "master",
              credit = true,
              throw_error = false) -> page_path, postprocess_cb

Make a demo page for `source` and return the path to the generated index file.

Processing pipeline:

1. analyze the folder structure `source` and loading all available configs.
2. copy assets
3. preprocess demo files and save it
4. save/copy cover images
5. generate postprocess callback function, which includes url-redirection.

!!! warning
    By default, `makedemos` generates all the necessary files to `docs/src/`, this means that the
    data you pass to `makedemos` should not be placed at `docs/src/`. A recommendation is to
    put folders in `docs/`. For example, `docs/quickstart` is a good choice.

# Inputs

* `source`: dir path to the root page of your demos; relative to `docs`.

# Outputs

* `page_path`: path to demo page's index. You can directly pass it to `makedocs`.
* `postprocess_cb`: callback function for postprocess. You can call `postprocess_cb()` _after_
  `makedocs`.
* `theme_assets`: the stylesheet assets that you may need to pass to `Documenter.HTML`. When the
  demo page has no theme, it will return `nothing`.

# Keywords

* `root::String`: should be equal to `Documenter`'s setting. Typically it is `"docs"` if this
  function is called in `docs/make.jl` file.
* `src::String`: should be equal to `Documenter`'s setting. By default it's `"src"`.
* `build::String`: should be equal to `Documenter`'s setting. By default it's `"build"`.
* `edit_branch::String`: should be equal to `Documenter`'s setting. By default it's `"master"`.
* `branch::String`: should be equal to `Documenter`'s setting. By default it's `"gh-pages"`.
* `credit::Bool`: `true` to show a "This page is generated by ..." info. By default it's `true`.
* `throw_error::Bool`: `true` to throw an error when the julia demo build fails; otherwise it will
  continue the build with warnings.

# Examples

The following is the simplest example for you to start with:

```julia
# 1. preprocess and generate demo files to docs/src
examples, postprocess_cb, demo_assets = makedemos("examples")

assets = []
isnothing(demo_assets) || (push!(assets, demo_assets))

# 2. do the standard Documenter pipeline
makedocs(format = Documenter.HTML(assets = assets),
         pages = [
             "Home" => "index.md",
             examples
         ])

# 3. postprocess after makedocs
postprocess_cb()
```

By default, it won't generate the index page for your demos. To enable it and configure how index
page is generated, you need to create "examples/config.json", whose contents should looks like the
following:

```json
{
    "theme": "grid",
    "order": [
        "basic",
        "advanced"
    ]
}
```

For more details of how `config.json` is configured, please check [`DemoCards.DemoPage`](@ref).
"""
function makedemos(source::String, templates::Union{Dict, Nothing} = nothing;
                   root::String = Base.source_dir(),
                   src::String = "src",
                   build::String = "build",
                   branch::String = "gh-pages",
                   edit_branch::String = "master",
                   credit = true,
                   throw_error = false)

    if !(basename(pwd()) == "docs" || basename(root) == "docs" || root == preview_build_dir())
        # special cases that warnings are not printed:
        # 1. called from `docs/make.jl`
        # 2. called from `preview_demos`
        # 3. pwd() in `docs` -- REPL
        @warn "Suspicious `root` setting: typically `makedemos` should be called from `docs/make.jl`. " pwd=pwd() root
    end
    
    root = abspath(root)
    page_root = abspath(root, source)

    if page_root == source
        # reach here when source is absolute path
        startswith(source, root) || throw(ArgumentError("invalid demo page source $page_root"))
    end

    page = DemoPage(page_root)

    relative_root = basename(page)

    # Where files are generated by DemoCards for Documenter.makedocs
    # e.g "$PROJECT_ROOT/docs/src/quickstart"
    absolute_root = abspath(root, src, relative_root)

    if page_root == absolute_root
        throw(ArgumentError("Demo page $page_root should not be placed at \"docs/$src\" folder."))
    end

    config_file = joinpath(page.root, config_filename)
    if !isnothing(templates)
        Base.depwarn(
            "It is not recommended to pass `templates`, please configure the index theme in the config file $(config_file). For example `\"theme\": \"grid\"`",
            :makedemos)
    end

    if !isnothing(page.theme)
        page_templates, theme_assets = cardtheme(page.theme, root = root)
        theme_assets = something(page.stylesheet, theme_assets)

        if templates != page_templates && templates != nothing
            @warn "use configured theme from $(config_file)"
        end

        templates = page_templates
    else
        theme_assets = page.stylesheet
    end

    # we can directly pass it to Documenter.makedocs
    if isnothing(templates)
        out_path = walkpage(page; flatten=false) do dir, item
            joinpath(
                basename(source),
                relpath(dir, page_root),
                splitext(basename(item))[1] * ".md"
            )
        end
    else
        # For themes that requires an index page
        # This will not generate a multi-level structure in the sidebar
        out_path = joinpath(relative_root, "index.md")
    end

    # Ensure every path exists before we actually do the work
    walkpage(page) do dir, item
        @assert isfile(item.path) || isdir(item.path)
    end

    @info "SetupDemoCardsDirectory: setting up \"$(source)\" directory."
    if isdir(absolute_root)
        # a typical and probably safe case -- that we're still in docs/ folder
        trigger_prompt = (
            !endswith(dirname(absolute_root), joinpath("docs", "src")) &&
            !(haskey(ENV, "GITLAB_CI") || haskey(ENV, "GITHUB_ACTIONS"))
        )
        @info "Deleting folder $absolute_root"

        if trigger_prompt
            @warn "DemoCards build dir $absolute_root already exists.\nThis should only happen when you are using DemoCards incorrectly."
            # Should never reach this in CI environment
            clean_builddir = input_bool("It might contain important data, do you still want to remove it?")
        else
            clean_builddir = true
        end
        if clean_builddir
            @info "Remove DemoCards build dir: $absolute_root"
            # Ref: https://discourse.julialang.org/t/find-what-has-locked-held-a-file/23278/2
            Base.Sys.iswindows() && GC.gc()
            rm(absolute_root; force=true, recursive=true)
        else
            error("Stopped demos build.")
        end
    end

    mkpath(absolute_root)
    local clean_up_temp_remote_files
    try
        # hard coded "covers" should be consistant to card template
        isnothing(templates) || mkpath(joinpath(absolute_root, "covers"))

        # make a copy before pipeline because `save_democards` modifies card path
        source_files = [x.path for x in walkpage(page)[2]]

        # pipeline
        # prepare remote files into current folder structure, and provide a callback
        # to clean it up after the generation
        page, clean_up_temp_remote_files = prepare_remote_files(page)

        # for themeless version, we don't need to generate covers and index page
        copy_assets(absolute_root, page)
        # WARNING: julia cards are reconfigured here
        save_democards(absolute_root, page;
                    project_root = root,
                    src = src,
                    credit = credit,
                    nbviewer_root_url = get_nbviewer_root_url(branch),
                    throw_error=throw_error)
        isnothing(templates) || save_cover(joinpath(absolute_root, "covers"), page)
        isnothing(templates) || generate(joinpath(absolute_root, "index.md"), page, templates)

        # pipeline: generate postprocess callback function
        postprocess_cb = ()->begin
            @info "Redirect page URL: redirect docs-edit-link for demos in \"$(source)\" directory."
            isnothing(templates) || push!(source_files, joinpath(page_root, "index.md"))
            foreach(source_files) do source_file
                # LocalRemoteCard is a virtual placeholder and does not exist here
                isfile(source_file) && return
                # only redirect to "real" files
                redirect_link(source_file, source, root, src, build, edit_branch)
            end

            @info "Clean up DemoCards build dir: \"$source\""
            # Ref: https://discourse.julialang.org/t/find-what-has-locked-held-a-file/23278/2
            Base.Sys.iswindows() && GC.gc()
            rm(absolute_root; force=true, recursive=true)

            if !isnothing(theme_assets)
                assets_path = abspath(root, src, theme_assets)
                # Ref: https://discourse.julialang.org/t/find-what-has-locked-held-a-file/23278/2
                Base.Sys.iswindows() && GC.gc()
                rm(assets_path, force=true)
                if isdir(dirname(assets_path))
                    if(isempty(readdir(dirname(assets_path))))
                        # Ref: https://discourse.julialang.org/t/find-what-has-locked-held-a-file/23278/2
                        Base.Sys.iswindows() && GC.gc()
                        rm(dirname(assets_path))
                    end
                end
            end
        end

        return out_path, postprocess_cb, theme_assets

    catch err
        # clean up build dir if anything wrong happens here so that we _hopefully_ never trigger the
        # user prompt logic before the build process.
        # Ref: https://discourse.julialang.org/t/find-what-has-locked-held-a-file/23278/2
        Base.Sys.iswindows() && GC.gc()
        rm(absolute_root; force=true, recursive=true)
        @error "Errors when building demo dir" pwd=pwd() source root src
        rethrow(err)
    finally
        clean_up_temp_remote_files()
    end
end

function generate(file::String, page::DemoPage, args...)
    check_ext(file, :markdown)
    open(file, "w") do f
        generate(f, page::DemoPage, args...)
    end
end
generate(io::IO, page::DemoPage, args...) = write(io, generate(page, args...))


function generate(page::DemoPage, templates)
    items = Dict("democards" => generate(page.sections, templates; properties=page.properties))
    Mustache.render(page.template, items)
end

function generate(cards::AbstractVector{<:AbstractDemoCard}, template; properties=Dict{String, Any}())
    # for those hidden cards, only generate the necessary assets and files, but don't add them into
    # the index.md page
    foreach(filter(ishidden, cards)) do x
        generate(x, template; properties=properties)
    end

    mapreduce(*, filter(x->!ishidden(x), cards); init="") do x
        generate(x, template; properties=properties)
    end
end

function generate(secs::AbstractVector{DemoSection}, templates; level=1, properties=Dict{String, Any}())
    mapreduce(*, secs; init="") do x
        properties = merge(properties, x.properties)
        generate(x, templates; level=level, properties=properties)
    end
end

function generate(sec::DemoSection, templates; level=1, properties=Dict{String, Any}())
    header = repeat("#", level) * " " * sec.title * "\n"
    footer = "\n"
    properties = merge(properties, sec.properties) # sec.properties has higher priority

    # either cards or subsections are empty
    # recursively generate the page contents
    if isempty(sec.cards)
        body = generate(sec.subsections, templates; level=level+1, properties=properties)
    else
        items = Dict(
            "cards" => generate(sec.cards, templates["card"], properties=properties),
            "description" => sec.description
        )
        body = Mustache.render(templates["section"], items)
    end
    header * body * footer
end

function generate(card::AbstractDemoCard, template; properties=Dict{String, Any})
    covername = get_covername(card)

    if isnothing(covername)
        # `generate` are called after `save_cover`, we assume that this default cover file is
        # already generated
        coverpath = "covers/" * basename(get_logopath())
    else
        coverpath = is_remote_url(card.cover) ? covername : "covers/" * covername
    end
    
    description = card.description
    cut_idx = 500
    if length(card.description) >= cut_idx
        # cut descriptions into ~500 characters
        offset = findfirst(' ', description[cut_idx:end])
        offset === nothing && (offset = 0)
        offset = cut_idx + offset - 2
        description = description[1:cut_idx] * "..."
    end

    items = Dict(
        "coverpath" => coverpath,
        "id" => card.id,
        "title" => card.title,
        "description" => description,
    )
    Mustache.render(template, items)
end

### save demo card covers

save_cover(path::String, page::DemoPage) = save_cover.(path, page.sections)
function save_cover(path::String, sec::DemoSection)
    save_cover.(path, sec.subsections)
    save_cover.(path, sec.cards)
end

"""
    save_cover(path::String, card)

process the cover image and save it.
"""
function save_cover(path::String, card::AbstractDemoCard)
    covername = get_covername(card)
    if isnothing(covername)
        default_coverpath = get_logopath()
        cover_path = joinpath(path, basename(default_coverpath))
        !isfile(cover_path) && cp(default_coverpath, cover_path)

        # now card uses default cover file as a fallback
        card.cover = basename(default_coverpath)
        return nothing
    end

    is_remote_url(card.cover) && return nothing

    # only save cover image if it is a existing local file
    src_path = joinpath(dirname(card.path), card.cover)
    if !isfile(src_path)
        @warn "cover file doesn't exists" cover_path=src_path

        # reset it back to nothing and fallback to use default cover
        card.cover = nothing
        save_cover(path, card)
    else
        cover_path = joinpath(path, covername)
        if isfile(cover_path)
            @warn "cover file already exists, perhaps you have demos of the same filename" cover_path
        end
        !isfile(cover_path) && cp(src_path, cover_path)
    end
end

function get_covername(card)
    isnothing(card.cover) && return nothing
    is_remote_url(card.cover) && return card.cover

    default_covername = basename(get_logopath())
    card.cover == default_covername && return default_covername
    
    return splitext(basename(card))[1] * splitext(card.cover)[2]
end

get_logopath() = joinpath(pkgdir(DemoCards), "assets", "democards_logo.svg")

### save markdown files

"""
    save_democards(root::String, page::DemoPage; credit, nbviewer_root_url)

recursively process and save source demo file
"""
function save_democards(root::String, page::DemoPage; kwargs...)
    @debug page.root
    save_democards.(root, page.sections; properties=page.properties, kwargs...)
end
function save_democards(root::String, sec::DemoSection; properties, kwargs...)
    @debug sec.root
    properties = merge(properties, sec.properties) # sec.properties has higher priority
    save_democards.(joinpath(root, basename(sec.root)), sec.subsections;
                    properties=properties, kwargs...)
    save_democards.(joinpath(root, basename(sec.root)), sec.cards;
                    properties=properties, kwargs...)
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

### prepare_remote_files

function prepare_remote_files(page)
    # 1. copy all remote files into its corresponding folders
    # 2. record all temporarily remote files
    # 3. rebuild the demo page in no-remote mode
    temp_entry_list = []
    for (root, dirs, files) in walkdir(page.root)
        config_filename in files || continue

        config_path = joinpath(root, config_filename)
        config = JSON.parsefile(config_path)

        if haskey(config, "remote")
            remotes = config["remote"]
            for (dst_entry_name, src_entry_path) in remotes
                dst_entry_path = joinpath(root, dst_entry_name)
                src_entry_path = normpath(root, src_entry_path)
                if !ispath(src_entry_path)
                    @warn "File/folder doesn't exist, skip it." path=src_entry_path
                    continue
                end
                if ispath(dst_entry_path)
                    @warn "A file/folder already exists for remote path $dst_entry_name, skip it." path=dst_entry_path
                    continue
                end

                cp(src_entry_path, dst_entry_path)
                push!(temp_entry_list, dst_entry_path)
            end
        end
    end

    page = isempty(temp_entry_list) ? page : DemoPage(page.root; ignore_remote=true)
    function clean_up_temp_remote_files()
        Base.Sys.iswindows() && GC.gc()
        foreach(temp_entry_list) do x
            rm(x; force=true, recursive=true)
        end
    end
    return page, clean_up_temp_remote_files
end


### postprocess

"""
    redirect_link(src_file, source, root, src, build, edit_branch)

Redirect the "Edit On GitHub" link of generated demo files to its original url, without
this a 404 error is expected.
"""
function redirect_link(source_file, source, root, src, build, edit_branch)
    build_file = get_build_file(source_file, source, build)
    if !isfile(build_file)
        @warn "$build_file doesn't exists, skip"
        return nothing
    end
    contents = read(build_file, String)

    if !isfile(source_file)
        # reach here when user doesn't create a page template index.md
        # just remove the whole button so that user don't click and get 404
        new_contents = replace(contents, regex_edit_on_github=>"")
    else
        # otherwise, redirect the url links
        m = match(regex_edit_on_github, contents)
        isnothing(m) && return nothing
        build_url = m.captures[1]

        src_url = get_source_url(build_url, source, basename(source_file), src)
        new_contents = replace(contents, build_url=>src_url)
    end
    write(build_file, new_contents)
end

function get_source_url(build_url, source, cardname, src)
    # given input:
    #   - projct_root:          "$REPO/blob/$edit_branch"
    #   - build_root:           "$projct_root/$docs_root/$src"
    #   - build_dir:            "$build_root/$prefix/$page/$section/$subsection"
    #   - build_url:            "$build_dir/$cardfile"
    # example of build_url:
    #  "https://github.com/johnnychen94/DemoCards.jl/blob/master/docs/src/quickstart/usage_example/julia_demos/2.cover_on_the_fly.md"
    # we need to generate:
    #   - src_root:             "$projct_root/$docs_root/$src"
    #   - src_dir:              "$src_root/$prefix/$page/$section/$subsection"
    #   - src_url:              "$src_dir/$cardfile"
    # example of src_url:
    #   "https://github.com/johnnychen94/DemoCards.jl/blob/master/docs/quickstart/usage_example/julia_demos/2.cover_on_the_fly.jl"
    source = replace(source, Base.Filesystem.path_separator => "/")

    repo, path = strip.(split(build_url, "/blob/"; limit=2), '/')
    root_to_subsection = replace(splitdir(path)[1], "$(src)/" => ""; count=1)
    root_to_subsection = replace(root_to_subsection, "/$(basename(source))/" => "/$(source)/"; count=1)
    src_url = join([repo, "blob", root_to_subsection, cardname], "/")

    return src_url
end

function get_build_file(source_file, source, build)
    # given inputs:
    #   - source_file: "$source_root/$prefix/$page/$section/$subsection/$card.md"
    #   - source:      "$prefix/$page
    #   - build:       "build"
    # we need to generate:
    #   - build_root: "$source_root/$build"
    #   - build_dir: "$build_root/$page/$section/$subsection
    #   - build_file: "$build_dir/$card.html" or "$build_dir/$card/index.html"

    sep = Base.Filesystem.path_separator
    # add trailing / to avoid incorrect substring match
    source_root = first(split(source_file, source * sep; limit=2))
    build_root = joinpath(source_root, build)
    prefix, page = splitdir(source)

    source_dir, name = splitdir(source_file)
    card, ext = splitext(name)
    _, prefix_to_subsection = split(source_dir, source_root; limit=2)
    if !isempty(prefix)
        # add trailing / to remove leading / for prefix_to_subsection
        # otherwise, joinpath of two absolute path would simply drop the first one
        _, prefix_to_subsection = split(prefix_to_subsection, prefix * sep; limit=2)
    end
    build_dir = joinpath(build_root, prefix_to_subsection)

    prettyurls = isdir(joinpath(build_dir, card))
    # Documenter.HTML behaves differently on prettyurls
    if prettyurls
        build_file = joinpath(build_dir, card, "index.html")
    else
        build_file = joinpath(build_dir, card * ".html")
    end
    return build_file
end

# modified from https://github.com/fredrikekre/Literate.jl to replace the use of @__NBVIEWER_ROOT_URL__
function get_nbviewer_root_url(branch)
    if haskey(ENV, "HAS_JOSH_K_SEAL_OF_APPROVAL") # Travis CI
        repo_slug = get(ENV, "TRAVIS_REPO_SLUG", "unknown-repository")
        deploy_folder = if get(ENV, "TRAVIS_PULL_REQUEST", nothing) == "false"
            tag = ENV["TRAVIS_TAG"]
            isempty(tag) ? "dev" : tag
        else
            "previews/PR$(get(ENV, "TRAVIS_PULL_REQUEST", "##"))"
        end
        return "https://nbviewer.jupyter.org/github/$(repo_slug)/blob/$(branch)/$(deploy_folder)"
    elseif haskey(ENV, "GITHUB_ACTIONS")
        repo_slug = get(ENV, "GITHUB_REPOSITORY", "unknown-repository")
        deploy_folder = if get(ENV, "GITHUB_EVENT_NAME", nothing) == "push"
            if (m = match(r"^refs\/tags\/(.*)$", get(ENV, "GITHUB_REF", ""))) !== nothing
                String(m.captures[1])
            else
                "dev"
            end
        elseif (m = match(r"refs\/pull\/(\d+)\/merge", get(ENV, "GITHUB_REF", ""))) !== nothing
            "previews/PR$(m.captures[1])"
        else
            "dev"
        end
        return "https://nbviewer.jupyter.org/github/$(repo_slug)/blob/$(branch)/$(deploy_folder)"
    elseif haskey(ENV, "GITLAB_CI")
        if (url = get(ENV, "CI_PROJECT_URL", nothing)) !== nothing
            cfg["repo_root_url"] = "$(url)/blob/$(devbranch)"
        end
        if (url = get(ENV, "CI_PAGES_URL", nothing)) !== nothing &&
           (m = match(r"https://(.+)", url)) !== nothing
            return "https://nbviewer.jupyter.org/urls/$(m[1])"
        end
    end
    return ""
end
