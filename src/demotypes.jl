""" recognize and generate a demofile"""
function democard(path::String)::AbstractDemoCard
    validate_file(path)
    _, ext = splitext(path)
    if ext in markdown_exts
        return MarkdownDemoCard(path)
    else
        throw("unrecognized democard format $(path)")
    end
end


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


struct DemoPage
    root::String
    sections::Vector{DemoSection}
    template::String
    title::String
end

function DemoPage(root::String)::DemoPage
    isdir(root) || throw("page root should be a valid dir, instead it's $(root)")

    section_paths = filter(isdir, joinpath.(root, readdir(root)))
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
