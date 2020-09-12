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
* `title`: specify the title of this demo page. By default, it's the folder name of `root`. Will be override by `template`.

The following is an example of `config.json`:

```json
{
    "template": "template.md",
    "order": [
        "basic",
        "advanced"
    ]
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
struct DemoPage
    root::String
    sections::Vector{DemoSection}
    template::String
    title::String
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
    
    sections = map(DemoSection, section_paths)


    # first consturct an incomplete page
    # then load the config and reconstruct a new one
    page = DemoPage(root, sections, "", "")

    section_paths = joinpath.(root, load_config(page, "order"))
    ordered_sections = map(DemoSection, section_paths) # TODO: technically, we don't need to regenerate sections here

    title = load_config(page, "title")
    page = DemoPage(root, ordered_sections, "", title)

    # default template requires a title
    template = load_config(page, "template")
    DemoPage(root, ordered_sections, template, title)
end

function load_config(page::DemoPage, key)
    json_path = joinpath(page.root, config_filename)
    json_config = isfile(json_path) ? JSON.parsefile(json_path) : Dict()

    template_file = joinpath(page.root, get(json_config, "template", template_filename))
    config = parse(Val(:Markdown), template_file)
    config = merge(json_config, config) # template has higher priority over config file

    if key == "order"
        haskey(config, key) || return get_default_order(page)

        order = config[key]
        validate_order(order, page)
        return order
    elseif key == "title"
        return get(config, key, get_default_title(page))
    elseif key == "template"
        return load_template(page, config)
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
