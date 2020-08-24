# ---
# id: demo2
# description: plot sinc(0--2pi) picture
# cover: assets/sinc.png
# ---

# 作图

using Plots
p = plot(sinc,0,2π)

#-
savefig(p,"assets/sinc.png")
