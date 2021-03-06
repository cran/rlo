#' Start libreoffice writer
#'
#' This functions starts libreoffice, if it is in the PATH on POSIX systems
#' (tested only on Linux). On Windows, consider using a shortcut 
#' including \dQuote{-accept=socket,host=localhost,port=8100;urp;}.
#'
#' @importFrom PythonInR pyExec
#' @param file The file to create/open
#' @param title The title of the document
#' @param dir The directory to write the file to
#' @param template The template file if to be used
#' @param open Should file be opened if it already exists?
#' @param overwrite Should file be overwritten if it already exists?
#' @param sleep_time The time to sleep after starting LibreOffice before
#'   trying to connect
#' @export
rlo_start <- function(file = NULL, title = NULL,
                      dir = ".", template = NULL,
                      open = !is.null(file), overwrite = FALSE,
                      sleep_time = 2)
{
  if (.Platform$OS.type == "windows") {
    stop("Consider using a shortcut including \"-accept=socket,host=localhost,port=8100;urp;\"",
      "to start LibreOffice on Windows")
  }
  # Start libreoffice listening to port 8100 on localhost
  # Use 'soffice' as that is how the executable is called on windows
  command = "soffice --accept='socket,host=localhost,port=8100;urp;'"

  if (!is.null(file)) {
    if (open) {
      if (file.access(file, mode = 4) == 0) {
        command = paste(command, file)
      } else {
        stop("File ", file, " is not readable")
      }
    } else {
      if (is.null(template)) {
        command = paste(command, "--writer")
      } else {
        if (file.access(template, mode = 4) == 0) {
          tmp = tempfile(fileext = ".odt")
          file.copy(template, tmp)
          command = paste(command, tmp)
        } else {
          stop("Template ", template, " is not readable")
        }
      }
    }
  }

  # Start libreoffice
  system(command, wait = FALSE)
  Sys.sleep(sleep_time)

  # Get UNO objects
  rlo_connect()

  # Set the title if requested
  if (!is.null(title)) {
    pyExec(paste0("doc.DocumentProperties.Title = '", title, "'"))
  }

 # Stop if file exists unless overwrite is TRUE
  if (!is.null(file)) {
    if (file.exists(file) & overwrite == FALSE ) {
      warning("Not saving, ", file, " exists")
    } else {
      file_url = paste0("file://", file.path(normalizePath(dir), file))
      message("Saved to ", file_url)
      rlo_dispatch(".uno:SaveAs",
        list(URL = file_url, FilterName = "writer8"))
    }
  }
}

#' Create a new libreoffice writer document
#' 
#' @inheritParams rlo_start
#' @rdname rlo_start
#' @export
rlo_new <- function(file, title = NULL, dir = ".", template = NULL,
        overwrite = FALSE, sleep_time = 2)
{
  rlo_start(file = file, title = title,
            dir = dir, template = template,
            open = FALSE, overwrite = overwrite,
            sleep_time = 1)
}
