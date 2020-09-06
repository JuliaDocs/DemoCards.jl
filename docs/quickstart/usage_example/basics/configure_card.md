---
title: Configure your card
cover: assets/logo.svg
id: configure_your_card
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
description: This demo show you how to pass additional meta info of card to DemoCards.jl

---
```

Of course, you have to make sure the `---` flag shows at the first line of the markdown file,
otherwise DemoCards would just read them as normal contents.

There are two valid `cover` options:

* a local file specified by relative path to the current file, or,
* an image file specified by http(s) URL (e.g, `https://johnnychen94.github.io/DemoCards.jl/dev/assets/logo.svg`)
