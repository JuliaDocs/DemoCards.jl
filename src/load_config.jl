"""
    load_config(page::DemoPage, key)
    load_config(section::DemoSection, key)

load the config `key` from the config file of `page` or `section`.

Although each dir holds a `config.json`, it is optional, the `key` item is also
optional.

# Options for key

## order::AbstractArray{String} -- used by `DemoPage` and `DemoSection`

Specify the order of items that will be placed. The default order is
case-insensitive alphabetic order.

## title::String -- used by `DemoPage`

Specify the title of section and page. TODO: explain the default behaviors.

## template::String -- used by `DemoPage`

Specify the path to template file used to generate `DemoPage`. The content of
template file must contains a `{{sections}}` placeholder.

"""
function load_config(x::T, key) where T <: Union{DemoSection,DemoPage}
    # although everytime we parse the whole config file when we read the key,
    # it doesn't matter much here since we don't care much about the performance
    path = joinpath(x.root, config_filename)
    config = isfile(path) ? JSON.parsefile(path) : Dict()

    # read and validate the content of key
    # no need to validate default configuration
    if key == "order"
        haskey(config, key) || return get_default_order(x)

        order = config[key]
        validate_order(order, x)
        return order
    elseif key == "title" && T <: DemoPage
        haskey(config, key) || return get_default_title(x)

        if haskey(config, "template")
            @warn("config item \"title\" in $(path) is suppressed by \"template\"")
        end
        return config[key]
    elseif key == "template" && T <: DemoPage
        haskey(config, key) || return get_default_template(x)

        template_file = config[key]
        template_path = joinpath(x.root, template_file)
        check_ext(template_path, :markdown)
        template = read(template_path, String)

        validate_page_template(template, x)
        return template
    else
        throw("Unrecognized key $(key) for $(T)")
    end
end

### default config behaviors

"""return case-insensitive alphabetic order"""
function get_default_order(sec::DemoSection)
    order = isempty(sec.cards) ? get_name.(sec.subsections) : get_name.(sec.cards)
    sort(order, by = x->lowercase(x))
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

get_default_title(x::Union{DemoSection,DemoPage}) = get_name(x)

function validate_order(order::AbstractArray, x::Union{DemoPage, DemoSection})
    default_order = get_default_order(x)
    if intersect(order, default_order) == union(order, default_order)
        return true
    else
        config_filepath = joinpath(x.root, config_filename)

        entries = join(string.(setdiff(order, default_order)), "\n")
        isempty(entries) || @warn("The following entries in $(config_filepath) are not used anymore:\n$(entries)")

        entries = join(string.(setdiff(default_order, order)), "\n")
        isempty(entries) || @warn("The following entries in $(config_filepath) are missing:\n$(entries)")

        throw("incorrect order in $(config_filepath), please check the previous warning message.")
    end
end

function validate_page_template(template::String, page::DemoPage)
    # TODO: we need to check if there exists one and only one `{{sections}}` placeholder
    true
end
