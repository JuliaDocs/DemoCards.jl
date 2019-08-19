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

function load_config(page::DemoPage, key)
    path = joinpath(page.root, config_filename)
    config = isfile(path) ? JSON.parsefile(path) : Dict()

    if key == "order"
        haskey(config, key) || return get_default_order(page)

        order = config[key]
        validate_order(order, page)
        return order
    elseif key == "title"
        haskey(config, key) || return get_default_title(page)

        if haskey(config, "template")
            @warn("config item \"title\" in $(path) is suppressed by \"template\"")
        end
        return config[key]
    elseif key == "template"
        haskey(config, key) || return get_default_template(page)

        template_file = config[key]
        template_path = joinpath(page.root, template_file)
        check_ext(template_path, :markdown)
        template = read(template_path, String)

        validate_page_template(template, page)
        return template
    else
        throw("Unrecognized key $(key) for DemoPage")
    end
end

get_default_order(page::DemoPage) =
    sort(get_name.(page.sections), by = x->lowercase(x))

function get_default_template(page::DemoPage)
    header = "# $(page.title)\n\n"
    # TODO: by doing this we loss the control on section-level template
    content = "{{{sections}}}" # render by Mustache
    footer = ""
    return header * content * footer
end

get_default_title(page::DemoPage) = get_name(page)

get_name(page::DemoPage) = splitpath(page.root)[end]

function validate_page_template(template::String, page::DemoPage)
    # TODO: we need to check if there exists one and only one `{{sections}}` placeholder
    true
end
