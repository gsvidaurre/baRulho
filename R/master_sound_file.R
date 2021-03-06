#' Create a master sound file
#' 
#' \code{master_sound_file} creates a master sound file to be used in playback experiments related to sound degradation.
#' @usage master_sound_file(X, file.name, dest.path = NULL, overwrite = FALSE, delay = 1, gap.duration = 1, amp.marker = 2)
#' @param X object of class 'extended_selection_table' created by the function \code{\link[warbleR]{selection_table}} from the warbleR package, or can be generated from Raven and Syrinx selection tables using the \code{\link[Rraven]{imp_raven}} or \code{\link[Rraven]{imp_syrinx}} functions from the Rraven package. The object must include the following additional columns: 'bottom.freq' and 'top.freq'.
#' @param file.name Character string indicating the name of the sound file.
#' @param dest.path Character string containing the directory path where the sound file will be saved.
#' If \code{NULL} (default) then the current working directory will be used instead.
#' @param overwrite Logical argument to determine if the function will overwrite any existing sound file with the same file name. Default is \code{FALSE}.
#' @param delay Numeric vector of length 1 to control the duration (in s) of a silence gap at the beginning of the sound file. This can be useful to allow some time at the start of the playback experiment. Default is 1.
#' @param gap.duration Numeric vector of length 1 to control the duration (in s) of silence gaps to be placed in between signals. Default is 1 s.
#' @param amp.marker Numeric vector of length 1 to use as a constant to amplify markers amplitude. This is useful to increase the amplitude of markers in relation to those of signals, so it is picked up at further distances. Default is 2.
#' @return Extended selection table similar to input data, but includes a new column (cross.correlation)
#' with the spectrogram cross-correlation coefficients.
#' @export
#' @name master_sound_file
#' @details The function is intended to simplify the creation of master sound files for playback experiments in signal degradation studies. The function takes the wave objects from extended selection tables and concatenate them in a single sound file. The function also adds acoustic markers at the start and end of the playback that can be used to time-sync re-recorded signals to facilitate the streamlining of degradation quantification.
#' @examples
#' {
#' # load example data from warbleR
#' data(list = c("Phae.long1", "Phae.long2", "Phae.long3", "Phae.long4", 
#' "lbh_selec_table"))
#' 
#' # save sound files to temporary folder
#' writeWave(Phae.long1, file.path(tempdir(), "Phae.long1.wav"))
#' writeWave(Phae.long2, file.path(tempdir(), "Phae.long2.wav"))
#' writeWave(Phae.long3, file.path(tempdir(), "Phae.long3.wav"))
#' writeWave(Phae.long4, file.path(tempdir(), "Phae.long4.wav"))
#' 
#' # make an extended selection table
#' est <- selection_table(X = lbh_selec_table, extended = TRUE, confirm.extended = FALSE, 
#' path = tempdir())
#' 
#' # create master sound file
#' master.sel.tab <- master_sound_file(X = est, file.name = "example_master", 
#' dest.path = tempdir(), gap.duration = 0.3)
#' 
#' # the following code exports the selection table to Raven using Rraven package
#' # Rraven::exp_raven(master.sel.tab, path = tempdir(), file.name = "example_master_selection_table")
#' }
#' 
#' @author Marcelo Araya-Salas (\email{marceloa27@@gmail.com})
#' @seealso \code{\link[Rraven]{exp_raven}}
#' @references {
#' Araya-Salas, M. (2020). baRulho: baRulho: quantifying habitat-induced degradation of (animal) acoustic signals in R. R package version 1.0.0
#' }
# last modification on jan-06-2020 (MAS)

master_sound_file <- function(X, file.name, dest.path = NULL, overwrite = FALSE, delay = 1, gap.duration = 1, amp.marker = 2){
  
  # is extended sel tab
  if (!warbleR::is_extended_selection_table(X)) 
    stop("'X' must be and extended selection table")

  # must have the same sampling rate
  if (length(unique(attr(X, "check.results")$sample.rate)) > 1) 
    stop("all wave objects in the extended selection table must have the same sampling rate (they can be homogenized using warbleR::resample_est())")
  
  # make overwrite FALSE if file doesn't exist
  if (!overwrite & file.exists(file.path(dest.path, file.name))) 
    stop("output .wav file already exists and overwrite is 'FALSE'")
    
  #check path to working directory
  if (is.null(dest.path)) dest.path <- getwd() else 
    if (!dir.exists(dest.path)) stop("'dest.path' provided does not exist") 
  
  # set frequency range for markers
    flim <- c(0, attr(X, "check.results")$sample.rate[1] / 2)
    
 # at least 3 rows
  if (nrow(X) < 2) 
    stop("'X' must have at least 2 rows (selections)")
  
  # remove margins in graphic device
  par(mar = rep(0, 4))
  
  # empty plot
  plot(0, type='n',axes = FALSE, ann = FALSE, xlim = c(0, 1), ylim = c(0, 1))
  
  # add text
  text(x = 0.5, y = 0.5, labels = "*start+", cex = 14, font = 1)
  
  # save image of start marker in temporary directory
  dev2bitmap(file.path(tempdir(), "strt_mrkr-img.png"), type = "pngmono", res = 30)
  
  # empty plot
  plot(0, type='n',axes = FALSE, ann = FALSE, xlim = c(0, 1), ylim = c(0, 1))
  
  # add text
  text(x = 0.5, y = 0.5, labels = "+end*-", cex = 14, font = 1)
  
  # save image of end marker in temporary directory
  dev2bitmap(file.path(tempdir(), "end_mrkr-img.png"), type = "pngmono", res = 30)
  
  # conver to wave both
  strt_mrkr <- warbleR::image_to_wave(file = file.path(tempdir(), "strt_mrkr-img.png"), plot = FALSE, flim = flim, samp.rate = attr(X, "check.results")$sample.rate[1])
  
  end_mrkr <- warbleR::image_to_wave(file = file.path(tempdir(), "end_mrkr-img.png"), plot = FALSE, flim = flim, samp.rate = attr(X, "check.results")$sample.rate[1])
  
 
  # remove plots 
  nll <- try(dev.off(), silent = TRUE)
  
  # output wave object
  strt_mrkr <- tuneR::normalize(strt_mrkr)
  end_mrkr <- tuneR::normalize(end_mrkr)
  
  # amplify markers
  strt_mrkr@left <- strt_mrkr@left * amp.marker
  end_mrkr@left <- end_mrkr@left * amp.marker
  
  # save duration of markers for creating selection table
  dur_strt_mrkr <- seewave::duration(strt_mrkr)
  dur_end_mrkr <- seewave::duration(end_mrkr)
  
  # reset margins
  par(mar = c(5, 4, 4, 2) + 0.1)
  
  # add delay at the beggining
  if (delay > 0)
    strt_mrkr <- seewave::addsilw(strt_mrkr, d = delay, output = "Wave", at = "start")

  # add gap to start marker
  strt_mrkr <- seewave::addsilw(strt_mrkr, d = gap.duration, output = "Wave", at = "end")
      
  # add columns to attach durations
  X$pb.start <- NA
  
  # add start marker duration
  X$pb.start[1] <- seewave::duration(strt_mrkr)
  
  # read first selection
  plbck <- warbleR::read_wave(X, index = 1)
  
  # duration first selection
  dr1 <- seewave::duration(plbck)
  
  # add gap
  plbck <- seewave::addsilw(plbck, d = gap.duration, output = "Wave", at = "end")
  
  # normalize
  plbck <- tuneR::normalize(plbck)
  
  # add start marker
  plbck <- seewave::pastew(plbck, strt_mrkr, output =  "Wave")
  
  # add end column
  X$pb.end <- NA
  
  # add duration of first selection
  X$pb.end[1] <- X$pb.start[1] + dr1
  
  # concatenate all selection with a loop
  for(i in 2:nrow(X))
  {    
  # read waves  
  wv <- warbleR::read_wave(X, index = i)
  
  # save duration in sel tab
  X$pb.start[i] <- seewave::duration(plbck) 
  X$pb.end[i] <- seewave::duration(plbck) + seewave::duration(wv) 
  
  # add gaps
  wv <- seewave::addsilw(wv, d = gap.duration, output = "Wave", at = "end")
  
  # normalize
  wv <- tuneR::normalize(wv)
  
  # add to master playback
  plbck <- seewave::pastew(wv, plbck, output =  "Wave")
  }
  
  # add end marker 
  plbck <- seewave::pastew(end_mrkr, plbck, output =  "Wave")
  
  # normalize whole master playback
  plbck <- tuneR::normalize(plbck, unit = "16")
  
  # margin range for selections on markers
  mar.f <- (flim[2] - flim[1]) / 3

  # add .wav at the end of file.name if not included
  if(!grepl("\\.wav$", file.name, ignore.case = TRUE)) file.name <- paste0(file.name, ".wav")
  
  # create selection table
  sel.tab <- data.frame(
    sound.files = file.name, 
    selec =  1:(nrow(X) + 2), 
    start = c(delay, X$pb.start, X$pb.end[nrow(X)] + gap.duration), 
    end = c(delay + dur_strt_mrkr, X$pb.end, X$pb.end[nrow(X)] + gap.duration + dur_end_mrkr), 
    bottom.freq = c(flim[1] + mar.f, X$bottom.freq, flim[1] + mar.f), 
    top.freq = c(flim[2] - mar.f, X$top.freq, flim[2] - mar.f), 
    orig.sound.file = c("start_marker", X$sound.files, "end_marker"))

  
  # save master playback
  tuneR::writeWave(plbck, file.path(dest.path, file.name), extensible = FALSE)
  
  return(sel.tab)

}
