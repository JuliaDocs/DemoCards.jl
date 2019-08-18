# Demos

By default, all sections, subsections and demo cards are sorted and rendered in an case-insensitive alphabetic order. This make
it extremely easy to start writing demo contents.

However, there're many cases this is not good enough.This page shows how you can partially specify the order of sections and demo cards.

Here's the folder structure of this page:

```text
ordered_demos
├── advanced
│   ├── demo_5.md
│   └── demo_6.md
├── basic
│   ├── part1
│   │   ├── demo_1.md
│   │   └── demo_2.md
│   └── part2
│       ├── config.json
│       ├── demo_3.md
│       └── demo_4.md
└── config.json
```

There're two `config.json` files here: `ordered_demos/config.json` and `ordered_demos/basic/part2/config.json`.

* The first config file specifies the section orders of *this* page - the `basic` section is put ahead of `advanced` section.
* The second config file specifies the card orders in `basic.part2` subsection - card `demo_4.md` is put ahead of card `demo_5.md`.

```text
# ordered_demos/config.json
{
    "template": "ordered_demos.md",
    "order": [
        "basic",
        "advanced"
    ]
}

# ordered_demos/basic/part2/config.json
{
    "order": [
        "demo_4.md",
        "demo_3.md"
    ]
}
```

Now you can see the ordered results:

---

{{{sections}}}

---
