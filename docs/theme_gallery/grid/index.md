# [Theme: Grid](@id theme-grid)

Given demos organized as following, you can make them displayed in grid-like manner

```text
grid
├── assets
│   └── logo.svg
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
grid_templates, grid_theme = cardtheme("grid")
grid_demopage, grid_cb = makedemos("theme_gallery/grid", grid_templates)
```



{{{democards}}}
