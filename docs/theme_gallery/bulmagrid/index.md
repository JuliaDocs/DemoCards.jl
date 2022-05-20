# Theme: Bulma Grid

Given demos organized as following, you can make them displayed in grid-like manner. This is like
the [`"grid"` theme](@ref theme-grid) but uses the [Bulma](https://bulma.io/) CSS framework and is
shipped with [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).

```text
bulmagrid
├── assets
│   └── logo.svg
├── config.json
├── bulmagrid_section_1
│   ├── bulmagrid_subsection_1
│   │   ├── bulmagrid_card_1.md
│   │   └── bulmagrid_card_2.md
│   └── bulmagrid_subsection_2
│       ├── bulmagrid_card_3.md
│       └── bulmagrid_card_4.md
└── index.md
```

```julia
bulmagrid_demopage, bulmagrid_cb, bulmagrid_assets = makedemos("theme_gallery/bulmagrid", bulmagrid_templates)
```

The page configuration file `bulmagrid/config.json` should contain an entry `theme = "bulmagrid"`, e.g.,

```json
{
    "theme": "bulmagrid"
}
```


{{{democards}}}
