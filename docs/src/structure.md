# [Structure manipulation](@id manipulation)

It is not uncommon that you'd need to manipulate the folder structure of your demos. For example,
when you are creating new demos, or when you need to reorder the demos and sections. The core design
of `DemoCards.jl` is to make such operation as trivial as possible; the less you modify `make.jl`,
the safer you'll be.

I'll explain it case by case, hopefully you'd get how things work out with `DemoCards.jl`.

Throughout this page, I'll use the following folder structure as an example:

```text
examples
├── part1
│   ├── assets
│   ├── config.json
│   ├── demo_1.md
│   ├── demo_2.md
│   └── demo_3.md
└── part2
    ├── demo_4.jl
    └── demo_5.jl
```

## To add/remove/rename a demo file

Suppose we need to add one `demo_6.jl` in section `"part2"`, just add the file in `examples/part2`
folder. Everything just works without the need to touch `make.jl`.

Adding `demo_6.jl` in section `"part1"` would be a little bit different, because there's a config
file for this section: `examples/part1/config.json`. If `"order"` is not defined in the config file,
it would be the same story. If `"order"` is defined in the config file, then you'll do one more step
to specify the exact order you want `demo_5.jl` be placed at.

Removing/renaming the demo file is similar that, if needed, you'll need to remove/rename the demo
from `"order"` in the config file.

You have to do so because `DemoCards` is not smart enough to guess a partial order for you.
Otherwise `DemoCards` would throw an error on it, for example, this is the error message if I change
`demo_1.md` to `demo1.md`.

```text
┌ Warning: The following entries in examples/part1/config.json are not used anymore:
│ demo_1.md
└ @ DemoCards ~/Documents/Julia/DemoCards/src/utils.jl:29
┌ Warning: The following entries in examples/part1/config.json are missing:
│ demo1.md
└ @ DemoCards ~/Documents/Julia/DemoCards/src/utils.jl:32
ERROR: LoadError: ArgumentError: incorrect order in examples/part1/config.json, please check the previous warning message.
```

The error message says you have to modify the "orders" item in `examples/part1/config.json` accordingly.

## To rename a section

Suppose we want to rename `"Part1"` to something more meaningful, say `"Markdown demos"`. There are
two ways to do so:

* rename `"examples/part1"` to `"examples/markdown demos"`
* add `"title" = "Markdown demos"` item in `examples/part1/config.json`.

## To move section around

If everything `demo_1.md`, `demo_2.md`, `demo_3.md` needed are placed in `examples/part1/assets`,
then it would be just a piece of cake to move the entire `examples/part1` folder around. Say, move
`examples/part1` to `examples/part1/markdown`.

To minimize the changes you need to do when you organize your demos, here's some general advice:

* Keep an `assets` folder for each of your section.
* Try to avoid specifying path in other folders.

This is just some advice and you don't have to follow it. After all, we don't really change the
folder structure that often.

## To change the page theme

Change the `"theme"` item in `examples/config.json` and that's all.
