#' Late spring frost
#' 
#' Compute late spring frost, which is a freezing event occurring after
#'  a substantial accumulation of warmth
#' 
#' @family GDD functions
#' @inheritParams temperature
#' @inheritParams GDD
#' @param tfrost an integer for the freezing threshold
#' @details 
#' Additional arguments:
#' 
#' \code{equation}: character to specify the equation to be used, \code{"variant_a"} 
#'  is set by default. See GDD() 
#' 
#' \code{last.day}: an object (optional to \var{span}) of class \code{Date} or
#'  any other object that can be coerced to \code{Date} (e.g. integer, character 
#'  YYYY-MM-DD) for the last day of the time series
#'  
#' \code{span}: an integer (optional to \var{last.day}) or a vector with 
#'  integers (optional if \var{last.day} is given) for the length of 
#'  the time series to be captured
#'  
#' @return a data.frame with the late frost events
#' \item{id}{the id generated using the indices for the rows in \var{object}}
#' \item{date}{the first day of the event}
#' \item{gdd}{the growing degree-days accumulated during the event}
#' \item{event}{a factor for the observed event, frost, latent (where there is no frost event, 
#'  but also there is no GDD), and warming (where GDD is accumulated)}
#' \item{duration}{the number of days the event spanned}
#' 
#' @references  
#' Trnka et al. (2014). Nature Climate Change 4(7):637–43.
#' \cr\url{https://doi.org/10.1038/nclimate2242}
#' 
#' Zohner et al. (2020). PNAS.
#' \cr\url{https://doi.org/10.1073/pnas.1920816117}
#' 
#' @examples 
#' 
#' # default method
#' data("innlandet", package = "climatrends")
#' 
#' tmax <- innlandet[, "tmax"]
#' tmin <- innlandet[, "tmin"]
#' date <- innlandet[, "dates"]
#' 
#' late_frost(tmax, tmin, dates = date)
#' 
#' # demo of the array method but no frost event is returned 
#' # because the data comes from the tropics
#' data("temp_dat", package = "climatrends")
#' 
#' late_frost(temp_dat, day.one = "2013-10-27")
#' 
#' 
#' \donttest{
#' # Some random points in Norway
#' # get data from NASA Power
#' library("nasapower")
#' data("lonlatsf", package = "climatrends")
#'   
#' late_frost(lonlatsf, day.one = "2019-01-01", last.day = "2019-07-01")
#'   
#' }
#' 
#' @export
late_frost <- function(..., base = 4, tfrost = -2) {
  
  UseMethod("late_frost")

}


#' @rdname late_frost
#' @method late_frost default
#' @export
late_frost.default <- function(tmax, tmin, dates = NULL, ..., base = 4, tfrost = -2) {
  
  dots <- list(...)
  equation <- dots[["equation"]]
  
  if (is.null(equation)) {
    equation <- "variant_a"
  }
  
  if (!is.null(dates)) {
    dates <- .coerce2Date(dates)
  }
  
  if (is.null(dates)) {
    dates <- rep(NA, times = length(tmax))
  }
  
  temp <- data.frame(id = 1, tmax = tmax, tmin = tmin, date = dates, 
                     stringsAsFactors = FALSE)
  
  result <- .late_frost(temp, base, tfrost, equation)
  
  return(result)
  
}

#' @rdname late_frost
#' @method late_frost data.frame
#' @export
late_frost.data.frame <- function(object, day.one, ..., base = 4, tfrost = -2){
  
  dots <- list(...)
  pars <- dots[["pars"]]
  equation <- dots[["equation"]]
  
  if (is.null(equation)) {
    equation <- "variant_a"
  }
  
  # coerce inputs to data.frame
  object <- as.data.frame(object)
  
  if(dim(object)[[2]] != 2) {
    stop("Subscript out of bounds. In late_frost.default(),",
         " only lonlat should be provided. \n")
  }
  
  day.one <- as.data.frame(day.one)[, 1]
  
  if (is.null(pars)) {
    pars <- c("T2M_MAX", "T2M_MIN")
  }
  
  dat <- get_timeseries(object, day.one, pars = pars, ...)
  
  temp <- cbind(dat[[1]], tmin = dat[[2]]$value)
  
  names(temp)[names(temp)=="value"] <- "tmax"
  
  result <- .late_frost(temp, base, tfrost, equation)
  
  return(result)
}

#' @rdname late_frost
#' @method late_frost array
#' @export
late_frost.array <- function(object, day.one, ..., base = 4, tfrost = -2){
  
  dots <- list(...)
  span <- dots[["span"]]
  last.day <- dots[["last.day"]]
  equation <- dots[["equation"]]
  
  if (is.null(equation)) {
    equation <- "variant_a"
  }
  
  day.one <- as.vector(t(day.one))
  
  # check if day.one is a 'Date' else try to coerce to Date
  if (isFALSE(.is_Date(day.one))) {
    day.one <- .coerce2Date(day.one)
  }
  
  if (all(is.null(span), is.null(last.day))) {
    do <- as.character(max(day.one))
    do <- match(do, dimnames(object[,,1])[[2]])
    span <- dim(object)[[2]] - do
  }
  
  ts <- get_timeseries(object, day.one, span = span, last.day = last.day, ...)
  
  temp <- cbind(ts[[1]], tmin = ts[[2]]$value)
  
  names(temp)[names(temp)=="value"] <- "tmax"
  
  result <- .late_frost(temp, base, tfrost, equation)
  
  return(result)
}


#' @rdname late_frost
#' @method late_frost sf
#' @export
late_frost.sf <- function(object, day.one, ..., base = 4, tfrost = -2){
  
  dots <- list(...)
  pars <- dots[["pars"]]
  equation <- dots[["equation"]]
  
  if (is.null(equation)) {
    equation <- "variant_a"
  }
  
  day.one <- as.data.frame(day.one)[, 1]
  
  if (is.null(pars)) {
    pars <- c("T2M_MAX", "T2M_MIN")
  }
  
  dat <- get_timeseries(object, day.one, pars = pars, ...)
  
  temp <- cbind(dat[[1]], tmin = dat[[2]]$value)
  
  names(temp)[names(temp)=="value"] <- "tmax"
  
  result <- .late_frost(temp, base, tfrost, equation)
  
  
  return(result)
}



#' @rdname late_frost
#' @method late_frost clima_ls
#' @export
late_frost.clima_ls <- function(object, ..., base = 4, tfrost = -2){
  
  dots <- list(...)
  equation <- dots[["equation"]]
  
  if (is.null(equation)) {
    equation <- "variant_a"
  }
  
  temp <- cbind(object[[1]], tmin = object[[2]]$value)
  
  names(temp)[names(temp)=="value"] <- "tmax"
  
  result <- .late_frost(temp, base, tfrost, equation)
  
  return(result)
  
}



.late_frost <- function(obj, base, tfrost, equation = "variant_a") {

  obj <- split(obj, obj$id)

  result <- lapply(obj, function(temp){
    # get tmin
    tmin <- temp$tmin

    # calculate GDD
    g <- .gdd(temp,
              base = base,
              equation = equation,
              return.as = "daily")$gdd

    # get a vector where 1 are the frost events and 0 are the non-frost
    frost <- as.integer(tmin <= tfrost & g == 0)

    # apply rle function to find the lengths of
    # each event (freeze and non-frost)
    r <- rle(frost)

    # rep the lengths to create an id for each event
    rids <- r$lengths
    rids <- rep(1:length(rids), rids)
    
    isfrost <- which(r$values == 1)

    # create a data frame with this data
    dat <- data.frame(id = temp$id[1],
                      frost_id = rids,
                      date = temp$date,
                      gdd = g,
                      frost = frost,
                      stringsAsFactors = FALSE)

    # and split it to get the summaries of each event
    dat <- split(dat, dat$frost_id)

    dat <- lapply(dat, function(x){
      data.frame(id = x$id[1],
                 frost_id = x$frost_id[1],
                 date = x$date[1],
                 gdd = sum(x$gdd, na.rm = TRUE),
                 event = NA,
                 duration = length(x$frost_id))
    })

    dat <- do.call("rbind", dat)
    
    l <- !dat$frost_id %in% isfrost & dat$gdd == 0
    
    dat$event[l] <- "latent"
    
    dat$event[dat$frost_id %in% isfrost] <- "frost"
    
    dat$event[is.na(dat$event)] <- "warming"
    
    return(dat)
    
  })

  result <- do.call("rbind", result)

  result <- result[, -which(names(result) == "frost_id")]

  rownames(result) <- 1:dim(result)[[1]]
  
  result$event <- factor(result$event, levels = c("frost","latent","warming"))
  
  result$id <- as.integer(result$id)

  class(result) <- union("clima_df", class(result))

  return(result)


}