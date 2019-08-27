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
* `template`: path to template filename. The content of the template file should has one and only one `{{{democards}}}`.
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
    isdir(root) || throw(ArgumentError("page root should be a valid dir, instead it's $(root)"))
    root = rstrip(root, '/') # otherwise basename(root) will returns `""`

    path = joinpath.(root, filter(x->!startswith(x, "."), readdir(root))) # filter out hidden files
    section_paths = filter(x->isdir(x)&&!(basename(x) in ignored_dirnames),
                           path)
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
    path = joinpath(page.root, config_filename)
    config = isfile(path) ? JSON.parsefile(path) : Dict()

    if key == "order"
        haskey(config, key) || return get_default_order(page)

        order = config[key]
        validate_order(order, page)
        return order
    elseif key == "title"
        return load_title(page, config)
    elseif key == "template"
        haskey(config, key) || return get_default_template(page)

        template_file = config[key]
        template_path = joinpath(page.root, template_file)

        check_ext(template_path, :markdown)
        if 1 != sum(occursin.("{{{democards}}}", readlines(template_path)))
            throw(ArgumentError("invalid template file $(template_path): it should has one and only one {{{democards}}}"))
        end

        return read(template_path, String)
    else
        throw(ArgumentError("Unrecognized key $(key) for DemoPage"))
    end
end

"""
    load_title(page::DemoPage, config)

load title from config using the following priority rules:

1. parse the title out from the template file
2. use config["title"]
3. fallback: use the folder name
"""
function load_title(page::DemoPage, config)
    key = "title"
    title = load_template_config(page, key)

    if haskey(config, key)
        if isnothing(title)
            return config[key]
        else
            path = joinpath(page.root, config_filename)
            @warn("config item $(key) in $(path) is suppressed by \"template\"")
            return title
        end
    else
        if isnothing(title)
            return basename(page)
        else
            return title
        end
    end
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

function load_template_config(page::DemoPage, key)
    config = parse_markdown(page.template)
    get(config, key, nothing)
end
