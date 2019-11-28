# DemoCards

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] [![][codecov-img]][codecov-url] |

This package is used to *dynamically* generate a demo page and integrate with [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).

_Let's focus on writing demos_

## Overview

* a plugin package to `Documenter.jl`.
* magically generate an index page for all demos.
* minimal configuration.
* all demos can be tested by CI.
* support demos in markdown and julia format.

Organize your folders in the following way, and let `DemoCards.jl` manage the demo page for you.

```text
docs/demos/simplest_demopage
└── examples
    ├── part1
    │   ├── assets
    │   ├── demo_1.md
    │   ├── demo_2.md
    │   └── demo_3.md
    └── part2
        ├── assets
        ├── demo_4.jl
        └── demo_5.jl
```

Read the [Quick Start](https://johnnychen94.github.io/DemoCards.jl/dev/quickstart/) for more instructions.


[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://johnnychen94.github.io/DemoCards.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://johnnychen94.github.io/DemoCards.jl/stable

[travis-img]: https://travis-ci.org/johnnychen94/DemoCards.jl.svg?branch=master
[travis-url]: https://travis-ci.org/johnnychen94/DemoCards.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/github/johnnychen94/DemoCards.jl?svg=true
[appveyor-url]: https://ci.appveyor.com/project/johnnychen94/DemoCards-jl

[codecov-img]: https://codecov.io/gh/johnnychen94/DemoCards.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/johnnychen94/DemoCards.jl
