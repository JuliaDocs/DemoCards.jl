# [Concepts](@id concepts)

This page is a brief introduction on the internal core types provided by `DemoCards.jl`. Generally,
you don't need to use them directly, but knowing them helps you to better organize and configure
your demo pages. For detailed description, please refer to the [Package References](@ref
package_references).

## [DemoPage](@id concepts_page)

[`DemoPage`](@ref DemoCards.DemoPage) is the root type in `DemoCards.jl`, everything
else is contained in it directly or indirectly.

You can configure your `DemoPage` by maintaining a `config.json` file, supported
configuration keys are:

* `"order"`: specify the section orders. By default, it's case-insensitive alphabetic order.
* `"title"`: specify the title of this demo page.
* `"theme"`: specify the index theme to use.
* `"template"`: filename to template that will be used to generate the index page. This option
  doesn't work if `"theme"` is unconfigured or is `"nothing"`, in which case no index page will be
  generated.

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
    "theme": "grid",
    "order": [
        "basic",
        "advanced"
    ]
}
```

!!! note
    Key `template` has higher priority over other keys. For example, if you provide both
    `template` and `title` in your `config.json` and the template file happens to have a title,
    `title` in `config.json` will be suppressed.

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

* `"order"`: specify the cards order or subsections order. By default, it's case-insensitive alphabetic order.
* `"title"`: specify the title of this demo section.
* `"description"`: words that would rendered under the section title.

The following is an example of `config.json`:

```json
{
    "title": "learn by examples",
    "description": "some one-line description can be useful.",
    "order": [
        "quickstart.md",
        "array.md"
    ]
}
```

!!! note
    🚧 Unlike `DemoPage`, a `DemoSection` does not yet support `"theme"` and `"template"` keys. A
    drawback of this design is that you have to put template contents into the `"description"` key,
    even if it contains hundreds of words.

## [DemoCard](@id concepts_card)

In simple words, a demo card consists of a link to its content and other relavent informations. In
`"grid"` theme, it looks just like a card.

Depending on how your demos are written, there are two types of demo cards:

* [`MarkdownDemoCard`](@ref configure_your_card) for markdown files, and
* [`JuliaDemoCard`](@ref juliademocard_example) for julia files.

`JuliaDemoCard`s are julia files that are specially handled by DemoCards to generate associated
assets, for example, markdown files (.md) and jupyter notebooks (.ipynb).

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
