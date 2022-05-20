# [Theme: Grid](@id theme-grid)

A basic DemoCards theme for grid-like layout.

Given demos organized as following, you can make them displayed in grid-like manner

```text
grid
├── assets
│   └── logo.svg
├── config.json
├── grid_section_1
│   ├── grid_subsection_1
│   │   ├── grid_card_1.md
│   │   └── grid_card_2.md
│   └── grid_subsection_2
│       ├── grid_card_3.md
│       └── grid_card_4.md
└── index.md
```

```julia
grid_demopage, grid_cb, grid_assets = makedemos("theme_gallery/grid", grid_templates)
```

The page configuration file `grid/config.json` should contain an entry `theme = "grid"`, e.g.,

```json
{
    "theme": "grid"
}
```


{{{democards}}}
