module DemoCards

import Base: basename
using Mustache
using Literate
using ImageCore
using FileIO
using JSON
using YAML

const config_filename = "config.json"
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
