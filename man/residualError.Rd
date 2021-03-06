% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scaling.R
\name{residualError}
\alias{residualError}
\title{Calculate the residual error}
\usage{
residualError(values, errors, mirror = FALSE, wtX = 0)
}
\arguments{
\item{values}{vector of underlying datapoints}

\item{errors}{the error associated with each datapoint}
}
\value{
the residual error vector
}
\description{
Models expected error relative to data point magnitudes and then uses the model
to calculate the residual error, i.e. how much greater or lesser the error is
compared to expectation.
}
