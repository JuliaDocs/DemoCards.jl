# Theme: List

Given demos organized as following, you can make them displayed as a list of charts

```text
list
├── assets
│   └── logo.svg
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
list_templates, list_theme = cardtheme("list")
list_demopage, list_cb = makedemos("theme_gallery/list", list_templates)
```



{{{democards}}}
