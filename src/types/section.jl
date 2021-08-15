abstract type AbstractDemoSection end

demosection(root::String) = DemoSection(root)
function demosection((name, path)::Pair{String, String})
    LocalRemoteSection(name, path, DemoSection(path))
end


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
* `description`: some header description that you want to add before demo cards.
* `properties`: a dictionary of properties that can be propagated to its children items. The same properties in
  the children items, if exist, have higher priority.

The following is an example of `config.json`:

```json
{
    "title": "learn by examples",
    "description": "some one-line description can be useful.",
    "order": [
        "quickstart.md",
        "array.md"
    ],
    "properties": {
        "notebook": "false",
        "julia": "1.6",
        "author": "Johnny Chen"
    }
}
```

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

The following is a typical nested folder structure of a `DemoSection`:

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
struct DemoSection <: AbstractDemoSection
    root::String
    cards::Vector
    subsections::Vector
    title::String
    description::String
    # These properties will be shared by all children of it during build time
    properties::Dict{String, Any}
end

Base.basename(sec::DemoSection) = basename(sec.root)
compact_title(sec::DemoSection) = sec.title
cards(sec::DemoSection) = sec.cards
subsections(sec::DemoSection) = sec.subsections

function DemoSection(root::String)::DemoSection
    root = replace(root, r"[/\\]" => Base.Filesystem.path_separator) # windows compatibility
    isdir(root) || throw(ArgumentError("section root should be a valid dir, instead it's $(root)"))

    path = joinpath.(root, filter(x->!startswith(x, "."), readdir(root))) # filter out hidden files
    card_paths = filter(x->isfile(x) && !endswith(x, config_filename), path)
    section_paths = filter(x->isdir(x)&&!(basename(x) in ignored_dirnames), path)

    if !isempty(card_paths) && !isempty(section_paths)
        throw(ArgumentError("section folder $(root) should only hold either cards or subsections"))
    end

    config_file = joinpath(root, config_filename)
    config = isfile(config_file) ? JSON.parsefile(config_file) : Dict()

    # For files that `democard` fails to recognized, dummy
    # `UnmatchedCard` will be generated. Currently, we only
    # throw warnings for it.
    cards = AbstractDemoCard[democard(x) for x in card_paths]
    unmatches = filter(cards) do x
        x isa UnmatchedCard
    end
    if !isempty(unmatches)
        msg = join(map(basename, unmatches), "\", \"")
        @warn "skip unmatched file: \"$msg\"" section_dir=root
    end
    remote_card_paths = read_remote_cards(config, root)
    cards = [cards..., democard.(remote_card_paths)...]
    cards = filter!(cards) do x
        !(x isa UnmatchedCard)
    end

    subsections = map(DemoSection, section_paths)
    remote_sections = map(demosection, read_remote_sections(config, root))
    subsections = [subsections..., remote_sections...]

    section = DemoSection(root, cards, subsections, "", "", Dict{String, Any}())
    cards, subsections = sort_by_order(section, config)

    title = load_config(section, "title"; config=config)
    description = load_config(section, "description"; config=config)

    properties = if haskey(config, "properties")
        Dict{String, Any}(config["properties"])
    else
        Dict{String, Any}()
    end

    DemoSection(root, cards, subsections, title, description, properties)
end

function sort_by_order(sec::DemoSection, config)
    cards = sec.cards
    subsections = sec.subsections

    ordered_paths = load_config(sec, "order"; config=config)
    if !isempty(sec.cards)
        indices = map(ordered_paths) do ref
            findfirst(cards) do card
                basename(card) == ref
            end
        end
        cards = cards[indices]
        subsections = []
    else
        indices = map(ordered_paths) do ref
            findfirst(subsections) do sec
                basename(sec) == ref
            end
        end
        subsections = subsections[indices]
        cards = []
    end

    return cards, subsections
end

function load_config(sec::DemoSection, key; config=Dict())
    if isempty(config)
        config_file = joinpath(sec.root, config_filename)
        config = isfile(config_file) ? JSON.parsefile(config_file) : Dict()
    end
    # config could still be an empty dictionary

    if key == "order"
        haskey(config, key) || return get_default_order(sec)

        order = config[key]
        validate_order(order, sec)
        return order
    elseif key == "title"
        get(config, key, get_default_title(sec))
    elseif key == "description"
        get(config, key, "")
    else
        throw(ArgumentError("Unrecognized key $(key) for DemoSection"))
    end
end

"""return case-insensitive alphabetic order"""
function get_default_order(sec::DemoSection)
    order = isempty(sec.cards) ? basename.(sec.subsections) : basename.(sec.cards)
    sort(order, by = x->lowercase(x))
end

function is_demosection(dir)
    try
        # if fails to parse, then it is not a valid demo page
        @suppress_err DemoSection(dir)
        return true
    catch err
        @debug err
        return false
    end
end

###
# LocalRemoteSection
###

struct LocalRemoteSection{T<:AbstractDemoSection} <: AbstractDemoSection
    name::String
    path::String
    item::T
    function LocalRemoteSection(name::String, path::String, item::T) where T<:AbstractDemoSection
        basename(name) == name || throw(ArgumentError("`name` should not be a path, instead it is: \"$name\". Do you mean \"$(basename(name))\""))
        isdir(path) || throw(ArgumentError("folder $path does not exist."))
        new{T}(name, path, item)
    end
end
function LocalRemoteSection(name::String, path::String, card::LocalRemoteSection{T}) where T<:AbstractDemoCard
    LocalRemoteSection(name, path, card.item)
end

Base.basename(sec::LocalRemoteSection) = sec.name
compact_title(sec::LocalRemoteSection) = "$(sec.name) => $(sec.path)"
cards(sec::LocalRemoteSection) = cards(sec.item)
subsections(sec::LocalRemoteSection) = subsections(sec.item)
