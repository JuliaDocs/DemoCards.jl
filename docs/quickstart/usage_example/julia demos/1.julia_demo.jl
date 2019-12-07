# ---
# title: write your demo in julia
# cover: assets/literate.png
# description: This demo shows you how to write your demo in julia
# ---

# Different from markdown format demo, source demo files are preprocessed so that it generates:
#
# 1. assets such as cover image
# 2. julia source file
# 3. mardkown file
# 4. jupyter notebook file
#
# Links to nbviewer and source files are provided as well.
#
# The conversions from source demo files to other files are mainly handled by Literate.
# The syntax to control/filter the outputs can be found [here](https://fredrikekre.github.io/Literate.jl/stable/fileformat/)

x = 1//3
y = 2//5
x + y

#-

# Images can be loaded and displayed
using TestImages, ImageShow
img = testimage("lena")

# The frontmatter is also written in YAML with only a leading `#`, for example:

# ```
# # ---
# # title: <title>
# # cover: <cover>
# # id: <id>
# # description: <description>
# # ---
# ```
