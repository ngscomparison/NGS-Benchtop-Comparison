#!/usr/bin/Rscript
# author: Nick Loman
# taken from: https://github.com/nickloman/benchtop-sequencing-comparison/tree/master/scripts

#usage: <input from read_bam.py> <output file>

library(xtable)
args<-commandArgs(TRUE)


do_it <-function(args){
  indels<-read.table(args[1], sep="\t", header=TRUE,skip=1)
  mapped<-indels[indels$mapped == 1,]
  tab <- cbind( 
	  "subst" = tapply(mapped$subst, mapped$sample, sum),
	  "insertions" = tapply(mapped$insertions, mapped$sample, sum),
	  "deletions" = tapply(mapped$deletions, mapped$sample, sum),
	  "bases" = tapply(mapped$rlen, mapped$sample, sum),
	  "reads" = tapply(mapped$rid, mapped$sample, length )  )
  fram<-as.data.frame(tab)
  summary<-cbind(fram,
	    "indels_per_100" = (fram$insertions + fram$deletions) / fram$bases * 100, 
	    "indels_per_read" = (fram$insertions + fram$deletions) / fram$reads,
	    "subst_per_100" = (fram$subst) / fram$bases * 100,
	    "subst_per_read"= (fram$subst) / fram$reads
	    )
  print(xtable(summary[,c(1,2,3,5,6,7,8,9)]), file = args[2])
  write.csv((summary[,c(1,2,3,5,6,7,8,9)]), file = args[3], quote=T)

}
args[2]=paste(args[1],".res",sep="")
args[3]=paste(args[1],".csv",sep="")
do_it(args)


