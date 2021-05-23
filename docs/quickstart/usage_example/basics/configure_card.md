---
title: Configure your card
cover: assets/logo.svg
id: configure_your_card
author: "[Johnny Chen](https://github.com/johnnychen94); Jane Doe"
date: 2020-09-13
description: This demo show you how to pass additional meta info of card to DemoCards.jl
---

This page is generated from a markdown file. In `DemoCards.jl`'s type system, it is called
[`MarkdownDemoCard`](@ref DemoCards.MarkdownDemoCard) whose contents are written in the markdown
format. 

The markdown files are almost directly passed to `Documenter.jl`, check the
[syntax of Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/man/syntax/)
if you are unfamiliar with the Julia flavor markdown syntax.

DemoCards extracts potential information from the file to build the index page, e.g., name, title,
reference id, cover image file/URL. If that's not available, then you would need to configure them
by adding a [YAML format front matter](https://jekyllrb.com/docs/front-matter/).

Supported YAML keywords are list as follows:

* `cover`: an URL or a relative path to the cover image. If not configured, it would use the DemoCard logo.
* `description`: a multi-line description to this file, will be displayed when the demo card is hovered.
* `id`: specify the `id` tag for cross-references.
* `title`: one-line description to this file, will be displayed under the cover image.
* `author`: author name. If there are multiple authors, split them with semicolon `;`.
* `date`: any string contents that can be passed to `Dates.DateTime`.
* `hidden`: whether this card is shown in the layout of index page.

!!! tip
    All these YAML configs are optional. If specified, it has higher priority over the meta info
    extracted from the demo contents. For example, if you don't like the inferred demo title, then
    specify one explicitly in the YAML frontmatter.

Of course, you have to make sure the `---` flag shows at the first line of the markdown file,
otherwise DemoCards would just read them as normal contents.

For example, the markdown file of this page uses the following frontmatter:

```markdown
---
title: Configure your card
cover: assets/logo.svg
id: configure_your_card
author: "[Johnny Chen](https://github.com/johnnychen94); Jane Doe"
date: 2020-09-13
description: This demo show you how to pass additional meta info of card to DemoCards.jl
---
```

As you can see, if configured, there will be badges for `author` and `date` info. If there are
multiple authors, they could be splitted by semicolon `;`. For example, `author: Jane Doe; John Roe`
would generate two author badges.

!!! tip
    If `author` is configured as markdown url format, then the generated badge will be clickable.

!!! warning
    A badly formatted YAML frontmatter will currently trigger a build failure with perhaps hard to
    understand error. Sometimes, you need to assist YAML parser by explicitly quoting the content
    with `""`. See the author field above as an instance.
