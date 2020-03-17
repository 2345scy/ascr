#' Fitting acoustic SCR models
#'
#' Fits an acoustic SCR model. Parameter estimation is done by maximum
#' likelihood through an AD Model Builder (ADMB) executable.
#'
#' ADMB uses a quasi-Newton method to find maximum likelihood
#' estimates for the model parameters. Standard errors are calculated
#' by taking the inverse of the negative of the
#' Hessian. Alternatively, \link{boot.ascr} can be used to carry out a
#' parametric bootstrap procedure.
#'
#' If the data are from an acoustic survey where stationary
#' individuals call more than once (i.e., the argument
#' \code{cue.rates} contains values that are not 1), then standard
#' errors calculated from the inverse of the negative Hessian are not
#' correct. They are therefore not provided in this case by default,
#' although this can be overridden by specifying \code{hess =
#' TRUE}. The method used by the function \link{boot.ascr} is
#' currently the only way to calculate these reliably (see Stevenson
#' et al., 2015, for details).
#'
#' @section The \code{ss.opts} argument:
#'
#' This argument allows the user to select options for the signal
#' strength detection function (for more details, see the section
#' below on fitted parameters). It is therefore only required if
#' signal strength information appears in the \code{capt} argument,
#' and is ignored (with a warning) otherwise.
#'
#' The argument \code{ss.opts} is a list with the following
#' components. The first two are relevant to the standard signal
#' strength model developed by Efford, Dawson, and Borchers
#' (2009). The remaining components are relevant to unpublished
#' extensions described in Stevenson (2016), a PhD thesis.
#'
#' \itemize{
#' 
#'   \item \code{cutoff}: Compulsory. The signal strength threshold,
#'         above which sounds are identified as detections.
#'
#'   \item \code{ss.link}: Optional. A character string, either
#'         \code{"identity"}, \code{"log"}, or \code{"spherical"}, which
#'         specifies the relationship between the expected received signal
#'         strength and distance from the microphone. See details on the
#'         signal strength detection function in the section 'Fitted
#'         parameters' below. Defaults to \code{"identity"}.
#' 
#'   \item \code{lower.cutoff}: Optional. Used for models where only
#'         the first detected call is used in the capture history. The
#'         lower cutoff is the signal strength value above which calls
#'         can be assumed to have been detected with certainty. See
#'         Stevenson (2016) for further details about first-call
#'         models.
#' 
#'   \item \code{het.source}: Optional. Logical, if \code{TRUE} a
#'         model with heterogeneity in source signal strengths is
#'         used. If unspecified, it will default to \code{FALSE}. See
#'         Stevenson (2016) for further details about models with
#'         heterogeneity in source signal strengths.
#'
#'   \item \code{het.source.method}: Optional. A character string,
#'         either \code{"GH"} or \code{"rect"}. If \code{"GH"},
#'         integration over source strengths uses Gauss-Hermite
#'         quadrature, which is recommended and also the default. If
#'         \code{"rect"}, the rectangle method is used.
#' 
#'   \item \code{n.het.source.quadpoints}: Optional. An integer,
#'         giving the number of quadrature points used for numerical
#'         integration over source strengths for models with
#'         heterogeneity in source strengths. Defaults to 15. A larger
#'         number of quadrature points leads to more accurate results,
#'         but will increase computation time.
#' 
#'   \item \code{directional}: Optional. Logical, if \code{TRUE} a
#'         directional signal strength model is used. If unspecified,
#'         it will default to \code{FALSE}, unless the \code{b2.ss}
#'         parameter (which controls directionality) is provided in
#'         \code{sv} or \code{fix}, in which case it will default to
#'         \code{TRUE}. See Stevenson (2016) for further details about
#'         directional-calling models.
#' 
#'   \item \code{n.dir.quadpoints}: Optional. An integer, giving the
#'         number of quadrature points used for numerical integration
#'         over the possible call directions. Defaults to 8, but needs
#'         to be larger when calls are more directional (i.e., b2.ss
#'         parameter is large). A larger number of quadrature points
#'         leads to more accurate results, but will increase
#'         computation time.
#'
#' }
#'
#' @section The \code{ihd.opts} argument:
#'
#' This argument allows the user to select options for the fitting on
#' inhomogeneous density surfaces.
#'
#' The argument \code{ihd.opts} is a list with up to three components:
#' \itemize{
#'    \item \code{model}: Compulsory. An equation for the relationship between
#'          covariates and the log of the density surface.
#'    \item \code{covariates}: Compulsory. A list of data frames, one
#'          for each session. Each data frame provides covariate
#'          values at each mask point.
#'    \item \code{scale}: Optional. If \code{TRUE}, the default,
#'          covariates are scaled by subtracting the mean and dividing
#'          by the standard deviaton. This does not affect model
#'          inference and improves optimisation stability, but makes
#'          it more difficult to interpret estimated coefficients.
#' }
#'
#' @section The \code{optim.opts} argument:
#'
#' This argument allows the user to select options for the
#' maximisation of the likelihood. These options can almost always be
#' safely ignored, but allow the user a little control over the
#' optimisation carried out by the ADMB executable.
#'
#' The argument \code{optim.opts} is a list with up to five components:
#' \itemize{
#'
#' \item \code{neld.mead}: Optional. A logical value specifying
#'     whether or not to use Nelder-Mead optimisation. Defaults to
#'     \code{FALSE}.
#'
#' \item \code{phases}: Optional. A named list. Component names are
#'     parameter names, and each component is a phase for the
#'     associated parameter. When specified, parameters are maximised
#'     over in phases, which can help convergence.
#'
#' \item \code{sf} A named list. Component names are parameter names,
#'     and each component is a scalefactor for the associated
#'     parameter. The default behaviour is to automatically select
#'     scalefactors based on parameter start values. See the section
#'     on convergence below.
#'
#' \item \code{cbs}: Optional. The CMPDIF_BUFFER_SIZE, set using the
#'     \code{-cbs} option of the executable created by ADMB. This can
#'     be increased to speed up optimisation if \code{cmpdiff.tmp}
#'     gets too large (please ignore, unless you are familiar with
#'     ADMB and know what you are doing).
#'
#' \item \code{gbs}: Optional. The GRADSTACK_BUFFER_SIZE, set using
#'     the \code{-gbs} option of the executable created by ADMB. This
#'     can be increased to speed up optimisation if
#'     \code{gradfil1.tmp} gets too large (please ignore, unless you
#'     are familiar with ADMB and know what you are doing).
#'
#' }
#'
#' @section Fitted parameters:
#'
#' For homogeneous density models, the parameter \code{D} is
#' estimated, representing the density of locations. This is the
#' density of individuals if each capture history is associated with a
#' specific individual.
#'
#' For acoustic surveys, where each capture history is associated with
#' a call, \code{D} is the density of calls, and is scaled by
#' \code{survey.length} to represent the density of calls per unit
#' time per hectare. An estimate of animal density given by \code{Da}
#' in this scenario if independently collected cue rates are provided
#' in the argument \code{cue.rates}.
#'
#' For inhomogeneous density models, specified via \code{ihd.opts},
#' coefficients for the log-linear relationship between covariates and
#' \eqn{log(D)} are fitted.
#'
#' The effective sampling area area, \code{esa}, (see Borchers, 2012,
#' for details) is always provided as a derived parameter, with a
#' standard error calculated using the delta method. For multi-session
#' models, an effective sampling error is provided for each session.
#'
#' Further parameters to be fitted depend on the choice of the
#' detection function (i.e., the \code{detfn} argument), and the types
#' of additional information collected (i.e., the components in the
#' \code{capt}).
#'
#' Details of the detection functions are as follows:
#'
#' For \code{detfn = "hn"}:
#' \itemize{
#'    \item Estimated parameters are \code{g0} and \code{sigma}.
#'    \item \eqn{g(d) = g_0\ exp(-d^2/(2\sigma^2))}{g(d) = g0 * exp( -d^2 / (2 * sigma^2 ))}
#' }
#'
#' For \code{detfn = "hhn"}:
#' \itemize{
#'    \item Estimated paramters are \code{lambda0} and \code{sigma}.
# '   \item \eqn{g(d) = 1 - exp( -\lambda_0\ exp(-d^2/(2\sigma^2)))}{g(d) = 1 - exp( -lambda0 exp( -d^2 / (2 * sigma^2 )))}
#' }
#' 
#' For \code{detfn = "hr"}:
#' \itemize{
#'    \item Estimated parameters are \code{g0}, \code{sigma}, and
#'          \code{z}.
#'    \item \eqn{g(d) = g_0\ (1 - exp(-(d/\sigma)^{-z}))}{g(d) = g0 * ( 1 - exp( -(d/sigma)^{-z} ) )}
#' }
#'
#' For \code{detfn = "lth"}:
#' \itemize{
#'   \item Estimated parameters are \code{shape.1}
#'         \ifelse{latex}{(\eqn{\kappa})}{}, \code{shape.2}
#'         \ifelse{latex}{(\eqn{\nu})}{}, and \code{scale}
#'         \ifelse{latex}{(\eqn{\tau})}{}.
#'   \item \eqn{g(d) = 0.5 - 0.5\ erf(\kappa - exp(\nu - \tau d))}{g(d) = 0.5 - 0.5 * erf( shape.1 - exp( shape.2 - scale * d ) )}
#' }
#'
#' For \code{detfn = "th"}:
#' \itemize{
#'   \item Estimated parameters are \code{shape}
#'         \ifelse{latex}{(\eqn{\kappa})}{} and \code{scale}
#'         \ifelse{latex}{(\eqn{\tau})}{}.
#'   \item \eqn{g(d) = 0.5 - 0.5\ erf(d/\tau - \kappa)}{g(d) = 0.5 - 0.5 * erf( d/scale - shape )}
#' }
#'
#' For \code{detfn = "ss"} in a non-directional model:
#' \itemize{
#'   \item The signal strength detection function is special in that
#'         it requires signal strength information to be collected in
#'         order for all parameters to be estimated.
#'   \item Estimated parameters are \code{b0.ss}, \code{b1.ss}, and
#'         \code{sigma.ss}.
#'   \item The expected signal strength is modelled as:
#'         \eqn{E(SS) = h^{-1}(\beta_0 - \beta_1d)}{E(SS) = h^{-1}(b0.ss - b1.ss*d)},
#'         where \eqn{h} is specified by the argument \code{ss.link}.
#' }
#'
#' For \code{detfn = "ss"} in a directional model:
#' \itemize{
#'   \item Estimated parameters are \code{b0.ss}, \code{b1.ss}, \code{b2.ss} and
#'         \code{sigma.ss}.
#'   \item The expected signal strength is modelled differently depending on the value of \code{ss.link} in \code{ss.opts}:
#'   \itemize{
#'     \item For \code{ss.link = "identity"} (the default):
#'     \itemize{
#'       \item \eqn{E(SS) = \beta_0 - (\beta_1 - (\beta_2(\cos(\theta) - 1)))d)}{E(SS) = h^{-1}( b0.ss - ( b1.ss - ( b2.ss * ( cos( theta ) - 1 ) ) ) * d }
#'     }
#'     \item For \code{ss.link = "log"}:
#'     \itemize{
#'       \item \eqn{E(SS) = log(\beta_0 - (\beta_1 - (\beta_2(\cos(\theta) - 1)))d)}{E(SS) = h^{-1}( b0.ss - ( b1.ss - ( b2.ss * ( cos( theta ) - 1 ) ) ) * d ) }
#'     }
#'     \item For \code{ss.link = "spherical"}:
#'     \itemize{
#'       \item \eqn{E(SS) = \beta_0 - 10\log_{10}(d^2) - ( \beta_1 - ( \beta_2(\cos(\theta ) - 1)))(d - 1)}{E(SS) = \beta_0 - 10 * \log_{10}(d^2) - ( b1.ss - ( b2.ss( \cos( \theta ) - 1 ) ) ) * ( d - 1 )}
#'     }
#'   }
#'   \item In all cases \eqn{\theta}{theta} is the difference between
#'   the bearing the animal is facing when it makes a call, and the
#'   bearing from the animal to the detector.
#'
#' }
#'
#' Details of the parameters associated with different additional data
#' types are as follows:
#'
#' For data type \code{"bearing"}, \code{kappa} is estimated. This is
#' the concerntration parameter of the von-Mises distribution used for
#' measurement error in estimated bearings.
#'
#' For data type \code{"dist"}, \code{alpha} is estimated. This is the
#' shape parameter of the gamma distribution used for measurement
#' error in estimated distances.
#'
#' For data type \code{"toa"}, \code{sigma.toa} is estimated. This is
#' the standard deviation parameter of the normal distribution used
#' for measurement error in recorded times of arrival.
#'
#' For data type \code{"mrds"}, no extra parameters are
#' estimated. Animal location is assumed to be known.
#'
#' @section Local integration:
#'
#' For SCR models, the likelihood is calculated by integrating over
#' the unobserved animal activity centres (see Borchers and Efford,
#' 2008). Here, the integral is approximated numerically by taking a
#' sum over the mask points. The integrand is negligible in size for
#' mask points far from detectors that detected a particular
#' individual, and so to increase computational efficiency the region
#' over which this sum takes place can be reduced.
#'
#' Setting \code{local} to \code{TRUE} will only carry out this sum
#' across mask points that are within the mask buffer distance of
#' \emph{all} detectors that made a detection. So long as the buffer
#' suitably represents a distance beyond which detection is
#' practically impossible, the effect this has on parameter estimates
#' is negligible, but processing time can be substantially reduced,
#' particularly if many detectors have been deployed and the mask is
#' large.
#'
#' Note that this increases the parameter estimates' sensitivity to
#' the buffer. A buffer that is too small will lead to inaccurate
#' results.
#'
#' @references Borchers, D. L., and Efford, M. G. (2008) Spatially
#'     explicit maximum likelihood methods for capture-recapture
#'     studies. \emph{Biometrics}, \strong{64}: 377--385.
#'
#' @references Borchers, D. L. (2012) A non-technical overview of
#'     spatially explicit capture-recapture models. \emph{Journal of
#'     Ornithology}, \strong{152}: 435--444.
#'
#' @references Borchers, D. L., Stevenson, B. C., Kidney, D., Thomas,
#'     L., and Marques, T. A. (2015) A unifying model for
#'     capture-recapture and distance sampling surveys of wildlife
#'     populations. \emph{Journal of the American Statistical
#'     Association}, \strong{110}: 195--204.
#'
#' @references Stevenson, B. C., Borchers, D. L., Altwegg, R., Swift,
#'     R. J., Gillespie, D. M., and Measey, G. J. (2015) A general
#'     framework for animal density estimation from acoustic
#'     detections across a fixed microphone array. \emph{Methods in
#'     Ecology and Evolution}, \strong{6}: 38--48.
#'
#' @return A list of class \code{"ascr"}. Components contain
#'     information such as estimated parameters and standard
#'     errors. The best way to access such information, however, is
#'     through the variety of helper functions provided by the
#'     ascr package.
#'
#' @param capt A list containing capture histories and supplementary
#'     data for each detected individual. It is most easily created
#'     using \link{create.capt}.
#' @param traps A matrix with two columns. Each row provides Cartesian
#'     coordinates for the location of a detector. Alternatively, this
#'     can be a list of such matrices if detections from multiple
#'     detector arrays (or `sessions') are being used to fit a single
#'     model.
#' @param mask A matrix with two columns, or a list of such matrices
#'     for a multi-session model. Each row provides Cartesian
#'     coordinates for the location of a mask point. It is most easily
#'     created using \link{create.mask}.
#' @param detfn A character string specifying the detection function
#'     to be used. One of "hn" (halfnormal), "hhn" (hazard
#'     halfnormal), "hr" (hazard rate), "th" (threshold), "lth"
#'     (log-link threshold), or "ss" (signal strength). If the latter
#'     is used, signal strength information must be provided in
#'     \code{capt}.
#' @param sv A named list. Component names are parameter names, and
#'     each component is a start value for the associated
#'     parameter. See 'Details' for further information on the
#'     parameters to be fitted.
#' @param bounds A named list. Component names are parameter names,
#'     and each components is a vector of length two, specifying the
#'     upper and lower bounds for the associated parameter.
#' @param fix A named list. Component names are parameter names to be
#'     fixed, and each component is the fixed value for the associated
#'     parameter.
#' @param ss.opts Options for models using the signal strength
#'     detection function. See 'Details' below.
#' @param cue.rates A vector of call rates collected independently of
#'     the main acoustic survey. This must be measured in calls per
#'     unit time, where the time units are equivalent to those used by
#'     \code{survey.length}. For example, if the survey was 30 minutes
#'     long, the cue rates must be provided in cues per minute if
#'     \code{survey.length = 30}, but in cues per hour if
#'     \code{survey.length = 0.5}.
#' @param survey.length The length of a cue-based survey. If provided,
#'     the estimated density \code{D} is measured in cues per unit
#'     time (using the same units as \code{survey.length}). For
#'     multi-session data, this must be a vector, giving the survey
#'     lengths for each session.
#' @param sound.speed The speed of sound in metres per
#'     second. Defaults to 330 (approximately the speed of sound in
#'     air). Only used when \code{"toa"} is a component name of
#'     \code{capt}.
#' @param local Logical, if \code{TRUE} integration over unobserved
#'     animal activity centres is only carried out in a region local
#'     to detectors that detected individuals. See 'Details'.
#' @param model A list specifying how to model parameters using
#'     covariates. See 'Details' below.
#' @param dfs A list of data frames providing covariates to model.
#' @param ihd.opts Options for inhomogeneous density. Deprecated.
#' @param hess Logical, if \code{TRUE} the Hessian is estimated,
#'     allowing for calculation of standard errors, the
#'     variance-covariance matrix, and the correlation matrix, at the
#'     expense of a little processing time. If \code{FALSE}, the
#'     Hessian is not estimated. Note that if stationary individuals
#'     are detectable more than once (e.g., by calling more than once
#'     on an acoustic survey) then parameter uncertainty is not
#'     properly represented by these calculations. As a result, this
#'     argument defaults to \code{FALSE} if \code{cue.rates} is
#'     provided.
#' @param trace Logical, if \code{TRUE} parameter values at each step
#'     of the optimisation algorithm are printed to the R console.
#' @param cov.scale Logical, if \code{TRUE}, covariates are centred
#'     and scaled to aid optimisation convergence.
#' @param clean Logical, if \code{TRUE} ADMB output files are
#'     removed. Otherwise, ADMB output file will remain in a
#'     directory, the location of which is reported after the model is
#'     fitted.
#' @param optim.opts Optimisation options. See 'Details' for further
#'     information.
#' @param ... Other arguments (mostly for back-compatibility).
#'
#' @seealso \link{boot.ascr} to calculate standard errors and
#'     estimate bias using a parametric bootstrap.
#' @seealso \link{coef.ascr}, \link{stdEr.ascr}, and
#'     \link{vcov.ascr} to extract estimated parameters, standard
#'     errors, and the variance-covariance matrix, respectively.
#' @seealso \link{confint.ascr} to calculate confidence intervals.
#' @seealso \link{summary.ascr} to get a summary of estimates and
#'     standard errors.
#' @seealso \link{show.detfn} to plot the estimated detection
#'     function.
#' @seealso \link{locations} to plot estimated locations of particular
#'     individuals or calls.
#'
#' @examples
#' \dontrun{
#' ## Getting some data.
#' simple.capt <- example.data$capt["bincapt"]
#' ## A simple model.
#' simple.hn.fit <- fit.ascr(capt = simple.capt, traps = example.data$traps,
#'                           mask = example.data$mask, fix = list(g0 = 1))
#' ## A simple model with a hazard-rate detection function.
#' simple.hr.fit <- fit.ascr(capt = simple.capt, traps = example.data$traps,
#'                           mask = example.data$mask, detfn = "hr")
#' ## Including some bearing information.
#' bearing.capt <- example.data$capt[c("bincapt", "bearing")]
#' ## Fitting a model with bearing information.
#' bearing.hn.fit <- fit.ascr(capt = bearing.capt, traps = example.data$traps,
#'                            mask = example.data$mask, fix = list(g0 = 1))
#' ## Getting some multi-session data.
#' multi.capt <- lapply(multi.example.data$capt, function(x) x[1])
#' multi.fit <- fit.ascr(multi.capt, multi.example.data$traps,
#'                       multi.example.data$mask)
#' }
#'
#' @export
fit.ascr <- function(capt, traps, mask, detfn = "hn", model = NULL, dfs = NULL,
                     sv = NULL, bounds = NULL, fix = NULL, ss.opts = NULL,
                     cue.rates = NULL, survey.length = NULL, sound.speed = 330,
                     ihd.opts = NULL, local = FALSE, hess = NULL, trace = FALSE,
                     cov.scale = TRUE, clean = TRUE, optim.opts = NULL, ...){
    ## Sorting out objects if they provided in single-session format.
    if (!is.list(traps)){
        traps <- list(traps)
    }
    if (!is.list(mask)){
        mask <- list(mask)
    }
    if (!is.list(capt[[1]])){
        capt <- list(capt)
    }
    ## Number of sessions.
    n.sessions <- length(traps)
    ## Checking for consistent list lengths.
    if ((length(capt) != n.sessions) | (length(mask) != n.sessions)){
        stop("Arugments 'capt', 'trap', and 'mask' imply different number of sessions.")
    }
    ## Number of traps per session.
    n.traps <- sapply(traps, nrow)
    ## Number of mask points per session.
    n.mask <- sapply(mask, nrow)
    ## Extracting types of information provided in capt. Note that
    ## these are vectors of length n.sessions, allowing different
    ## information types to be collected on different sessions. TODO:
    ## Actually implement this in ADMB.
    capt.names <- vector(mode = "list", length = n.sessions)
    fit.bearing <- sapply(capt, function(x) any(names(x) == "bearing"))
    fit.dist <- sapply(capt, function(x) any(names(x) == "dist"))
    fit.mrds <- sapply(capt, function(x) any(names(x) == "mrds"))
    fit.ss <- sapply(capt, function(x) any(names(x) == "ss"))
    fit.ss.any <- any(fit.ss)
    fit.toa <- sapply(capt, function(x) any(names(x) == "toa"))
    fit.supp.types <- c(bearing = any(fit.bearing), dist = any(fit.dist),
                        mrds = any(fit.mrds), ss = any(fit.ss), toa = any(fit.toa))
    ## Error if signal strengths are only sometimes provided.
    if (!all(fit.ss) & !all(!fit.ss)){
        stop("Signal strengths must be collected for all sessions, or for no sessions.")
    }
    ## Names of supplementary information parameters.
    supp.par.names <- c("kappa", "alpha", "sigma.toa")[fit.supp.types[c("bearing", "dist", "toa")]]
    ## Extracting some signal strength information.
    ss.cutoff <- ss.opts$cutoff
    ss.link <- ss.opts$ss.link
    if (fit.ss.any){
        if (!missing(detfn) & detfn != "ss"){
            warning("Argument 'detfn' is being ignored as signal strength information is provided in 'capt'. A signal strength detection function has been fitted instead.")
        }
        if (ss.link == "identity"){
            detfn <- "ss"
            linkfn.id <- 1
        } else if (ss.link == "log"){
            detfn <- "log.ss"
            linkfn.id <- 2
        } else if (ss.link == "spherical"){
            detfn <- "spherical.ss"
            linkfn.id <- 3
        }
    }
    ## Sorting out detection function ID for ADMB:
    ## 1 = Half normal
    ## 2 = Hazard halfnormal
    ## 3 = Hazard rate
    ## 4 = Threshold
    ## 5 = Log-link threshold
    ## 6 = Identity-link signal strength
    ## 7 = Log-link signal strength.
    ## 8 = Spherical-spreading signal strength.
    detfn.id <- which(detfn == c("hn",
                                 "hhn",
                                 "hr",
                                 "th",
                                 "lth",
                                 "ss",
                                 "log.ss",
                                 "spherical.ss"))
    ## Setting detection function parameter names.
    det.par.names <- switch(detfn,
                            hn = c("g0", "sigma"),
                            hhn = c("lambda0", "sigma"),
                            hr = c("g0", "sigma", "z"),
                            th = c("shape", "scale"),
                            lth = c("shape.1", "shape.2", "scale"),
                            ss = c("b0.ss", "b1.ss", "sigma.ss"),
                            log.ss = c("b0.ss", "b1.ss", "sigma.ss"),
                            spherical.ss = c("b0.ss", "b1.ss", "sigma.ss"))
    ## Extracting session data frame with special variable 'session'.
    session.df <- dfs$session
    if (is.null(session.df)){
        session.df <- data.frame(session = factor(1:n.sessions))
    } else {
        session.df <- data.frame(session = factor(1:n.sessions), session.df)
    }
    ## Extracting mask data frame.
    mask.df <- dfs$mask
    if (is.null(mask.df)){
        mask.df <- vector(mode = "list", length = n.sessions)
        for (i in 1:n.sessions){
            mask.df[[i]] <- mask[[i]][, 1:2]
        }
    }
    ## Extracting traps data frame.
    trap.df <- dfs$trap
    ## Extracting detections data frame.
    detection.df <- dfs$detection
    ## Determining parameters in model statement.
    model.pars <- sapply(model, function(x) rownames(attr(terms(x), "factors"))[1])
    ## Setting up model matrix for D. Parameter affected by session
    ## and mask covariates, so we need a row for every mask point.
    browser()
    D.session.df <- data.frame(session.df[rep(1:n.sessions, times = n.mask), ])
    names(D.session.df) <- names(session.df)
    D.mask.df <- do.call(rbind, mask.df)
    D.df <- data.frame(D.session.df, D.mask.df)
    D.scale.covs <- scale.closure(D.df, cov.scale)
    D.df <- D.scale.covs(D.df)
    D.df <- data.frame(D.df, D = rep(0, nrow(D.df)))
    ## Extracting model statement for D.
    if (any(model.pars == "D")){
        D.formula <- model[[model.pars == "D"]]
    } else {
        D.formula <- D ~ 1
    }
    D.mm <- gam(D.formula, data = D.df, fit = FALSE)$X
    D.beta.names <- paste("D.", colnames(D.mm), sep = "")
    ## Setting up model matrices for detection function parameters.
    ## TODO.
    ## Setting up model matrices for supplementary information parameters.
    ## TODO.
}

