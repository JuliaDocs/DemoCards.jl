struct LocalRemoteCard{T<:AbstractDemoCard} <: AbstractDemoCard
    name::String
    path::String
    item::T
    function LocalRemoteCard(name::String, path::String, item::T) where T<:AbstractDemoCard
        basename(name) == name || throw(ArgumentError("`name` should not be a path, instead it is: \"$name\". Do you mean \"$(basename(name))\""))
        isempty(splitext(name)[2]) && throw(ArgumentError("Remote entry name `$name`for card should has extensions."))
        isfile(path) || throw(ArgumentError("file $path does not exist."))
        new{T}(name, path, item)
    end
end
function LocalRemoteCard(name::String, path::String, card::LocalRemoteCard{T}) where T<:AbstractDemoCard
    LocalRemoteCard(name, path, card.item)
end

ishidden(card::LocalRemoteCard) = ishidden(card.item)
Base.basename(card::LocalRemoteCard) = card.name

function Base.show(io::IO, card::LocalRemoteCard)
    print(io, basename(card), " => ", card.path)
end

function generate(card::LocalRemoteCard, template; kwargs...)
    with_tempcard(card) do tempcard
        generate(tempcard, template; kwargs...)
    end
end
function save_democards(card_dir::String, card::LocalRemoteCard; kwargs...)
    dst = joinpath(card_dir, basename(card))
    isfile(dst) && throw(ArgumentError("file $dst already exists."))

    with_tempcard(card) do tempcard
        save_democards(card_dir, tempcard; kwargs...)
    end
end

function save_cover(path::String, card::LocalRemoteCard)
    with_tempcard(card) do tempcard
        save_cover(path, tempcard)
    end
end

# TODO: this file copy is not very necessary, and it get called many times
function with_tempcard(f, card)
    mktempdir() do dir
        # copy and rename file so that generated files are correctly handled
        # For example:
        #   "cardname" => "path/to/sourcefile.jl"
        # Later workflow uses "cardname.md" instead of "sourcefile.md"
        tmpfile = joinpath(dir, basename(card))
        cp(card.path, tmpfile)
        f(democard(tmpfile))
    end
end
