% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dataList2list.R
\name{dataList2List}
\alias{dataList2List}
\title{Convert MultiAssayExperiment object to list and data.frame}
\usage{
dataList2List(dat, groupList)
}
\arguments{
\item{dat}{(MultiAssayExperiment) Patient data and metadata}

\item{groupList}{(list) variable groupings used for feature construction. See groupList arg in buildPredictor().}
}
\value{
(list) Keys are:
1) assays: list of matrices, each corresponding to data from a particular
layer
2) pheno: (data.frame) sample metadata
}
\description{
Convert MultiAssayExperiment object to list and data.frame
}
\details{
Used by internal routines in netDx
}
\examples{
data(xpr,pheno)
require(MultiAssayExperiment)
objlist <- list("RNA"=SummarizedExperiment(xpr))
mae <- MultiAssayExperiment(objlist,pheno)
groupList <- list(RNA=rownames(xpr))
dl <- dataList2List(mae,groupList)
summary(dl) 
}
