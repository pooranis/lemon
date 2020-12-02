# Axis annotations


#' @include ggplot2.r
#' @include lemon-plot.r
NULL



  
# annotated_y_axis   ## adds a label
# annotated_y_axis_custom   ## adds a random grob

#' Annotations in the axis
#' 
#' @section: Showing values:
#' See \link[grDevices]{plotmath} for using mathematical expressions.
#' The function uses a simple replacement strategy where the literal strings
#' \code{.(y)} and \code{.(val)} are replaced by the value after round of to
#' a number of digits, as given by argument \code{digits}.
#' 
#' @rdname annotate_axis
#' @param label Text to print
#' @param y,x Position of the annotation.
#' @param side left or right, or top or bottom side to print annotation
#' @param parsed Logical (default \code{FALSE}), 
#'   when \code{TRUE}, uses mathplot for outputting expressions. 
#'   See section "Showing values".
#' @param print_label,print_value,print_both
#'   Logical; what to show on annotation. Label and/or value.
#'   \code{print_both} is shortcut for setting both \code{print_label} and
#'   \code{print_value}. When both is TRUE, uses argument \code{sep} to 
#'   separate the label and value.
#' @param ... Style settings for label and tick: 
#'   colour, hjust, vjust, size, fontface, family, rot. 
#'   When \code{waiver()} (default),
#'   the relevant theme element is used.
#' @example inst/examples/axis-annotation-ex.r
#' @export 
annotate_y_axis <- function(label, y, 
                             side = waiver(), 
                             print_label = TRUE,
                             print_value = TRUE,
                             print_both = TRUE,
                             parsed = FALSE,
                             ...) {
  
  if (!missing(print_both)) {
    print_label <- print_both
    print_value <- print_both
  }
  
  aa <- ggplot2::ggproto(NULL, 
    `_inherit`=if (parsed) AxisAnnotationBquote else AxisAnnotationText,
    aesthetic = 'y',
    side = side,
    params = list(
      label = label,
      y = y,
      value = y,
      print_label = print_label,
      print_value = print_value,      
      ...
    )
  )
  
  
  prependClass(aa, 'axis_annotation')
}
#' @rdname annotate_axis
#' @export
# @inheritParams annotate_y_axis
#' @param label Text to print
#' @param y,x Position of the annotation.
#' @param side left or right, or top or bottom side to print annotation
#' @param parsed Logical (default \code{FALSE}), 
#'   when \code{TRUE}, uses mathplot for outputting expressions. 
#'   See section "Showing values".
#' @param print_label,print_value,print_both
#'   Logical; what to show on annotation. Label and/or value.
#'   \code{print_both} is shortcut for setting both \code{print_label} and
#'   \code{print_value}. When both is TRUE, uses argument \code{sep} to 
#'   separate the label and value.
#' @param ... Style settings for label and tick: 
#'   colour, hjust, vjust, size, fontface, family, rot. 
#'   When \code{waiver()} (default),
#'   the relevant theme element is used.

annotate_x_axis <- function(label, x, 
                             side = waiver(), 
                             print_label = TRUE,
                             print_value = TRUE,
                             print_both = TRUE,
                             parsed = FALSE,
                             ...) {
  
  if (!missing(print_both)) {
    print_label <- print_both
    print_value <- print_both
  }
  
  
  aa <- ggplot2::ggproto(NULL, 
     `_inherit`=if (parsed) AxisAnnotationBquote else AxisAnnotationText,
     aesthetic = 'x',
     side = side,
     params = list(
       label = label,
       x = x,
       value = x,
       print_label = print_label,
       print_value = print_value,      
       ...
     )
  )
  
  prependClass(aa, 'axis_annotation')
}


# Axis_annotation base class ------
# Modelled after Scales in ggplot2/R/scale

#' @import grid
#' @import ggplot2
# Property 'reducible' is set to TRUE for inherited classes for which their
# labels can easily be reduced to vectors. Bquote objects, not so much?
AxisAnnotation <- ggplot2::ggproto('AxisAnnotation', NULL,
  side = waiver(),
  aesthetic = NULL,
  reducible=FALSE,
  params = list(
    value = NA,
    label = NA,
    print_label = TRUE,
    print_value = TRUE,
    sep = ' = ',
    digits = 2,
    tick = waiver(),
    colour = waiver(),
    hjust = waiver(),
    vjust = waiver(),
    size = waiver(),
    fontface = waiver(),
    family = waiver(),
    rot = waiver()
  ),
  
  get_param = function(self, x) {
    mine <- self$params[x]
    mine <- mine[!sapply(mine, is.null)]
    if (length(x) > length(mine)) {
      mine <- c(mine, AxisAnnotation$params[setdiff(x, names(mine))])
    }
    if (length(x) == 1)
      return(mine[[1]])
    return(mine)
  },
  
  label = function(self) {
    if (!self$get_param('print_label'))
      return(round(self$get_param('value'), self$get_param('digits')))
    if (!self$get_param('print_value'))
      return(self$get_param('label'))
    paste0(self$get_param('label'), self$get_param('sep'), 
           round(self$get_param('value'), self$get_param('digits')))
  }
)

AxisAnnotationText <- ggplot2::ggproto('AxisAnnotationText', AxisAnnotation, reducible=TRUE)

AxisAnnotationBquote <- ggplot2::ggproto('AxisAnnotationBquote', AxisAnnotation,
  reducible = FALSE,
  params = list(
    print_value = FALSE
  ), 
  label = function(self) {
    l <- self$get_param('label')
    l <- gsub("\\.\\(y\\)", round(self$get_param('value'), self$get_param('digits')), l)
    l <- gsub("\\.\\(val\\)", round(self$get_param('value'), self$get_param('digits')), l)
    parse(text=l)
  },
  draw = function(self, side, range, theme) {
    g <- ggplot2::ggproto_parent(AxisAnnotation, self)$draw(side, range, theme)
    g[[1]]$label <- self$label()
    g
  }
)


#' @export
#' @keywords internal
ggplot_add.axis_annotation <- function(object, plot, object_name) {
  plot <- as.lemon_plot(plot)
  plot$axis_annotation <- plot$axis_annotation$clone()
  plot$axis_annotation$add(object)
  plot
}

# Annotation "slot" in the plot ----------------
# Modelled after ScalesList in ggplot2/R/scales-.r


axis_annotation_list <- function() {
  ggproto(NULL, AAList)
}

as.is <- function(x) {x}


#' @export
#' @keywords internal
ggplot_add.axis_annotation <- function(object, plot, object_name) {
  plot <- as.lemon_plot(plot)
  plot$axis_annotation <- plot$axis_annotation$clone()
  plot$axis_annotation$add(object)
  plot
}

#' @rdname lemon-ggproto
#' @import ggplot2
#' @import grid
#' @import scales
AAList <- ggplot2::ggproto("AAList", NULL,
  annotations = NULL,
  
  # self.annotations holds a heriachical list of all annotations, i.e.
  # self.annotations$x = list(...)
  # self.annotations$y = list(...)
  # but only after first is added.
  add = function(self, new_annotation) {
    if (is.null(new_annotation)) {
      return()
    }
    if (!inherits(new_annotation, 'AxisAnnotation'))
      stop('Not sure what to do with an object of type',class(new_annotation),'.')
    
    new_aes <- new_annotation$aesthetic[1]
    if (is.null(new_aes)) 
      stop('Adding a axis annotation requires an annotation class with either "x" or "y" as aesthetic.')

    self$annotations <- c(self$annotations, list(new_annotation))
  },
  
  # See ggplot2/R/scales-.r for cloning. 
  # Might be necessary to avoid updating a referenced object.
  clone = function(self) {
    ggproto(NULL, self, annotations=lapply(self$annotations, as.is))
  },
  
  n = function(self, aesthetic=NULL) {
    if (is.null(aesthetic))
      return(length(self$annotations))
    
    res <- table(vapply(self$annotations, function(a) a$aesthetic, character(1)))[aesthetic]
    names(res) <- aesthetic
    res[is.na(res)] <- 0
    res
  },
  
  
  draw = function(self, side, is.primary=FALSE, range, theme) {
    annotations <- self$get_annotations(side, is.primary)
    if (length(annotations) == 0)
      return(zeroGrob())
    
    #aes <- switch(side, top='x', bottom='x', left='y', right='y', NA)
    
    label_render <- switch(side,
       top = "axis.text.x.top", bottom = "axis.text.x",
       left = "axis.text.y", right = "axis.text.y.right"
    )
    tick_render <- switch(side,
       top = 'axis.ticks.x.top', bottom = 'axis.ticks.x', 
       left = 'axis.ticks.y', right = 'axis.ticks.y.right'
    )
    
    default <- ggplot2::calc_element(label_render, theme)
    tick = is.null(render_gpar(theme, tick_render))
    
    # coerce to single data.frame where possible 
    are_reducible <- vapply(annotations, function(a) a$reducible %||% FALSE, logical(1))
    if (sum(are_reducible) > 0) {

      labels <- lapply(annotations[are_reducible], function(a) {
        a$label()
      })
      
      params <- lapply(annotations[are_reducible], function(a) {
        data.frame(
          values = a$get_param('value'),
          colour = a$get_param('colour') %|W|% default$colour,
          hjust = a$get_param('hjust') %|W|% default$hjust,
          vjust = a$get_param('vjust') %|W|% default$vjust,
          rot = a$get_param('rot') %|W|% default$angle,
          face = a$get_param('fontface') %|W|% default$face,
          family = a$get_param('family') %|W|% default$family,
          size = a$get_param('size') %|W|% default$size,
          tick = a$get_param('tick') %|W|% tick,
          stringsAsFactors = FALSE
        )
      }) 
      params <- do.call(rbind, params)
      
      params$tickcolour <- ifelse(params$tick, params$colour, NA)
      
      axisgrob <- old_guide_axis(scales::rescale(params$values, from=range), labels, side, theme)
    } else {
      axisgrob <- old_guide_axis(NA, NA, side, theme)
    }
    
    gt_index <- which(axisgrob$childrenOrder == 'axis')
    if (sum(!are_reducible) > 0) {
      
      order <- switch(side,
        top = list(names=c('label','tick'), t=c(1,2), l=c(1,1), r=c(1,1), b=c(1,2)),
        bottom = list(names=c('tick','label'), t=c(1,2), l=c(1,1), r=c(1,1), b=c(1,2)),
        right = list(names=c('tick','label'), t=c(1,1), l=c(1,2), r=c(1,2), b=c(1,1)),
        left = list(names=c('label','tick'), t=c(1,1), l=c(1,2), r=c(1,2), b=c(1,1))
      )
      
      for (i in which(!are_reducible)) {
        a <- annotations[[i]]
        gp_df <- data.frame(
          values = a$get_param('value'),
          colour = a$get_param('colour') %|W|% default$colour,
          hjust = a$get_param('hjust') %|W|% default$hjust,
          vjust = a$get_param('vjust') %|W|% default$vjust,
          rot = a$get_param('rot') %|W|% default$angle,
          face = a$get_param('fontface') %|W|% default$face,
          family = a$get_param('family') %|W|% default$family,
          size = a$get_param('size') %|W|% default$size,
          tick = a$get_param('tick') %|W|% tick,
          stringsAsFactors = FALSE
        )
        
        next_grobs <- old_guide_axis(
          scales::rescale(a$get_param('value'), from=range), 
          a$label(), side, theme)
        
        axisgrob$children[[gt_index]] <- gtable_add_grob(
          x = axisgrob$children[[gt_index]],
          grobs = next_grobs$children[[gt_index]]$grobs[1:2],
          t=order$t, l=order$l, r=order$l, b=order$b, clip='off',
          name=paste(order$names, i, sep='-')
        )
      }
    }
    axisgrob
    #if (sum(!are_simple) > 0) {
    #  rest <- do.call(grid::gList,
    #    lapply(annotations[!are_simple], function(a) a$draw(side, range, theme)))
    #} else {
    #  rest <- ggplot2::zeroGrob()
    #}
    #grid::grobTree(textgrob, lg, rest, vp=temp$vp, gp=temp$gp)
  },

  # axis annotations can be shown on top, left, right, or bottom.
  # defaults to where the secondary axis is (i.e. not the primary)
  # the annotation itself does not need to know which side it has to be on.
  #' @param side top, left, right, bottom, etc.
  #' @param is.primary When TRUE, only get annotations whose side are set to that
  #'   side. When FALSE (default), also get those that are waiver.
  get_annotations = function(self, side, is.primary=FALSE) {
    aes <- switch(side, top='x', bottom='x', left='y', right='y', NA)
    
    #if (self$n(aes) == 0)
    #  return()
    
    #if (is.primary) {
    #  # only those with side as set
    #  i <- which(vapply(self$annotations[[aes]], function(a) {
    #    !is.waive(a$side) && a$side == side
    #  }, logical(1)))
    #} else {
    #  i <- which(vapply(self$annotations[[aes]], function(a) {
    #    is.waive(a$side) || a$side == side
    #  }, logical(1)))
    #}
    #self$annotations[[aes]][i]
    
    if (is.primary) {
      get <- vapply(self$annotations, function(a) {
        a$aesthetic == aes && (!is.waive(a$side) && a$side == side)
      }, logical(1))
    } else {
      get <- vapply(self$annotations, function(a) {
        a$aesthetic == aes && (is.waive(a$side) || a$side == side)
      }, logical(1))
    }    
    
    self$annotations[get]
  }

)

# ggplot2 v. 2.2.1 guide_axis
# Grob for axes
#
# @param position of ticks
# @param labels at ticks
# @param position of axis (top, bottom, left or right)
# @param range of data values
old_guide_axis <- function(at, labels, position = "right", theme) {
  if (length(at) == 0)
    return(zeroGrob())

  at <- unit(at, "native")
  position <- match.arg(position, c("top", "bottom", "right", "left"))

  zero <- unit(0, "npc")
  one <- unit(1, "npc")

  label_render <- switch(position,
    top = "axis.text.x.top", bottom = "axis.text.x",
    left = "axis.text.y", right = "axis.text.y.right"
  )

  label_x <- switch(position,
    top = ,
    bottom = at,
    right = theme$axis.ticks.length,
    left = one - theme$axis.ticks.length
  )
  label_y <- switch(position,
    top = theme$axis.ticks.length,
    bottom = one - theme$axis.ticks.length,
    right = ,
    left = at
  )

  if (is.list(labels)) {
    if (any(sapply(labels, is.language))) {
      labels <- do.call(expression, labels)
    } else {
      labels <- unlist(labels)
    }
  }

  labels <- switch(position,
    top = ,
    bottom = element_render(theme, label_render, labels, x = label_x),#, expand_y = TRUE),
    right = ,
    left =  element_render(theme, label_render, labels, y = label_y)#, expand_x = TRUE))
  )

  line <- switch(position,
    top =    element_render(theme, "axis.line.x", c(0, 1), c(0, 0), id.lengths = 2),
    bottom = element_render(theme, "axis.line.x", c(0, 1), c(1, 1), id.lengths = 2),
    right =  element_render(theme, "axis.line.y", c(0, 0), c(0, 1), id.lengths = 2),
    left =   element_render(theme, "axis.line.y", c(1, 1), c(0, 1), id.lengths = 2)
  )

  nticks <- length(at)

  ticks <- switch(position,
    top = element_render(theme, "axis.ticks.x",
      x          = rep(at, each = 2),
      y          = rep(unit.c(zero, theme$axis.ticks.length), nticks),
      id.lengths = rep(2, nticks)),
    bottom = element_render(theme, "axis.ticks.x",
      x          = rep(at, each = 2),
      y          = rep(unit.c(one - theme$axis.ticks.length, one), nticks),
      id.lengths = rep(2, nticks)),
    right = element_render(theme, "axis.ticks.y",
      x          = rep(unit.c(zero, theme$axis.ticks.length), nticks),
      y          = rep(at, each = 2),
      id.lengths = rep(2, nticks)),
    left = element_render(theme, "axis.ticks.y",
      x          = rep(unit.c(one - theme$axis.ticks.length, one), nticks),
      y          = rep(at, each = 2),
      id.lengths = rep(2, nticks))
  )

  # Create the gtable for the ticks + labels
  gt <- switch(position,
    top    = gtable_col("axis",
      grobs   = list(labels, ticks),
      width   = one,
      heights = unit.c(grobHeight(labels), theme$axis.ticks.length)
    ),
    bottom = gtable_col("axis",
      grobs   = list(ticks, labels),
      width   = one,
      heights = unit.c(theme$axis.ticks.length, grobHeight(labels))
    ),
    right  = gtable_row("axis",
      grobs   = list(ticks, labels),
      widths  = unit.c(theme$axis.ticks.length, grobWidth(labels)),
      height  = one
    ),
    left   = gtable_row("axis",
      grobs   = list(labels, ticks),
      widths  = unit.c(grobWidth(labels), theme$axis.ticks.length),
      height  = one
    )
  )

  # Viewport for justifying the axis grob
  justvp <- switch(position,
    top    = viewport(y = 0, just = "bottom", height = gtable_height(gt)),
    bottom = viewport(y = 1, just = "top",    height = gtable_height(gt)),
    right  = viewport(x = 0, just = "left",   width  = gtable_width(gt)),
    left   = viewport(x = 1, just = "right",  width  = gtable_width(gt))
  )

  absoluteGrob(
    gList(line, gt),
    width = gtable_width(gt),
    height = gtable_height(gt),
    vp = justvp
  )
}
