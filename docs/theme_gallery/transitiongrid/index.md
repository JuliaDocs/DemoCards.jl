# Theme: Transition Grid

Given demos organized as following, you can make them displayed in grid-like manner. This is like
the [`"grid"` theme](@ref theme-grid) but uses a transition effect on the card covers.

```text
transitiongrid
├── assets
│   └── logo.svg
├── config.json
├── transitiongrid_section_1
│   ├── transitiongrid_subsection_1
│   │   ├── transitiongrid_card_1.md
│   │   └── transitiongrid_card_2.md
│   └── transitiongrid_subsection_2
│       ├── transitiongrid_card_3.md
│       └── transitiongrid_card_4.md
└── index.md
```

```julia
transitiongrid_demopage, transitiongrid_cb, transitiongrid_assets = makedemos("theme_gallery/transitiongrid", transitiongrid_templates)
```

The page configuration file `transitiongrid/config.json` should contain an entry `theme = "transitiongrid"`, e.g.,

```json
{
    "theme": "transitiongrid"
}
```


{{{democards}}}
