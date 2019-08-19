struct DemoSection
    root::String
    cards::Vector # can be Any[]
    subsections::Vector{DemoSection}
    # we don't need a title field, that is defined by the page template
end

function DemoSection(root::String)::DemoSection
    isdir(root) || throw("section root should be a valid dir, instead it's $(root)")

    path = joinpath.(root, readdir(root))
    card_paths = filter(x->isfile(x) && !endswith(x, config_filename), path)
    section_paths = filter(isdir, path)

    if isempty(card_paths) && isempty(section_paths)
        throw("emtpy section folder $(root)")
    elseif !xor(isempty(card_paths), isempty(section_paths))
        throw("section folder $(root) should only hold either cards or subsections")
    end

    # first consturct an incomplete section
    # then load the config and reconstruct a new one
    section = DemoSection(root,
                          map(democard, card_paths),
                          map(DemoSection, section_paths))

    ordered_paths = joinpath.(root, load_config(section, "order"))
    if !isempty(section.cards)
        cards = map(democard, ordered_paths)
        subsections = []
    else
        cards = []
        subsections = map(DemoSection, ordered_paths)
    end

    DemoSection(root, cards, subsections)
end


function load_config(sec::DemoSection, key)
    path = joinpath(sec.root, config_filename)
    config = isfile(path) ? JSON.parsefile(path) : Dict()

    if key == "order"
        haskey(config, key) || return get_default_order(sec)

        order = config[key]
        validate_order(order, sec)
        return order
    else
        throw("Unrecognized key $(key) for DemoSection")
    end
end

"""return case-insensitive alphabetic order"""
function get_default_order(sec::DemoSection)
    order = isempty(sec.cards) ? get_name.(sec.subsections) : get_name.(sec.cards)
    sort(order, by = x->lowercase(x))
end

get_name(sec::DemoSection) = splitpath(sec.root)[end]
