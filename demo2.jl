# ---
# id: demo2
# description: plot sinc(0--2pi) picture
# cover: assets/sinc.png
# ---

# 代码和头信息之间必须要有空格，而且头信息前面不能有代码和注释，否则头信息不生效。

using Plots
p = plot(sinc,0,2π)

#-
savefig(p,"assets/sinc.png")
