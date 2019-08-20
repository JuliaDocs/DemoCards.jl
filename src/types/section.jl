"""
    struct DemoSection <: Any
    DemoSection(root::String)

Constructs a demo section that holds either nested subsections or demo cards.

# Fields

Besides the root path to the demo section folder `root`, this struct has some other fields:

* `cards`: demo cards found in `root`
* `subsections`: nested subsections found in `root`

# Configuration

You can manage an extra `config.json` file to customize rendering of a demo section.
Supported items are:

* `order`: specify the cards order or subsections order. By default, it's case-insensitive alphabetic order.
* `title`: specify the title of this demo section. By default, it's the folder name of `root`.

The following is an example of `config.json`:

```json
{
    "title": "learn by examples"
    "order": [
        "quickstart.md",
        "array.md"
    ]
}
```

!!! warning

    You can't specify files or foldernames in other folders.

# Examples

The following is the simplest folder structure of a `DemoSection`:

```text
section
├── demo_1.md
├── demo_2.md
├── demo_3.md
├── demo_4.md
├── demo_5.md
├── demo_6.md
├── demo_7.md
└── demo_8.md
```

The following is a typical folder structure of a `DemoSection`:

```text
section
├── config.json
├── part1
│   ├── demo_21.md
│   └── demo_22.md
└── part2
    ├── config.json
    ├── demo_23.md
    └── demo_24.md
```

!!! warning

    A section should only hold either subsections or demo files. A folder that has both subfolders and demo files (e.g., `*.md`) is invalid.

See also: [`MarkdownDemoCard`](@ref DemoCards.MarkdownDemoCard), [`DemoPage`](@ref DemoCards.DemoPage)
"""
struct DemoSection
    root::String
    cards::Vector # Why would `Vector{<:AbstractDemoCard}` fail here?
    subsections::Vector{DemoSection}
    title::String
end

basename(sec::DemoSection) = basename(sec.root)

function DemoSection(root::String)::DemoSection
    isdir(root) || throw("section root should be a valid dir, instead it's $(root)")

    path = joinpath.(root, readdir(root))
    card_paths = filter(x->isfile(x) && !endswith(x, config_filename), path)
    section_paths = filter(x->isdir(x)&&!(basename(x) in ignored_dirnames), path)

    if isempty(card_paths) && isempty(section_paths)
        throw("emtpy section folder $(root)")
    elseif !xor(isempty(card_paths), isempty(section_paths))
        throw("section folder $(root) should only hold either cards or subsections")
    end

    # first consturct an incomplete section
    # then load the config and reconstruct a new one
    section = DemoSection(root,
                          map(democard, card_paths),
                          map(DemoSection, section_paths),
                          "")

    ordered_paths = joinpath.(root, load_config(section, "order"))
    if !isempty(section.cards)
        cards = map(democard, ordered_paths)
        subsections = []
    else
        cards = []
        subsections = map(DemoSection, ordered_paths)
    end

    title = load_config(section, "title")
    DemoSection(root, cards, subsections, title)
end


function load_config(sec::DemoSection, key)
    path = joinpath(sec.root, config_filename)
    config = isfile(path) ? JSON.parsefile(path) : Dict()

    if key == "order"
        haskey(config, key) || return get_default_order(sec)

        order = config[key]
        validate_order(order, sec)
        return order
    elseif key == "title"
        get(config, key, basename(sec))
    else
        throw("Unrecognized key $(key) for DemoSection")
    end
end

"""return case-insensitive alphabetic order"""
function get_default_order(sec::DemoSection)
    order = isempty(sec.cards) ? basename.(sec.subsections) : basename.(sec.cards)
    sort(order, by = x->lowercase(x))
end
