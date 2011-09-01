library(cranvas)

### (1) flea: color by categorical variable, and linking
data(flea, package = 'tourr')
qflea <- qdata(flea, color = species)  # use species to create colors

qscatter(tars1, aede1)
qscatter(tars1, tars2, asp = 1)  # aspect ratio

## link qflea to itself using species
id = link_cat(qflea, 'species')


## remove linking
remove_listener(qflea, id)


## a bubble chart
qflea2 = qdata(flea, color = NA, border = species, size = tars1)
qscatter(tars1, tars2)



### (2) NRC rankings
data(nrcstat)

qnrc = qdata(nrcstat, color = Regional.Code)

qscatter(R.Rankings.5th.Percentile, R.Rankings.95th.Percentile)

qscatter(S.Rankings.5th.Percentile, S.Rankings.95th.Percentile)



\dontrun{
### (3) secrets in the pollen data
library(animation)
data(pollen, package = 'animation')
head(pollen)
qpollen = qdata(pollen, color = rgb(0, 0, 0, .2), size = 2)
qscatter(RIDGE, CRACK, data = qpollen)
## try zooming into the center



### (4) pressure test; run with care!
n = 5e+05  # half a million still works (at least for me)
df = qdata(data.frame(x = rnorm(n), y = rnorm(n),
    z = gl(4, n/4)), color = z)
qscatter(x, y)
}