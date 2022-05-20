# Theme: List

A basic DemoCards theme for list-like layout.

Given demos organized as following, you can make them displayed as a list of charts

```text
list
├── assets
│   └── logo.svg
├── config.json
├── list_section_1
│   ├── list_subsection_1
│   │   ├── list_card_1.md
│   │   └── list_card_2.md
│   └── list_subsection_2
│       ├── list_card_3.md
│       └── list_card_4.md
└── index.md
```

```julia
list_demopage, list_cb, list_assets = makedemos("theme_gallery/grid", list_templates)
```

The page configuration file `list/config.json` should contain an entry `theme = "list"`, e.g.,

```json
{
    "theme": "list"
}
```



{{{democards}}}
