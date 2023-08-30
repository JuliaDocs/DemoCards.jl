# Theme: No-cover List

A basic DemoCards theme for list-like without cover images layout.

Given demos organized as following, you can make them displayed as a list of charts

```text
nocoverlist
├── assets
│   └── logo.svg
├── config.json
├── nocoverlist_section_1
│   ├── nocoverlist_subsection_1
│   │   ├── nocoverlist_card_1.md
│   │   └── nocoverlist_card_2.md
│   └── nocoverlist_subsection_2
│       ├── nocoverlist_card_3.md
│       └── nocoverlist_card_4.md
└── index.md
```

```julia
nocoverlist_demopage, nocoverlist_cb, nocoverlist_assets = makedemos("theme_gallery/grid", nocoverlist_templates)
```

The page configuration file `nocoverlist/config.json` should contain an entry `theme = "nocoverlist"`, e.g.,

```json
{
    "theme": "nocoverlist"
}
```



{{{democards}}}
