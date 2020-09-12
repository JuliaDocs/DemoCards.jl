---
title: Configure your card
cover: assets/logo.svg
id: configure_your_card
author: Johnny Chen
date: 2020-09-13
description: This demo show you how to pass additional meta info of card to DemoCards.jl
---

Besides the meta info extracted from your demo contents, `DemoCards.jl` also
reads the YAML format frontmatter, for example, this demo uses the following
frontmatter:

```markdown
---
title: Configure your card
cover: assets/democards.png
id: configure_your_card
author: Johnny Chen
date: 2020-09-13
description: This demo show you how to pass additional meta info of card to DemoCards.jl

---
```

!!! tip
    All these YAML configs are optional. If specified, it has higher priority over the meta info
    extracted from the demo contents. For example, if you don't like the inferred demo title, then
    specify one explicitly in the YAML frontmatter.

    Of course, you have to make sure the `---` flag shows at the first line of the markdown file,
    otherwise DemoCards would just read them as normal contents.

The rules are simple:

* `author` and `date` badges will only be added if you configure them.
* If there are multiple authors, they could be splitted by semicolon `;`. For example, `author:
  Jane Doe; John Roe` would generate two author badges.
* there are two valid `cover` options:
  * a local file specified by relative path to the current file, or,
  * an image file specified by http(s) URL.
