% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/similarities.R
\name{checkSimValid}
\alias{checkSimValid}
\title{checks if provided similarity functions are valid. Returns error if not}
\usage{
checkSimValid(sims)
}
\arguments{
\item{sims}{(list) keys are layer names, values are functions or characters (names of built-in similarity functions)}
}
\value{
TRUE if all pass check. Else throws error.
}
\description{
checks if provided similarity functions are valid. Returns error if not
}
