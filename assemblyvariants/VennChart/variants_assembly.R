library(grid)
library("VennDiagram")

# like the Consensus_differences.R, but takes not read the gerneic mot files but a plain list (eiher subst or indel) 
# of manually extracted variance position (one line per technology with one column per line only lisitng the variance names-positions as one entry (seperated by ",")

data=read.table("SeqSphereSNPs.csv", header=T,sep='\t')
PGM_snp=data[1,2]
PGM_snp=unlist(strsplit(gsub("\\s","", as.character(PGM_snp)), split=","))
MiSeq_snp=data[2,2]
MiSeq_snp=unlist(strsplit(gsub("\\s","", as.character(MiSeq_snp)), split=","))
GSJ_snp=data[3,2]
GSJ_snp=unlist(strsplit(gsub("\\s","", as.character(GSJ_snp)), split=","))


venn.diagram(
    x = list(
        PGM=PGM_snp,
        MiSeq=MiSeq_snp,
        GSJ=GSJ_snp
        ),
    filename = "SeqShpereVaraints_snp.tiff",
    col = "transparent",
    fill = c("red", "blue", "green"),
    alpha = 0.5,
    cex = 2.5,
    fontfamily = "serif",
    fontface = "bold",
    cat.default.pos = "text",
    cat.col = c("black", "black", "black"),
    cat.cex = 2.5,
    cat.fontfamily = "serif",
    cat.dist = c(0.06, 0.06, 0.06),
    cat.pos = 0
    );

data=read.table("SeqSphereIndels.csv", header=T,sep='\t')
PGM_ind=data[1,2]
PGM_ind=unlist(strsplit(gsub("\\s","", as.character(PGM_ind)), split=","))
MiSeq_ind=data[2,2]
MiSeq_ind=unlist(strsplit(gsub("\\s","", as.character(MiSeq_ind)), split=","))
GSJ_ind=data[3,2]
GSJ_ind=unlist(strsplit(gsub("\\s","", as.character(GSJ_ind)), split=","))

venn.diagram(
    x = list(
        PGM=PGM_ind,
        MiSeq=MiSeq_ind,
        GSJ=GSJ_ind
        ),
    filename = "SeqSphereVariants_indel.tiff",
    col = "transparent",
    fill = c("green", "red", "blue"),
    alpha = 0.5,
    cex = 2.5,
    fontfamily = "serif",
    fontface = "bold",
    cat.default.pos = "text",
    cat.col = c("black", "black", "black"),
    cat.cex = 2.5,
    cat.fontfamily = "serif",
    cat.dist = c(0.09, 0.09, 0.09),
    cat.pos = 0
    );
