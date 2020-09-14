# ---
# title: Generate your cover on the fly
# cover: assets/lena_color_256.png
# description: this demo shows you how to generate cover on the fly
# julia: 1.0.0
# ---

# There're many reasons that you don't want to mannually manage the cover image.
# DemoCards.jl allows you to generate the card cover on the fly for demos written
# in julia.

# Let's do this with a simple example

using TestImages, FileIO, ImageShow
## ImageIO backend such as ImageMagick is required
cover = testimage("lena_color_256")
save("assets/lena_color_256.png", cover)

# You can use this image later with `cover`, `# ![](assets/lena_color_256.png)`
# , or you can directly write it in your frontmatter

cover

# ## Advanced Literate & Documenter tricks
#
# The following tricks are what you'd probably need to work on a real-world demo.
#
# ### Hide asset generation
#
# There are cases that you want to hide the codes related to asset generation, e.g., the
# `save(...)` line. Fortunately, this is doable by combining the syntax of Documenter and Literate.
# For example, the following code can be inserted to whereever you need to generate the assets.
# The [`#src` flag](https://fredrikekre.github.io/Literate.jl/v2/fileformat/#Filtering-Lines) is used as a filter to tell Literate that this line is reserved only in the
# original source codes.
#
# ```julia #md
# save("assets/cover.png", img_noise) #src #md
# ``` #md
#
# Gif image is also supported via `ImageMagick`:
#
# ```julia #md
# # --- save covers --- #src #md
# using ImageMagick #src #md
# imgs = map(10:5:50) do k #src #md
#     colorview(RGB, rank_approx.(svdfactors, k)...) #src #md
# end #src #md
# ImageMagick.save("assets/color_separations_svd.gif", cat(imgs...; dims=3); fps=2) #src #md
# ``` #md
#
# ### Hide the output result
# 
# It does not look good to show the `0` result in the above code block as it does not provide
# anything that the reader cares.There are two ways to fix this.
#
# The first way is to insert a [`#hide`
# flag](https://juliadocs.github.io/Documenter.jl/stable/man/syntax/#@example-block) to the line you
# don't want the user see. For example, if you write your source file in this way
#
# ```julia #md
# cover = testimage("lena_color_256") #md
# save("assets/lena_color_256.png", cover) #hide #md
# ``` #md
#
# it will show up in the generated HTML page as

cover = testimage("lena_color_256")
save("assets/lena_color_256.png", cover) #hide

# The return value is still `0`. Sometimes it is wanted, sometime it is not. To also hide the return
# value `0`, you could insert a trivial `nothing #hide #md` to work it around.
#
# ```julia #md
# cover = testimage("lena_color_256") #md
# save("assets/lena_color_256.png", cover) #hide #md
# nothing #hide #md
# ``` #md
#
# generates

cover = testimage("lena_color_256")
save("assets/lena_color_256.png", cover)
nothing #hide #md

# No output at all. You could, of course, insert `cover #hide #md` to show the image result:
#
#
# ```julia #md
# cover = testimage("lena_color_256") #md
# save("assets/lena_color_256.png", cover) #hide #md
# cover #hide #md
# ``` #md
#
# generates

cover = testimage("lena_color_256")
save("assets/lena_color_256.png", cover) #hide
cover #hide #md

# The `#md` flag is used to keep a clean `.jl` file provided by the download-julia badge:
# ![](https://img.shields.io/badge/download-julia-brightgreen.svg)
