module DemoCards

import Base: basename
using Mustache
using Literate
using ImageCore, ImageTransformations
using FileIO, JSON, YAML
using Suppressor # suppress log generated by 3rd party tools, e.g., Literate

const config_filename = "config.json"
const template_filename = "index.md"
# directly copy these folders without processing
const ignored_dirnames = ["assets"]

include("compat.jl")

include("types/card.jl")
include("types/section.jl")
include("types/page.jl")

include("utils.jl")
include("show.jl")
include("generate.jl")
include("cardthemes.jl")

export makedemos, cardtheme


"""

This package breaks the rendering of the whole demo page into three types:

* `DemoPage` contains serveral `DemoSection`s;
* `DemoSection` contains either serveral `DemoSection`s or serveral `DemoCard`s;
* `DemoCard` consists of cover image, title and other necessary information.
"""
DemoCards

end # module
