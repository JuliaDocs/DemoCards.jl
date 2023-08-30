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
