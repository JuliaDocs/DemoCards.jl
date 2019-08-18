# Configure your demo page

Most demos contains a `config.json` file that specify the relative path to the template, for example:

```text
demo_with_template/
├── advanced
│   ├── demo_3.md
│   └── demo_4.md
├── basic
│   ├── demo_1.md
│   └── demo_2.md
└── config.json
```

```text
# demo_with_template/config.json
{
    "template": "simple_template.md"
}
```

In this way, you can still write the content of your demo page without caring about how the demos are rendered.

---

{{{sections}}}

---
