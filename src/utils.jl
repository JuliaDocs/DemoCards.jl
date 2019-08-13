function validate_file(path, filetype = :text)
    isfile(path) || throw("$(path) is not a valid file")
    _, ext = splitext(path)
    if filetype == :text
        return true
    elseif filetype == :markdown
        return lowercase(ext) in markdown_exts || throw("$(path) is not a valid markdown file")
    else
        throw("Unrecognized filetype $(filetype)")
    end
end

"""return the dirname or filename"""
get_name(x::Union{DemoPage,DemoSection}) = splitpath(x.root)[end]
get_name(x::DemoCard) = get_name(x.demo)
get_name(x::AbstractDemoFile) = splitpath(x.path)[end]
