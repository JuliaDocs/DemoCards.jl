"""
This function combines `ignore_CR` with ignoring difference between `ref` and
`actual` resulting from blank lines.
"""
ignore_all(ref::AbstractString, actual::AbstractString) = isequal(_ignore_all(ref), _ignore_all(actual))

_ignore_all(x::AbstractString) = _ignore_tempdir(_ignore_blank_line_and_CR(_ignore_CR(x)))

const edit_url_re = r"EditURL = \"(.*)\""

function _ignore_tempdir(doc::AbstractString)
    path_match = match(edit_url_re, doc)
    if path_match === nothing
        return doc
    end
    path = unescape_string(path_match[1])
    if !startswith(path, "/") && match(r"^[A-Z]:", path) === nothing
        # all we need to do is normalise the path separator
        norm_dir = replace(path, "\\" => "/")
    else
        # we need to remove the tempdir part of the path
        bits = split(replace(path, "\\" => "/"), "/")
        tmp_dir = findlast(x -> startswith(x, "jl_"), bits)
        if tmp_dir === nothing
            error("Cannot find tempdir in $path")
        end
        norm_dir = "/TEMPDIR/" * join(bits[end+1:end], "/")
    end
    return replace(doc, edit_url_re => "EditURL = \"$norm_dir\"")
end

"""
This function combines `ignore_CR` with ignoring difference between `ref` and
`actual` resulting from blank lines.
"""
ignore_blank_line_and_CR(ref::AbstractString, actual::AbstractString) = isequal(_ignore_blank_line_and_CR(ref), _ignore_blank_line_and_CR(actual))

_ignore_blank_line_and_CR(x::AbstractString) = _ignore_blank_line(_ignore_CR(x))

_ignore_blank_line(x::AbstractString) = replace(x, r"\n+"=>"\n")

"""
    ignore_CR(ref::AbstractString, actual::AbstractString)

Ignore the CRLF(`\\r\\n`) and LF(`\\n`) difference by removing `\\r` from the given string.

CRLF format is widely used by Windows while LF format is mainly used by Linux.
"""
ignore_CR(ref::AbstractString, actual::AbstractString) = isequal(_ignore_CR(ref), _ignore_CR(actual))

_ignore_CR(x::AbstractString) = replace(x, "\r\n"=>"\n")
