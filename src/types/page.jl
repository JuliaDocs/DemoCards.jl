"""
    struct DemoPage <: Any
    DemoPage(root::String)

Constructs a demo page object.

# Fields

Besides the root path to the demo page folder `root`, this struct has some other fields:

* `title`: page title
* `template`: template content of the demo page.
* `sections`: demo sections found in `root`

# Configuration

You can manage an extra `config.json` file to customize rendering of a demo page.
Supported items are:

* `order`: specify the sections order. By default, it's case-insensitive alphabetic order.
* `template`: path to template filename. By default, it's `"index.md"`. The content of the template file should has one and only one `{{{democards}}}`.
* `theme`: specify which card theme should be used to generate the index page. If not specified, it
  will default to `nothing`.
* `title`: specify the title of this demo page. By default, it's the folder name of `root`. Will be override by `template`.
* `properties`: a dictionary of properties that can be propagated to its children items. The same properties in
  the children items, if exist, have higher priority.

The following is an example of `config.json`:

```json
{
    "template": "template.md",
    "theme": "grid",
    "order": [
        "basic",
        "advanced"
    ],
    "properties": {
        "notebook": "false",
        "julia": "1.6",
        "author": "Johnny Chen"
    }
}
```

# Examples

The following is the simplest folder structure of a `DemoPage`:

```text
demos
└── basic
    ├── demo_1.md
    ├── demo_2.md
    ├── demo_3.md
    ├── demo_4.md
    ├── demo_5.md
    ├── demo_6.md
    ├── demo_7.md
    └── demo_8.md
```

!!! note

    A `DemoPage` doesn't manage demo files directly, so here you'll need
    a DemoSection `basic` to manage them.

The following is a typical folder structure of a `DemoPage`:

```text
demos
├── advanced
│   ├── advanced_demo_1.md
│   └── advanced_demo_2.md
├── basic
│   ├── part1
│   │   ├── basic_demo_1_1.md
│   │   └── basic_demo_1_2.md
│   └── part2
│       ├── config.json
│       ├── basic_demo_2_1.md
│       └── basic_demo_2_2.md
├── config.json
└── template.md
```

!!! warning

    A section should only hold either subsections or demo files. A folder that has both subfolders and demo files (e.g., `*.md`) is invalid.

See also: [`MarkdownDemoCard`](@ref DemoCards.MarkdownDemoCard), [`DemoSection`](@ref DemoCards.DemoSection)
"""
mutable struct DemoPage
    root::String
    sections::Vector{DemoSection}
    template::String
    theme::Union{Nothing, String}
    stylesheet::Union{Nothing, String}
    title::String
    # These properties will be shared by all children of it during build time
    properties::Dict{String, Any}
end

basename(page::DemoPage) = basename(page.root)

function DemoPage(root::String)::DemoPage
    root = replace(root, r"[/\\]" => Base.Filesystem.path_separator) # windows compatibility
    isdir(root) || throw(ArgumentError("page root does not exist: $(root)"))
    root = rstrip(root, '/') # otherwise basename(root) will returns `""`

    path = joinpath.(root, filter(x->!startswith(x, "."), readdir(root))) # filter out hidden files
    section_paths = filter(x->isdir(x)&&!(basename(x) in ignored_dirnames),
                           path)
    
    if isempty(section_paths)
        # This is an edge and trivial case that we need to disallow; we want the following
        # folder structure be uniquely parsed as a demo section and not a demo page without
        # ambiguity.
        # ```
        # demos/
        # └── demo1.jl
        # ```
        msg = "can not find a valid page structure in page dir \"$root\"\nit should have at least one folder as section inside it"
        throw(ArgumentError(msg))
    end

    json_path = joinpath(root, config_filename)
    json_config = isfile(json_path) ? JSON.parsefile(json_path) : Dict()

    template_file = joinpath(root, get(json_config, "template", template_filename))
    config = parse(Val(:Markdown), template_file)
    config = merge(json_config, config) # template has higher priority over config file

    sections = filter(map(DemoSection, section_paths)) do sec
        empty_section = isempty(sec.cards) && isempty(sec.subsections)
        if empty_section
            @warn "Empty section detected, remove from the demo page tree." section=relpath(sec.root, root)
            return false
        else
            return true
        end
    end
    isempty(sections) && error("Empty demo page, you have to add something.")

    page = DemoPage(root, sections, "", nothing, nothing, "", Dict{String, Any}())
    page.theme = load_config(page, "theme"; config=config)
    page.stylesheet = load_config(page, "stylesheet"; config=config)

    section_orders = load_config(page, "order"; config=config)
    section_orders = map(sections) do sec
        findfirst(x-> x == basename(sec.root), section_orders)
    end
    ordered_sections = sections[section_orders]

    title = load_config(page, "title"; config=config)
    page.sections = ordered_sections
    page.title = title

    # default template requires a title
    template = load_config(page, "template"; config=config)
    page.template = template

    if haskey(config, "properties")
        properties = config["properties"]::Dict
        merge!(page.properties, properties)
    end
    return page
end

function load_config(page::DemoPage, key; config=Dict())
    if isempty(config)
        json_path = joinpath(page.root, config_filename)
        json_config = isfile(json_path) ? JSON.parsefile(json_path) : Dict()

        template_file = joinpath(page.root, get(json_config, "template", template_filename))
        config = parse(Val(:Markdown), template_file)
        config = merge(json_config, config) # template has higher priority over config file
    end
    # config could still be an empty dictionary

    if key == "order"
        haskey(config, key) || return get_default_order(page)

        order = config[key]
        validate_order(order, page)
        return order
    elseif key == "title"
        return get(config, key, get_default_title(page))
    elseif key == "template"
        return load_template(page, config)
    elseif key == "theme"
        theme = get(config, key, nothing)
        if !isnothing(theme) && lowercase(theme) == "nothing"
            theme = nothing
        end
        return theme
    elseif key == "stylesheet"
        return get(config, key, nothing)
    else
        throw(ArgumentError("Unrecognized key $(key) for DemoPage"))
    end
end

function load_template(page, config)
    key = "template"
    if haskey(config, key)
        # windows compatibility
        template_name = replace(config[key],
                            r"[/\\]" => Base.Filesystem.path_separator)
        template_file = joinpath(page.root, template_name)
    else
        template_file = joinpath(page.root, template_filename)
    end

    isfile(template_file) || return get_default_template(page)

    check_ext(template_file, :markdown)
    if 1 != sum(occursin.("{{{democards}}}", readlines(template_file)))
        throw(ArgumentError("invalid template file $(template_file): it should has one and only one {{{democards}}}"))
    end
    return read(template_file, String)
end

get_default_order(page::DemoPage) =
    sort(basename.(page.sections), by = x->lowercase(x))

function get_default_template(page::DemoPage)
    header = "# $(page.title)\n\n"
    # TODO: by doing this we loss the control on section-level template
    content = "{{{democards}}}" # render by Mustache
    footer = ""
    return header * content * footer
end

# page utils

"""
    infer_pagedir(card_path; rootdir="")

Given a demo card path, infer the *outmost* dir path that makes it a valid demo page. If it fails to
find such dir path, return `nothing`.

The inference is done recursively, `rootdir` sets a stop condition for the inference process.

!!! warning
    This inference may not be the exact page dir in trivial cases, for example:

    ```
    testdir/
    └── examples
        └── sections
            └── demo1.md
    ```

    Both `testdir` and `examples` can be valid dir path for a demo page, this function would
    just return `testdir` as it is the outmost match.

"""
function infer_pagedir(path; rootdir::String=first(splitdrive(path)))
    # the last root path that `DemoPage(root)` successfully parses
    if is_demopage(path)
        root, dir = splitdir(path) # we need the outmost folder, so not return right here
    elseif is_demosection(path)
        root, dir = splitdir(path)
    elseif is_democard(path)
        root, dir = splitdir(dirname(path))
    else
        return nothing
    end

    while true
        if is_demopage(root)
            root, dir = splitdir(root)
        else
            pagedir = joinpath(root, dir)
            return is_demopage(pagedir) ? pagedir : nothing # in case it fails at the first try
        end

        root in push!(["/", ""], rootdir) && return nothing
    end
end

function is_demopage(dir)
    try
        # if fails to parse, then it is not a valid demo page
        @suppress_err DemoPage(dir)
        return true
    catch err
        @debug err
        return false
    end
end
