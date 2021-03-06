% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/simulate.R
\name{simulateAssay}
\alias{simulateAssay}
\title{Simulate selection assay}
\usage{
simulateAssay(params, plasmidPools, trueFit, n, sd = 0.01, t = 3)
}
\arguments{
\item{params}{the parameter sheet}

\item{trueFit}{the output of simulateFitness()}

\item{n}{The size of the pre-selection pool (number of cells)}

\item{sd}{the standard deviation of the noise affecting the growth assay.}

\item{t}{the selection time in generations}

\item{pool}{the output of simulatePool()}
}
\value{
a list of vectors containing the clone frequencies in the pre- and post-selection pool
}
\description{
This simulates the effects of a growth-based fitness assay. It samples a pool of cells
of the desired size and applies fitness effects with a pre-determined amount of noise. 
It then outputs the clone frequencies in the pre- and post-selection pool
}
