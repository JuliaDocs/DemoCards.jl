module DemoCards

using Mustache
using ImageCore
using FileIO
using JSON

include("compat.jl")
include("demotypes.jl")
include("utils.jl")
include("load_config.jl")
include("show.jl")
include("generate.jl")

export DemoCard, DemoSection, DemoPage,
       generate


"""

This package breaks the rendering of the whole demo page into three types:

* `DemoPage` contains serveral `DemoSection`s;
* `DemoSection` contains either serveral `DemoSection`s or serveral `DemoCard`s;
* `DemoCard` consists of cover image, title and other necessary information.
"""
DemoCards

end # module
