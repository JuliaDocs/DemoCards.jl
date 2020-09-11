#---
#hidden: true
#id: hidden_card
#---

# # This is a hidden card

# This card doesn't get displayed in [quickstart index page](@ref quickstart) page and can only be
# viewed with relink `[hidden card](@ref hidden_card)`.

# Note that hidden cards are still processed by DemoCards to get you necessary assets.

using ImageCore, ImageTransformations, TestImages

imresize(testimage("camera"); ratio=0.25)
