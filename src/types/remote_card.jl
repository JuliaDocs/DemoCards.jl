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
