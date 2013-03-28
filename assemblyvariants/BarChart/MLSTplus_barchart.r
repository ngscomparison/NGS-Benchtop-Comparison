library(lattice)
library(grid)
mlst <-read.table(file="MLSTplus.csv", sep="\t", header=TRUE)
names <- mlst$Sample
mlst_clean <- mlst[-2]          
mlst_frame <- cbind(stack(mlst_clean), names)
cols <- c("green", "yellow", "red");

mlst_frame$names <- factor(mlst_frame$names, levels=c("GSJ", "", "MiSeq 150bp", "MiSeq 250bp", " ", "PGM 100bp", "PGM 200bp", "PGM 300bp", "PGM 400bp"))

chart <-barchart(
    values~names, data=mlst_frame, stack=TRUE,
    group=sort(factor(ind)),
    layout = c(1,1),
    as.table=FALSE,
    index.cond=list(c(1,1)),
    par.settings=list(superpose.polygon = list(col=cols), axis.line = list(col = "black") ),
    aspect="fill",
    ylab=list(label="Sakai genes", cex=0.8), 
    xlab=list(label="GSJ                              MiSeq                           PGM", cex=0.8),
    main="",
    box.width=0.5, box.ratio=0.5, lwd=0.1, cex.axis=0.8,
    ylim=c(1,5000), drop.unused.levels=FALSE,
    scales=list(
	tick.number=10, alternating=1, axs="i", cex=0.8,
	x=list(at=c(1,2,4,6,7,8,9), labels=c("400bp", "2x150bp", "2x250bp", "100bp", "200bp", "300bp", "400bp")),
	y=list(at=c(pretty(0:4000, 10),4671), labels=c(pretty(0:4000, 10),4671))), 
    panel=function(x, y,...) {
        panel.abline(h=4671, lwd=1, lty=2)
	panel.barchart(x, y,...) 
    },
)  

svg("mlst.svg", width=5,height=3.5)
print(chart)
dev.off()

