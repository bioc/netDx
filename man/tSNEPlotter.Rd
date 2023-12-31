% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helper.R
\name{tSNEPlotter}
\alias{tSNEPlotter}
\title{Plot tSNE}
\usage{
tSNEPlotter(psn, pheno, ...)
}
\arguments{
\item{psn}{(matrix) Patient similarity network represented as adjacency
matrix (symmetric). Row and column names are patient IDs. Note that NA
values will be replaced by very small number (effectively zero).}

\item{pheno}{(data.frame) Patient labels. ID column is patient ID and 
STATUS is patient label of interest. tSNE will colour-code nodes by 
patient label.}

\item{...}{Parameters for Rtsne() function.}
}
\value{
(Rtsne) output of Rtsne call. Side effect of tSNE plot
}
\description{
Plot tSNE
}
\details{
Plots tSNE of integrated patient similarity network using Rtsne
}
\examples{
pid <- paste("P",1:100,sep="")
psn <- matrix(rnorm(100*100),nrow=100,dimnames=list(pid,pid))
psn[lower.tri(psn)] <- NA; diag(psn) <- NA
psn2 <- reshape2::melt(psn); psn2 <- psn2[-which(is.na(psn2[,3])),]
colnames(psn2) <- c("SOURCE","TARGET","WEIGHT")
pheno <- data.frame(ID=pid,STATUS=c(rep("control",50),rep("case",50)))
tSNEPlotter(psn2,pheno)
}
