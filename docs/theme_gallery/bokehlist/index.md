# Theme: BokehList

BokehList is a list theme used in [Bokeh.jl](https://cjdoris.github.io/Bokeh.jl/dev/gallery/).

Given demos organized as following, you can make them displayed as a list of charts

```text
bokehlist
├── assets
│   └── logo.svg
├── config.json
├── bokehlist_section_1
│   ├── bokehlist_subsection_1
│   │   ├── bokehlist_card_1.md
│   │   └── bokehlist_card_2.md
│   └── bokehlist_subsection_2
│       ├── bokehlist_card_3.md
│       └── bokehlist_card_4.md
└── index.md
```

```julia
bokehlist_demopage, bokehlist_cb, bokehlist_assets = makedemos("theme_gallery/bokehlist", bokehlist_templates)
```

The page configuration file `bokehlist/config.json` should contain an entry `theme = "bokehlist"`, e.g.,

```json
{
    "theme": "bokehlist"
}
```



{{{democards}}}
