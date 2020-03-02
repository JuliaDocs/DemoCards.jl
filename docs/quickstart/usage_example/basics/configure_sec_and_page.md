---
title: Configure your section and page
cover: assets/logo.svg
---

This demo shows you how to manipulate your demo sections.

By default, a demo section takes the folder name as its section title, and it
takes the file orders as its card orders, which can be unsatisfying in many cases.
Luckily, `DemoCards.jl` reads the `config.json` file in the section folder, for example:

```json
{
    "title": "Basic Usage",
    "order": [
        "simple_markdown_demo.md",
        "configure_with_yaml.md"
    ]
}
```


A demo page is maintained in a similar manner, except that it has a key for
template page. For example:

```json
{
    "template": "template.md",
    "order": [
        "basic",
        "advanced"
    ]
}
```
