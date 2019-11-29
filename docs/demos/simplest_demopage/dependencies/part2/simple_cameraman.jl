# ---
# cover: assets/cameraman.png
# ---

using TestImages, FileIO

img = testimage("cameraman")
save("assets/cameraman.png", img)
img
