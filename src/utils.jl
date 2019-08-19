function validate_file(path, filetype = :text)
    isfile(path) || throw("$(path) is not a valid file")
    check_ext(path, filetype)
end

function check_ext(path, filetype = :text)
    _, ext = splitext(path)
    if filetype == :text
        return true
    elseif filetype == :markdown
        return lowercase(ext) in markdown_exts || throw("$(path) is not a valid markdown file")
    else
        throw("Unrecognized filetype $(filetype)")
    end
end

### common utils for DemoPage and DemoSection

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
