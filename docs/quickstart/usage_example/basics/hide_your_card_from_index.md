---
title: Hide your card from page index layout
description: This demo shows you how to hide your card in page layout.
---

There are cases that you want to hide one card in the generated page layout and only provide the
entrance via reflink. For example, you have multiple version of demos and you only want to set the
latest one as the default and provide legacy versions as reflink in the latest page.

This can be done by setting `hidden: false` in the frontmatter, for example:

```markdown
---
hidden: true
id: hidden_card
---
```

By doing this, this page is not shown in the generated index page, the only way to visit it is
through URLs. Usually, you can use Documenter's [reflink
feature](https://juliadocs.github.io/Documenter.jl/dev/man/syntax/#@ref-link) to provide a reflink
to the hidden page.

For example, `[hidden card](@ref hidden_card)` generates a reflink to the [hidden page](@ref
hidden_card), note that it doesn't get displayed in [quickstart index page](@ref quickstart).

!!! note
    If you don't pass a index template to `makedemos`, i.e., `makedemos(demodir)`, then it does not
    generate an index page for you. In this case, `hidden` keyword does not change anything, for
    obvious reasons.
