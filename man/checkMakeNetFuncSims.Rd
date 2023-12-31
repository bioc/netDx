% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/similarities.R
\name{checkMakeNetFuncSims}
\alias{checkMakeNetFuncSims}
\title{internal test function to check validity of makeNetFunc and sims}
\usage{
checkMakeNetFuncSims(makeNetFunc, sims, groupList)
}
\arguments{
\item{makeNetFunc}{(function) makeNetFunc from buildPredictor()}

\item{sims}{(list) sims from buildPredictor()}

\item{groupList}{(list) groupList from buildPredictor()s}
}
\value{
(list) cleaned values for makeNetFunc and Sims
}
\description{
internal test function to check validity of makeNetFunc and sims
}
\details{
User must provide either makeNetFunc or sims. This function
confirms this.
}
