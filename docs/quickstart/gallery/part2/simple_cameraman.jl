# ---
# title: generate cover on the fly
# ---
using TestImages, FileIO

img = testimage("cameraman")
save("assets/cameraman.png", img) # hide

# ![cover](assets/cameraman.png)