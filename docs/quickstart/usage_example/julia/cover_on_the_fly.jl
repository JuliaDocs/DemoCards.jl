# ---
# title: Generate your cover on the fly
# cover: assets/lena_color_256.png
# description: this demo shows you how to generate cover on the fly
# ---

# There're many reasons that you don't want to mannually manage the cover image.
# DemoCards.jl allows you to generate the card cover on the fly for demos written
# in julia.

# Let's do this with a simple example

using TestImages, FileIO
## ImageIO backend such as ImageMagick is required
cover = testimage("lena_color_256")
save("assets/lena_color_256.png", cover)

# You can use this image later with `cover`, `# ![](assets/lena_color_256.png)`
# , or you can directly write it in your frontmatter

cover