module PlutoNotebook

using Dates
using DemoCards: AbstractDemoCard
import DemoCards: PlutoDemoCard, save_democards, make_badges, parse
isdefined(Base, :get_extension) ? (using PlutoStaticHTML) : (using ..PlutoStaticHTML)
using PlutoStaticHTML


function PlutoDemoCard(path::AbstractString)::PlutoDemoCard
    # first consturct an incomplete democard, and then load the config
    card = PlutoDemoCard(path, "", "", "", "", "", DateTime(0), JULIA_COMPAT, false)

    config = parse(card)
    card.cover = load_config(card, "cover"; config = config)
    card.title = load_config(card, "title"; config = config)
    card.date = load_config(card, "date"; config = config)
    card.author = load_config(card, "author"; config = config)
    card.julia = load_config(card, "julia"; config = config)
    # default id requires a title
    card.id = load_config(card, "id"; config = config)
    # default description requires a title
    card.description = load_config(card, "description"; config = config)
    card.hidden = load_config(card, "hidden"; config = config)

    return card
end


"""
    save_democards(card_dir::AbstractString, card::PlutoDemoCard;
                   project_dir,
                   src,
                   credit,
                   nbviewer_root_url)

process the original julia file and save it.

The processing pipeline is:

1. preprocess and copy source file
3. generate markdown file
4. insert header and footer to generated markdown file
"""
function save_democards(
    card_dir::AbstractString,
    card::PlutoDemoCard;
    credit,
    nbviewer_root_url,
    project_dir = Base.source_dir(),
    src = "src",
    throw_error = false,
    properties = Dict{String,Any}(),
    kwargs...,
)
    if !isabspath(card_dir)
        card_dir = abspath(card_dir)
    end
    isdir(card_dir) || mkpath(card_dir)
    @debug card.path

    # copy to card dir and do things
    cardname = splitext(basename(card.path))[1]
    # pluto outputs are expensive, we save the output to a cache dir
    # these cache dir contains the render files from previous runs,
    # saves time, while rendering
    render_dir = joinpath(project_dir, "pluto_output") |> abspath
    isdir(render_dir) || mkpath(render_dir)

    nb_path = joinpath(card_dir, "$(cardname).jl")
    md_path = joinpath(card_dir, "$(cardname).md")

    cp(card.path, nb_path)

    if VERSION < card.julia
        # It may work, it may not work; I hope it would work.
        @warn "The running Julia version `$(VERSION)` is older than the declared compatible version `$(card.julia)`. You might need to upgrade your Julia."
    end

    oopts = OutputOptions(; append_build_context = false)
    output_format = documenter_output
    bopts = BuildOptions(card_dir; previous_dir = render_dir, output_format = output_format)
    # don't run notebooks in parallel
    # TODO: User option to run it parallel or not
    build_notebooks(bopts, ["$(cardname).jl"], oopts)

    # move rendered files to cache
    cache_path = joinpath(render_dir, basename(md_path))
    cp(md_path, cache_path; force = true)

    badges = make_badges(
        card;
        src = src,
        card_dir = card_dir,
        nbviewer_root_url = nbviewer_root_url,
        project_dir = project_dir,
        build_notebook = false,
    )

    header = "# [$(card.title)](@id $(card.id))\n"
    footer = pluto_footer

    body = join(readlines(md_path), "\n")
    write(md_path, header, badges * "\n\n", body, footer)

    return nothing
end

function make_badges(
    card::PlutoDemoCard;
    src,
    card_dir,
    nbviewer_root_url,
    project_dir,
    build_notebook,
)
    cardname = splitext(basename(card.path))[1]
    badges = []
    push!(badges, "[![Source code]($download_badge)]($(cardname).jl)")

    push!(badges, invoke(make_badges, Tuple{AbstractDemoCard}, card))

    join(badges, " ")
end

parse(card::PlutoDemoCard) = PlutoStaticHTML.Pluto.frontmatter(card.path)



end
