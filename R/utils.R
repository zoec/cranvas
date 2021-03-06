#' Extend the range of data by an amount
#'
#' This is useful for setting a margin in the plot region.
#'
#' @param x the data vector (either the orginal vector or its range) or an n by
#'   2 matrix which is used to define the ranges of two axes in two columns
#' @param f the amount to extend the range (usually a scalar; when it is a
#'   vector, its length must be 2 (giving the amount to extend to the left and
#'   right respectively) or 4 (extending x-axis and y-axis respectively)
#' @return a vector or a matrix of ranges corresponding to the input \code{x}
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
#' @examples extend_ranges(c(0, 1))
#' extend_ranges(1:10)
#'
#' m = matrix(c(c(1,5,10), c(5,7,8)), ncol = 2)
#' extend_ranges(m)
#' extend_ranges(m, f = c(.1, .2))  # larger top and right margins
#' extend_ranges(m, f = c(.2, .2, .1, .1))  # larger horiz margins, small vertical margins
extend_ranges = function(x, f = qpar("mar")) {
  if (!is.null(d <- dim(x))) {
    if (length(d) != 2L) stop("x must be of 2 dimensions")
    if (d[2] != 2L) stop("x must be of 2 columns")
    f = rep(f, length = 4)
    return(cbind(extend_ranges(x[, 1], f = f[1:2]), extend_ranges(x[, 2], f = f[3:4])))
  }
  if (length(x) != 2) x = range(x, na.rm = TRUE, finite = TRUE)
  x + c(-1, 1) * f * (x[2] - x[1])
}

#' Re-order the columns of a data frame based on MDS or ANOVA
#'
#' For the MDS method, we use (1 - correlation matrix) as the distance matrix
#' and re-order the columns according their distances between each other (i.e.
#' 1-dimension representation of p-dimension); as a result, columns in a
#' neighborhood indicate they are more similar to each other. For the ANOVA
#' method, if there is a column named \code{.color}, it will be used as the x
#' variable and we perform ANOVA on each numeric column vs this variable, then
#' the columns are re-ordered by the P-values, so the colors can discriminate
#' the first few columns most apart. Of course, when there is only a single
#' color in the \code{.color} variable, the ANOVA method will not work and the
#' original order will be returned. For the randomForest method, the variables
#' will be ordered by the importance scores (mean descrease in accuracy) and the
#' argument \code{x} will be used as the response variable.
#' @param data a data frame (or similar data structures like mutaframes)
#' @param type the method to re-order the variables (columns)
#' @param vars the column names of the \code{data}
#' @param numcol a logical vector indicating which columns are numeric
#' @param x the x variable to be used in ANOVA and randomForest
#' @return the column names (i.e. the argument \code{vars}) after being
#'   re-ordered; note non-numeric variables will always be put in the end and
#'   they will not go into the computation
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
#' @examples
#' reorder_var(tennis, type = 'MDS')
#'
#' reorder_var(iris, type = 'ANOVA', x = iris$Species)
#' names(iris)  # original column names
#' reorder_var(iris, type = 'randomForest', x = iris$Species)
#'
reorder_var = function(data, type = c('none', 'MDS', 'ANOVA', 'randomForest'),
                       vars = names(data), numcol = sapply(data, is.numeric),
                       x = data$.color) {
  type = match.arg(type)
  if (any(numcol)) {
    num_data = data[, numcol, drop = FALSE]
    switch(type, none = NULL, MDS = {
      idx = order(cmdscale(1 - cor(num_data), k = 1))
    }, ANOVA = {
      if (!is.null(x) && length(unique(x)) > 1) {
        xfactor = factor(x)
        idx = order(apply(num_data, 2, function(y) {
          summary(aov(y ~ xfactor))[[1]][1, 5]
        }))
      } else {
        idx = 1:ncol(num_data)
      }
    }, randomForest = {
      if (!is.null(x) && length(unique(x)) > 1 && require('randomForest')) {
        xfactor = factor(x)
        imp = randomForest(num_data, xfactor, importance = TRUE)$importance
        idx = order(-imp[, ncol(imp) - 1])
      } else {
        idx = 1:ncol(num_data)
      }
    })
    if (type != 'none') {
      return(c(vars[numcol][idx], vars[!numcol]))
    }
  }
  vars
}

#' Insert line breaks into character strings
#'
#' By default, all the non-alphanumeric characters are replaced by \code{'\n'},
#' which can be useful when plotting long axis labels, e.g., in parallel
#' coordinates plots.
#'
#' @param x a character vector
#' @param split the rule (regular expression) to replace characters by line
#'   breaks
#' @param ... other arguments passed to \code{\link[base]{gsub}}
#' @return a character vector with certain characters replaced by \code{'\n'}
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
#' @examples
#' break_str(c('long label1.1', 'long label1.2', 'long label1.3'), split = ' ')
#' break_str(names(iris))
#'
break_str = function(x, split = '[^[:alnum:]]', ...) {
  gsub(split, '\n', x, ...)
}

#' Switch the values of two variables
#'
#' The values of two variables \code{a} and \code{b} are switched in an
#' environment \code{envir}.
#'
#' This function can make it a little bit easier when a plot can be drawn
#' vertically and horizontally, in which case we only need to switch some
#' attributes in the x-axis and y-axis, and the code for actual drawing is not
#' affected. The bar plot is such an example.
#' @param a the name of the first variable (character)
#' @param b the name of the second variable (character)
#' @param envir the environment of the variables \code{a} and \code{b}
#' @return \code{NULL}
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
#' @seealso \code{\link[base]{get}}, \code{\link[base]{assign}}
#' @examples x1 = 4:9; x2 = letters
#' switch_value('x1', 'x2')
#' x1; x2
switch_value = function(a, b, envir = .GlobalEnv) {
  tmp = get(a, envir = envir)
  assign(a, get(b, envir = envir), envir = envir)
  assign(b, tmp, envir = envir)
  invisible(NULL)
}

#' Simple data imputation
#'
#' Impute data by some simple methods.
#' @param x the numeric data matrix
#' @param method imputation method; one of the following: \describe{
#'   \item{below.min}{replace missing values by a value 20\% below the mininum}
#'   }
#' @return the imputed data
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
na_impute = function(x, method = "below.min") {
  apply(x, 2, function(xx) {
    if (any(is.na(xx))) {
      xx[is.na(xx)] = switch(method, below.min = min(xx, na.rm = TRUE) - 0.2 *
        diff(range(xx, na.rm = TRUE)))
    }
    xx
  })
}

.QtCursor = structure(
  c(0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L, 11L, 12L, 13L, 14L, 17L, 18L,
    15L, 16L, 20L, 19L, 21L, 24L),
  .Names = c("ArrowCursor", "UpArrowCursor", "CrossCursor", "WaitCursor",
             "IBeamCursor", "SizeVerCursor", "SizeHorCursor", "SizeBDiagCursor",
             "SizeFDiagCursor", "SizeAllCursor", "BlankCursor", "SplitVCursor",
             "SplitHCursor", "PointingHandCursor", "ForbiddenCursor",
             "OpenHandCursor", "ClosedHandCursor", "WhatsThisCursor", "BusyCursor",
             "DragMoveCursor", "DragCopyCursor", "DragLinkCursor", "BitmapCursor")
)

#' Set the cursor of a view
#'
#' Change the shape of cursor on a view.
#'
#' All possible cursor types with the corresponding integer code are:
#'
#' 0: ArrowCursor; 1: UpArrowCursor; 2: CrossCursor; 3: WaitCursor; 4:
#' IBeamCursor; 5: SizeVerCursor; 6: SizeHorCursor; 7: SizeBDiagCursor; 8:
#' SizeFDiagCursor; 9: SizeAllCursor; 10: BlankCursor; 11: SplitVCursor; 12:
#' SplitHCursor; 13: PointingHandCursor; 14: ForbiddenCursor; 17:
#' OpenHandCursor; 18: ClosedHandCursor; 15: WhatsThisCursor; 16: BusyCursor;
#' 20: DragMoveCursor; 19: DragCopyCursor; 21: DragLinkCursor; 24: BitmapCursor
#'
#' We can pass either the integer code or the character string to the
#' \code{cursor} argument.
#' @param view the view for which to change the cursor (created by
#'   \code{\link[qtpaint]{qplotView}})
#' @param cursor an integer or a character string (see Details)
#' @return \code{NULL}; the cursor of the view is set as a side effect
#' @author Yihui Xie <\url{http://yihui.name}>
#' @references \url{http://doc.qt.nokia.com/latest/qt.html#CursorShape-enum}
#' @export
#' @examples
#' library(cranvas)
#' library(qtpaint)
#' scene = qscene()
#' qlayer(scene)
#' v = qplotView(scene = scene)
#' print(v)
#'
#' set_cursor(v, 'WaitCursor')
#'
#' set_cursor(v, 2L)  # CrossCursor
#'
set_cursor = function(view, cursor = 'ArrowCursor') {
  cu = view$cursor
  if (is.character(cursor)) cursor = .QtCursor[cursor]
  cu$setShape(cursor)
  view$cursor = cu
}

## remove (nearly) constant columns
.rm.cons.col = function(data) {
  const.col = sapply(data, function(x) {
    x = na.omit(x)
    x = as.numeric(x)
    length(x) == 0 || diff(range(x)) < 1e-6
  })
  if (any(const.col)) {
    data = data[, !const.col, drop = FALSE]
    warning("removed constant column(s) ",
            paste(names(data)[const.col], collapse = ","))
  }
  data
}

#' Create a rectangle to be used in identifying
#'
#' To identify cases under the mouse, we need a small rectangle to look for
#' cases in this rectangle. This function creates such a rectangle using
#' \code{meta$pos} (mouse position) and \code{meta$limits} (layer limits).
#'
#' Currently the size of the rectangle is 1\% of the layer limits.
#' @param meta the meta data containing at least \code{meta$pos} and
#'   \code{meta$limits}
#' @return A Qt rectangle object (see \code{\link[qtbase]{qrect}})
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
#' @examples ## see source code of, e.g., qparallel()
identify_rect = function(meta) {
  r = apply(meta$limits, 2, diff) / 200
  p = meta$pos
  qrect(rbind(p - r, p + r))
}

#' Generate lighter colors
#'
#' This function first converts colors to the RGB and HSV space, then modifies
#' the brightness (the \code{V} component in HSV) by an amount.
#' @param color the color vector
#' @param factor numeric: larger than 0 means to make the color lighter, and
#'   less than 0 means darker (can be either a vector or a scalar)
#' @return The modified color vector.
#' @author Heike Hofmann and Yihui Xie
#' @export
#' @example inst/examples/lighter-ex.R
lighter = function(color, factor = 0.2) {
  ## converts color to hsv, multiplies v by factor, returns colors as hexcode
  x = rgb2hsv(col2rgb(color))
  v = pmax(pmin(x[3, ] + factor, 1), 0)
  hsv(h = x[1, ], s = x[2, ], v = v)
}

#' Preferred height and width of layers with texts
#'
#' The height and width of a layer which draws texts often involves with the
#' number of line breaks (\code{'\n'}) in the texts. These two functions give
#' the preferred height and width of a layer as a rule of thumb.
#'
#' Usually the height and width of the title layer and x- and y-axis layers need
#' to be adjusted dynamically.
#' @param text the character vector to be drawn in the layer
#' @return The height or width (numeric).
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
#' @rdname prefer_dimension
#' @examples prefer_height('a label'); prefer_height('this is\na label')
#' prefer_width('abc'); prefer_width('a long long label')
#' prefer_width('line\nbreaks')  # 'breaks' dominates the width because it is wider
#' prefer_width('multiple\nvertical\nlines', horizontal = FALSE)
prefer_height = function(text) {
  text[is.na(text)] = 'NA'
  if (all(!nzchar(text))) return(10)  # 10 pixels if text is empty
  30 * max(sapply(gregexpr('\n', text),
                  function(xx) ifelse(any(xx < 0), 0, length(xx)) + 1))
}
#' @param horizontal logical: the text is drawn horizontally
#' (\code{TRUE}) or vertically (\code{FALSE})
#' @rdname prefer_dimension
#' @export
prefer_width = function(text, horizontal = TRUE) {
  text[is.na(text)] = 'NA'
  if (horizontal) {
    9 * max(nchar(unlist(strsplit(text, '\n')))) + 10
  } else {
    15 * max(sapply(gregexpr('\n', text),
                    function(xx) ifelse(any(xx < 0), 0, length(xx)) + 1))
  }
}

#' Get the relative width and height of one pixel on the screen
#'
#' This function calculates the relative size of one pixel in a layer coordinate
#' system, since it has different relative dimensions in different coordinate
#' systems.
#' @param painter the painter of a layer
#' @return A numeric vector of length 2 (width and height).
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
#' @examples library(qtpaint); s = qscene()
#' qlayer(s, paintFun = function(layer, painter){d = one_pixel(painter)
#' qdrawSegment(painter, .1, seq(0,1,.1), .1 + d[1], seq(0,1,.1))  # one pixel segments
#' qdrawRect(painter, .3, .4, .3 + d[1], .4 + d[2]) # one pixel rectangle
#' }, limits = qrect(c(0, 1), c(0, 1)))
#' qplotView(scene = s)
one_pixel = function(painter) {
  m = qvmap(qdeviceTransform(painter)$inverted(), c(0, 1), c(0, 1))
  abs(c(m[2, 1] - m[1, 1], m[2, 2] - m[1, 2]))
}

#' Get variable names
#'
#' It is often flexible to input variables in plotting functions, and this
#' generic function convert most common inputs (character, numeric or formula)
#' to a character vector of variable names.
#'
#' Numeric indices are converted to character names according to the positions
#' of variables in the data; \code{\link[base]{all.vars}} is used to extract all
#' variable names in a formula, and the special formula \code{~ .} is treated
#' differently: it means all variables in the data except thoese names starting
#' with a dot (e.g. \code{.color}).
#' @param vars a character vector of variable names, or a numeric vector of
#'   column indices, or a two-sided formula like \code{~ x1 + x2 + x3}
#' @param data the data containing the variables
#' @return A character vector
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
#' @examples var_names(~., mtcars); var_names(~disp+hp, mtcars); var_names(1:3, mtcars)
var_names = function(vars, data) {
  UseMethod('var_names')
}
#' @method var_names default
#' @rdname var_names
#' @export
var_names.default = function(vars, data) {
  stop("'vars' must be a character or numeric vector or a formula")
}
#' @method var_names character
#' @rdname var_names
#' @export
var_names.character = function(vars, data) {
  vars
}
#' @method var_names numeric
#' @rdname var_names
#' @export
var_names.numeric = function(vars, data) {
  names(data)[vars]
}
#' @method var_names formula
#' @rdname var_names
#' @export
var_names.formula = function(vars, data) {
  v = all.vars(vars)
  if (identical(v, '.')) v = grep('^[^.]', names(data), value = TRUE)
  v
}

#' Set the dimensions of child layers to fixed values
#'
#' This function makes use of the grid layout of a root layer to set the size of
#' its child layers.
#' @param root the root layer
#' @param row a list containing the row id's and the corresponding height values
#' @param column a list containing column id's and width values
#' @return The dimensions of child layers are set to given values, and their
#'   stretch factors are set to 0.
#' @author Yihui Xie <\url{http://yihui.name}>
#' @export
#' @examples ## see ?qaxis
fix_dimension = function(root, row = list(id = NULL, value = NULL),
                         column = list(id = NULL, value = NULL)) {
    layout = root$gridLayout()
    for (i in seq_along(row$id)) {
      layout$setRowPreferredHeight(row$id[i], row$value[i])
      layout$setRowStretchFactor(row$id[i], 0)
    }
    for (j in seq_along(column$id)) {
      layout$setColumnPreferredWidth(column$id[j], column$value[j])
      layout$setColumnStretchFactor(column$id[j], 0)
    }
  }


#' Get a Qt glyph (point shapes)
#'
#' This function create a Qt glyph based on shape and size.
#' @param shape an integer to be mapped to different shapes (1: circle; 2:
#'   square; 3: triangle)
#' @param size the size of the glyph
#' @return A Qt glyph
#' @author Yihui Xie <\url{http://yihui.name}>
#' @noRd
#' @examples ## TODO
get_glyph = function(shape, size = 4) {
  switch(shape, qglyphCircle(size), qglyphSquare(size), qglyphTriangle(size))
}

#' Save the plot to a file
#'
#' This function saves a plot view to a image file like PNG or JPEG, etc.
#' @param obj the view object or CranvasPlot object(usually returned by a plotting function)
#' @param filename the file name (must have an explicit extension; see the
#'   references for supported image formats)
#' @param width the desired width (pixels)
#' @param height the desired height
#' @return \code{TRUE} if the plot is successfully saved; otherwise \code{FALSE}
#' @author Yihui Xie <\url{http://yihui.name}>, Tengfei Yin
#' @references Supported image formats:
#'   \url{http://doc.qt.nokia.com/latest/qimagewriter.html#supportedImageFormats}
#' @export
#' @docType methods
#' @rdname qsave-methods
#' @aliases qsave,Qanviz::PlotView-method
#' @aliases qsave,CranvsPlot-method
#' @examples library(cranvas); qtennis = qdata(tennis)
#' v = qbar(matches, data = qtennis); qsave(v, 'tennis_bar.png', 480, 320); qsave(v$view, 'tennis_bar.png', 480, 320)
setGeneric("qsave", function(obj, ...) standardGeneric("qsave"))

setMethod("qsave", "Qanviz::PlotView", function(obj, filename = 'Rplot.png', width = 480, height = 480){
  view = obj
  filename = file.path(normalizePath(dirname(filename)), basename(filename))
  size = as.numeric(view$size)  # original size
  view$resize(width, height)
  view$scene()$setBackgroundBrush(Qt$QBrush(Qt$QColor(255, 255, 255)))
  qimg = Qt$QImage(view$sceneRect$size()$toSize(), Qt$QImage$Format_ARGB32_Premultiplied)
  pt = Qt$QPainter(qimg)
  view$scene()$render(pt)
  view$resize(size[1], size[2])  # restore size
  qimg$save(filename)
})

setMethod("qsave", "CranvasPlot", function(obj, filename = 'Rplot.png', width = 480, height = 480){
  view = obj$view
  filename = file.path(normalizePath(dirname(filename)), basename(filename))
  size = as.numeric(view$size)  # original size
  view$resize(width, height)
  view$scene()$setBackgroundBrush(Qt$QBrush(Qt$QColor(255, 255, 255)))
  qimg = Qt$QImage(view$sceneRect$size()$toSize(), Qt$QImage$Format_ARGB32_Premultiplied)
  pt = Qt$QPainter(qimg)
  view$scene()$render(pt)
  view$resize(size[1], size[2])  # restore size
  qimg$save(filename)
})

## qsave = function(filename = 'Rplot.png', view, width = 480, height = 480) {
##   filename = file.path(normalizePath(dirname(filename)), basename(filename))
##   size = as.numeric(view$size)  # original size
##   view$resize(width, height)
##   view$scene()$setBackgroundBrush(Qt$QBrush(Qt$QColor(255, 255, 255)))
##   qimg = Qt$QImage(view$sceneRect$size()$toSize(), Qt$QImage$Format_ARGB32_Premultiplied)
##   pt = Qt$QPainter(qimg)
##   view$scene()$render(pt)
##   view$resize(size[1], size[2])  # restore size
##   qimg$save(filename)
## }

near_constant = function(x) diff(range(x, na.rm = TRUE, finite = TRUE)) < 1e-7

# data limits x and y; plot limits X and Y; return a matrix to draw segments to
# denote boundaries
bound_seg = function(meta = list()) {
  x = meta$xlim; y = meta$ylim; X = meta$limits[, 1]; Y = meta$limits[, 2]
  if (length(x) * length(y) * length(X) * length(Y) == 0L) return()
  rbind(if (x[1] < X[1]) c(X[1], Y[1], X[1], Y[2]),
        if (x[2] > X[2]) c(X[2], Y[1], X[2], Y[2]),
        if (y[1] < Y[1]) c(X[1], Y[1], X[2], Y[1]),
        if (y[2] > Y[2]) c(X[1], Y[2], X[2], Y[2]))
}

# default colors for NA's
na_colors = function(x, color = 'gray') {
  x[is.na(x)] = color
  x
}
