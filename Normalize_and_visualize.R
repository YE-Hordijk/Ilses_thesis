# R program to print Hello World
# aString = "Hello World!"
# print (aString)

# Run this script separately with "Rscript Normalize_and_visualize.R"

#!/usr/bin/env Rscript
print("R script is active...")


#_____________________________Installing Packages_______________________________
cat("Installing packages if needed...")

#Installs that need to be done before running the R script
if (!requireNamespace("BiocManager", quietly = TRUE))
	install.packages("BiocManager", dependencies=TRUE)

if (!(suppressMessages(suppressWarnings(require("DESeq2", quietly = TRUE)))))
	suppressMessages(BiocManager::install("DESeq2", quietly=TRUE, dependencies=TRUE))

if (!require("pheatmap", quietly = TRUE))
	BiocManager::install("pheatmap", dependencies=TRUE)
cat("COMPLETED!\n")


#_____________________________Loading Packages__________________________________
cat("Loading packages...")
library("ggplot2")
library("DESeq2")
library("pheatmap")
suppressMessages(library("crayon"))
#install.packages("here")
#library("here")
cat("COMPLETED!\n")

#sessionInfo()

#_____________________________Getting inputfiles________________________________
cat("Receiving inputfiles:\n")
args = commandArgs(trailingOnly=TRUE) #importing arguments given with the run command
cat(yellow("Genecounts inputfile:	", args[1], "\n"))
genecounts = args[1]
cat(yellow("Metadata inputfile:	", args[2], "\n"))
metafile = args[2]
cat(yellow("Experiment name:	", args[3], "\n"))
experiment_name = args[3]



path = paste("./",args[3],"/Files_for_R",sep="")
setwd(path)


cat("Reading inputfiles...")
countTable <- read.delim(genecounts, row.names = 1, check.names=FALSE) #dim(input) 
#meta = read.delim(file=paste("Metafiles", metafile, sep="/"), row.names = 1, check.names=FALSE) #dim(meta)
meta = read.delim(metafile, row.names = 1, check.names=FALSE) #dim(meta)
cat("COMPLETED!\n")

#print(countTable)

#print(meta)
#Extra checking that the data files are compatible
cat(blue("Checking if counttable and metadata matches: ", all(colnames(countTable) %in% rownames(meta)), "\n")) #colnames of countTable and rownames of  meta
cat(blue("Checking if counttable and metadata are in the same order: ", all(colnames(countTable) == rownames(meta)), "\n")) #items in colnames of countTable and rownames of meta are in the same order


#Making the DESeq2 opbject
suppressMessages(suppressWarnings(count.data.set <- DESeqDataSetFromMatrix(countData=countTable, colData=meta, design= ~ age)))
#print(count.data.set)
suppressMessages(count.data.set.object <- DESeq(count.data.set))

#____________Plotting extra information about DEseq2 objects____________________
#
#
#res <- results(count.data.set.object)
#print(res)

#
#print("Size of count.data.set: ")
#dim(count.data.set)
#keep <- rowSums(counts(count.data.set)) >= 10 # keeping all rows that have expression of at least 10 reads across all the samples
#count.data.set <- count.data.set[keep,]
#print("Size of count.data.set after filtering out genes with expression lower thatn 10 read across all the samples: ")
#dim(count.data.set)
#
#


#__________________________Making normalized file_______________________________
#Normalizing
vsd <- vst(count.data.set.object, nsub = 100, blind=TRUE) #Normalizing
norm.data = assay(vsd)


#Saving normalized table
setwd('..')
dir.create("./Files_from_R", showWarnings = FALSE, recursive = FALSE, mode = "0777")
newFileName = paste(substr(genecounts, 0,nchar(genecounts) - 16), "NORMALIZED.txt", sep="")
NEWFILENAME <- paste("Files_from_R/",newFileName, sep="")

write.table(norm.data, 
            sep="\t",
            file=NEWFILENAME, 
            row.names=TRUE,
            col.names=NA,            
            quote=FALSE)


#__________________________Clustering the data__________________________________
#sampleDists <- dist(t(norm.data),  method = "euclidean")
#clusters=hclust(sampleDists)
#plot(clusters)




#_______________________________________________________________________________
#The code below is stolen from https://groups.google.com/g/ggplot2/c/HajrW1yN9ZE
# david kahle
# sept 27, 2010

theme_nothing <- function (base_size = 12){
  structure(list(
    axis.line = theme_blank(), 
    axis.text.x = theme_blank(), axis.text.y = theme_blank(),
    axis.ticks = theme_blank(), 
    axis.title.x = theme_blank(), axis.title.y = theme_blank(), 
    axis.ticks.length = unit(0, "lines"), axis.ticks.margin = unit(0, "lines"), 
    legend.position = "none", 
    panel.background = theme_blank(), panel.border = theme_blank(), 
    panel.grid.major = theme_blank(), panel.grid.minor = theme_blank(), 
    panel.margin = unit(0, "lines"), 
    plot.background = theme_blank(), 
    plot.title = theme_text(size = base_size * 1.2), 
    plot.margin = unit(c(-1, -1, -1.5, -1.5), "lines")
  ), class = "options")
}


#__________________________Making the PCAplot___________________________________
dir.create("./PCAplots", showWarnings = FALSE, recursive = FALSE, mode = "0777")
PCAplotName = paste(substr(genecounts, 0,nchar(genecounts) - 16), "PCAplot.png", sep="") #Making a name for the PCAplot
w = plotPCA(vsd, intgroup=c("age")) # If you rmove the w = it will save the plot as a PDF as well
#w + theme(plot.margin = unit(c(-10, 0.1, -10, 0.1), "cm"))
ggsave(paste("PCAplots/", PCAplotName, sep=""))

#__________________________Get the PCs__________________________________________
pcs <- prcomp(t(norm.data)) 
df <- as.data.frame(pcs$x) #result is a table with all the PC values for every subject

#summary(pcs)
#PCAAnalysis$x
#newdat<-pcs$x[,1:2]
#newdat


newFileName = paste(substr(genecounts, 0,nchar(genecounts) - 16), "PCs.txt", sep="")
NEWFILENAME <- paste("Files_from_R/",newFileName, sep="")
write.table(df, 
            sep="\t",
            file=NEWFILENAME, 
            row.names=TRUE,
            col.names=NA,            
            quote=FALSE)




#________Better code for making the PCA plot but returns ERROR_______
#
#percentrl <- pcs$sdev^2/sum(pcs$sdev^2)
#plotData <- data.frame(meta, pcs$x[,1:2])
#p <- ggplot(plotData, aes(x = PC1, y = PC2, colour = age)) 
#p + geom_point(size = 3) +
#  scale_color_manual(values = c("salmon", "blue")) +
#  xlab(paste0("PC1:", round(percentrl[1] * 100), "% variance")) +
#  ylab(paste0("PC2:", round(percentrl[2] * 100), "% variance")) +
#  ggtitle("PCA") +
#  theme(plot.title = element_text(family = "Helvetica", color = "#666666", face = "bold", 
#                                  size = 16, hjust = 0.5)) +
#  geom_text(aes(label = meta$Samples, hjust = 0.5, vjust = 2, size = 1), cex = 2.5)



#__________________________Making the heatmap___________________________________
#head(row.names(countTable))


select <- order(rowMeans(counts(count.data.set.object,normalized=TRUE)), decreasing=TRUE)[1:20]
df <- as.data.frame(colData(count.data.set.object)[,c("age")])

#colnames(mat) <- str_sub(colnames(count.data.set.object))
rownames(df) <- colnames(count.data.set.object)
colnames(df) <- "Agegroups"


#making an array
cdsd = assay(count.data.set.object)
ntd <- normTransform(count.data.set.object, f=log2, pc=1)
banaan = assay(ntd)
rownames(banaan) <- row.names(countTable)


#getwd()
cat("Creating and saving heatmap...")
dir.create("./Heatmaps", showWarnings = FALSE, recursive = FALSE, mode = "0777")
newFileName = paste(substr(genecounts, 0,nchar(genecounts) - 16), "Heatmap.png", sep="")
w = HEATMAP = pheatmap(banaan,
                   cluster_rows=TRUE, 
                   show_rownames=FALSE, #TRUE, 
                   show_colnames=FALSE,
                   show_row_dend = FALSE,
                   cluster_cols=TRUE, 
                   annotation_col=df,
                   clustering_method = "complete",
                   clustering_distance_cols = "euclidean",
                   file = paste("Heatmaps/", newFileName, sep=""),
                   #fontsize_row = 1.4,
                   #cutree_rows = 20
                   #hight = 5000,
                   #width = 10
)
#for getting cluseters
#cl = cutree(w$tree_row,20)
#ann = data.frame(cl)
##rownames(ann) = rownames(banaan)
#ann


#IF YOU WANT A WIDER PLOT, USE THE CODE UNDERNEATH (https://stackoverflow.com/questions/65332430/pull-out-genes-observations-from-cutree-rows-groups-in-pheatmap)
#png(file="bananenXX.png", res=300, width=100, height=100)
#HEATMAP
#invisible(dev.off())
cat("COMPLETED\n")


cat("\nEnd of the R script. Normalized readcounts and plots have been saved.\n")
quit()




