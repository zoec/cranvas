\name{visible}
\alias{visible}
\alias{visible<-}
\title{Set or query the visibility of observations}
\usage{
visible(data)

visible(data) <- value
}
\arguments{
  \item{data}{the mutaframe}

  \item{value}{a logical vector of the length
  \code{nrow(data)}}
}
\value{
  The function \code{\link{visible}} returns the logical
  vector to control the visibility of observations
}
\description{
  There is a column \code{.visible} to control the
  visibility of observations. This can be useful for
  ``deleting'' certain observations from the plot (set
  their visibility to \code{FALSE}).
}
\examples{
df <- qdata(iris)

visible(df)

visible(df) <- rep(c(TRUE, FALSE), c(100, 50))  # hide the last 50 obs

visible(df)
}
\author{
  Yihui Xie <\url{http://yihui.name}>
}
\seealso{
  \code{\link{qdata}}
}
