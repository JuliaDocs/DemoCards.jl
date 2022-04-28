# DemoCards

**NOTE**: the purpose of this fork of DemoCards is to generate cover images during HTML generation, thereby needing only a **single pass**. It has only been tested in very narrow scenarios, so **use with caution.**

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![][action-img]][action-url] [![][pkgeval-img]][pkgeval-url] [![][codecov-img]][codecov-url] |

This package is used to *dynamically* generate a demo page and integrate with [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).

_Let's focus on writing demos_

## Overview

* a plugin package to `Documenter.jl` to manage all your demos.
* folder structure is the demo structure.
* minimal configuration.
* CI friendly
* support demos in markdown and julia format.

![democards workflow](docs/quickstart/assets/democards_workflow.png)

The philosophy of DemoCards is "folder structure is the structure of demos"; organizing folders and files in
the a structural way, then `DemoCards.jl` will help manage how you navigate through the pages.

```text
examples
├── part1
│   ├── assets
│   ├── demo_1.md
│   ├── demo_2.md
│   └── demo_3.md
└── part2
    ├── demo_4.jl
    └── demo_5.jl
```

DemoCards would understand it in the following way:

```text
# Examples
  ## Part1
    demo_1.md
    demo_2.md
    demo_3.md
  ## Part2
    demo_4.jl
    demo_5.jl
```

Read the [Quick Start](https://johnnychen94.github.io/DemoCards.jl/stable/democards/quickstart/index.html) for more instructions.

## Examples

* [AlgebraOfGraphics.jl](http://juliaplots.org/AlgebraOfGraphics.jl/dev/gallery/)
* [Augmentor.jl](https://evizero.github.io/Augmentor.jl/dev/operations/)
* [FractionalDiffEq.jl](https://scifracx.org/FractionalDiffEq.jl/dev/ChaosGallery/)
* [LeetCode.jl](https://cn.julialang.org/LeetCode.jl/dev/)
* [Images.jl](https://juliaimages.org/latest/examples/)
* [ReinforcementLearning.jl](https://juliareinforcementlearning.org/docs/experiments/)
* [Plots.jl](https://docs.juliaplots.org/dev/user_gallery/)

## Caveat Emptor

The use of this package heavily relies on [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl),
[Literate.jl](https://github.com/fredrikekre/Literate.jl), [Mustache.jl](https://github.com/jverzani/Mustache.jl)
and others. Unfortunately, I'm not a contributor of any. This package also uses a lot of Regex, which I know little.

The initial purpose of this package is to set up the [demo page](https://juliaimages.org/latest/examples) of JuliaImages.
I'm not sure how broadly this package suits the need of others, but I'd like to accept any issues/PRs on improving the usage experience.


[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://johnnychen94.github.io/DemoCards.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://johnnychen94.github.io/DemoCards.jl/stable

[action-img]: https://github.com/johnnychen94/DemoCards.jl/workflows/Unit%20test/badge.svg
[action-url]: https://github.com/johnnychen94/DemoCards.jl/actions

[codecov-img]: https://codecov.io/gh/johnnychen94/DemoCards.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/johnnychen94/DemoCards.jl

[pkgeval-img]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/D/DemoCards.svg
[pkgeval-url]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html
