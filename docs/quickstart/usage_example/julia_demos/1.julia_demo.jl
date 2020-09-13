#! /usr/bin/julia

# comments are allowed before YAML frontmatter

# ---
# title: Write your demo in julia
# cover: assets/literate.png
# date: 2020-09-13
# author: Johnny Chen
# julia: 1.0.1
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
# # date: 2020-09-13
# # author: Johnny Chen
# # julia: 1.3
# # description: <description>
# # ---
# ```

# Julia format demos accept one extra frontmatter config: `julia`. It allows you to specify the
# compat version of your demo. `DemoCards` would 1) throw a warning if your demos are generated
# using a lower version of Julia 2) insert a compat version badge. The warning is something like
# "The running Julia version `1.0.5` is older than the declared compatible version `1.3.0`."

# You should be careful about the leading whitespaces after the first #. Frontmatter as weird as the
# following is not guaranteed to work and it is very likely to hit a YAML parsing error.

# ```
# # ---
# # title: <title>
# #  cover: <cover>
# #  id: <id>
# # description: <description>
# # ---
# ```

# !!! tip
#     Comments are allowed before frontmatter, but it would only be appeared in the julia source
#     codes. Normally, you may only want to add magic comments and license information before the
#     YAML frontmatter.
