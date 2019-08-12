# splitpath requires at least Julia 1.1.
# copy from https://github.com/JuliaLang/julia/blob/6f4b6fb62ceb5e5b6a00206b9b542dc321f0bbb7/base/path.jl
if v"1.0" <= VERSION < v"1.1"
    if Sys.isunix()
        const path_dir_splitter = r"^(.*?)(/+)([^/]*)$"
    elseif Sys.iswindows()
        const path_dir_splitter = r"^(.*?)([/\\]+)([^/\\]*)$"
    else
        error("path primitives for this OS need to be defined")
    end

    _splitdir_nodrive(path::String) = _splitdir_nodrive("", path)
    function _splitdir_nodrive(a::String, b::String)
        m = match(path_dir_splitter,b)
        m === nothing && return (a,b)
        a = string(a, isempty(m.captures[1]) ? m.captures[2][1] : m.captures[1])
        a, String(m.captures[3])
    end

    function splitpath(p::String)
        drive, p = splitdrive(p)
        out = String[]
        isempty(p) && (pushfirst!(out,p))  # "" means the current directory.
        while !isempty(p)
            dir, base = _splitdir_nodrive(p)
            dir == p && (pushfirst!(out, dir); break)  # Reached root node.
            if !isempty(base)  # Skip trailing '/' in basename
                pushfirst!(out, base)
            end
            p = dir
        end
        if !isempty(drive)  # Tack the drive back on to the first element.
            out[1] = drive*out[1]  # Note that length(out) is always >= 1.
        end
        return out
    end
end
