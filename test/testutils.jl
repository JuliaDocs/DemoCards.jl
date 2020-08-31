"""
    ignore_CR(ref::AbstractString, actual::AbstractString)

Ignore the CRLF(`\\r\\n`) and LF(`\\n`) difference by removing `\\r` from the given string.

CRLF format is widely used by Windows while LF format is mainly used by Linux.
"""
ignore_CR(ref::AbstractString, actual::AbstractString) = isequal(_ignore_CR(ref), _ignore_CR(actual))

_ignore_CR(x::AbstractString) = replace(x, "\r\n"=>"\n")
