module DemoCards

using Mustache

include("compat.jl")
include("type.jl")
include("show.jl")
include("generate.jl")

export DemoCard, DemoSection, DemoPage,
       generate

end # module
