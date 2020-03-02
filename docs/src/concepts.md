# [Concepts](@id concepts)

This page is a brief introduction on the core types provided by `DemoCards.jl`.
Knowing them helps you configure your demo pages. For detailed description, please
refer to the [Package References](@ref package_references).

## [DemoPage](@id concepts_page)

[`DemoPage`](@ref DemoCards.DemoPage) is the root type in `DemoCards.jl`, everything
else is contained in it directly or indirectly.

You can configure your `DemoPage` by maintaining a `config.json` file, supported
configuration keys are:

* `order`: specify the section orders. By default, it's case-insensitive alphabetic order.
* `title`: specify the title of this demo page.
* `template`: template filename.

A valid template is a markdown file that contains one and only one `{{{democards}}}`. For example,

```markdown
# Examples

This page contains a set of examples for you to start with.

{{{democards}}}

Contributions are welcomed at [DemoCards.jl](https://github.com/johnnychen94/DemoCards.jl) :D
```

Here's an example of `config.json` for `DemoPage`:

```json
{
    "template": "index.md",
    "order": [
        "basic",
        "advanced"
    ]
}
```

!!! note

    Key `template` has higher priority over other keys.

    For example, if you provide both `template` and `title` in your `config.json`
    and the template file happens to have a title, `title` in `config.json` will
    be suppressed.

## [DemoSection](@id concepts_section)

[`DemoSection`](@ref DemoCards.DemoSection) defines the structure of your demo page.
It has the following fields:

* `cards`: holds a list of demo cards.
* `subsections`: holds a list of demo subsections.

!!! warning

    A `DemoSection` can't directly holds both cards and subsections; either of them
    should be empty vector.

Similar to `DemoPage`, you can configure your `DemoSection` by maintaining a `config.json`
file, supported configuration keys are:

* `order`: specify the cards order or subsections order. By default, it's case-insensitive alphabetic order.
* `title`: specify the title of this demo section.

The following is an example of `config.json`:

```json
{
    "title": "learn by examples",
    "order": [
        "quickstart.md",
        "array.md"
    ]
}
```

## [DemoCard](@id concepts_card)

In simple words, a demo card consists of a cover image, a description, and
a link to its content -- just like a card.

### [`MarkdownDemoCard`](@id concepts_mdcard)

[`MarkdownDemoCard`](@ref DemoCards.MarkdownDemoCard) is a demo card whose contents
are written in the markdown format.

The markdown files are almost directly passed to `Documenter.jl`, check the
[syntax of Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/man/syntax/)
if you are unfamiliar with the Julia flavor markdown syntax.

You can configure your markdown demos by adding a [YAML format front matter](https://jekyllrb.com/docs/front-matter/).

* `cover`: path to the cover image. By default, it will use the first available image link.
* `description`: a multi-line description to this file, will be displayed when the demo card is hovered. By default it uses `title`.
* `id`: specify the `id` tag for cross-references.
* `title`: one-line description to this file, will be displayed under the cover image.

An example of the front matter:

```markdown
---
title: Configure your demo with front matter
cover: cover.png
id: non_ambiguious_id
description: this demo shows how you can pass extra demo information to DemoCards package.
---

You don't need to add a title in the body. DemoCards.jl fills it for you.
```

### [`JuliaDemoCard`](@id concepts_juliacard)

[`JuliaDemoCard`](@ref DemoCards.JuliaDemoCard) is a demo card whose contents
are written as julia source file.

Conversion from `.jl` to `.md` and `.ipynb` are powered by [`Literate.jl`](https://github.com/fredrikekre/Literate.jl),
please refer to [Literate Syntax](https://fredrikekre.github.io/Literate.jl/stable/fileformat/) if you're not familar.

An additional YAML format is added to existing Literate format, for example:

```julia
# ---
# title: Configure your demo with front matter
# cover: cover.png
# id: non_ambiguious_id
# description: this demo shows how you can pass extra demo information to DemoCards package.
# ---

# You don't need to add a title in the body. DemoCards.jl fills it for you.
```

## Remarks

Currently, there're two special names used in `DemoCards.jl`:

* `assets` is a preserved name for `DemoCards.jl` to escape preprocessing
* `config.json` is used to tell `DemoCards.jl` more informations of current folder.

To free you from managing/re-organizing demo structure, some decisions are made here:

* maintain a `config.json` in each folder
* always use relative path
* all information is supplementary and hence optional

!!! note

    If you've specified orders in `config.json`, then for every new demos, you need to add
    its filename to `order`. `DemoCards.jl` isn't smart enough to guess what you really want.
