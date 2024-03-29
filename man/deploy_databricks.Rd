% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/deploy.R
\name{deploy_databricks}
\alias{deploy_databricks}
\title{Deploys Databricks backed content to publishing server}
\usage{
deploy_databricks(
  appDir = NULL,
  python = NULL,
  account = NULL,
  server = NULL,
  lint = FALSE,
  forceGeneratePythonEnvironment = TRUE,
  version = NULL,
  cluster_id = NULL,
  host = NULL,
  token = NULL,
  confirm = interactive(),
  ...
)
}
\arguments{
\item{appDir}{A directory containing an application (e.g. a Shiny app or plumber API)
Defaults to NULL. If left NULL, and if called within RStudio, it will attempt
to use the folder of the currently opened document within the IDE. If there are
no opened documents, or not working in the RStudio IDE, then it will use
\code{getwd()} as the default value.}

\item{python}{Full path to a python binary for use by \code{reticulate.} It defaults to NULL.
If left NULL, this function will attempt to find a viable local Python
environment to replicate using the following hierarchy:
\enumerate{
\item \code{version} - Cluster's DBR version
\item \code{cluster_id} - Query the cluster to obtain its DBR version
\item If one is loaded in the current R session, it will verify that the Python
environment is suited to be used as the one to use
}}

\item{account}{The name of the account to use to publish}

\item{server}{The name of the target server to publish}

\item{lint}{Lint the project before initiating the project? Default to FALSE.
It has been causing issues for this type of content.}

\item{forceGeneratePythonEnvironment}{If an existing requirements.txt file is found,
it will be overwritten when this argument is TRUE.}

\item{version}{The Databricks Runtime (DBR) version. Use if \code{python} is NULL.}

\item{cluster_id}{The Databricks cluster ID. Use if \code{python}, and \code{version} are
NULL}

\item{host}{The Databricks host URL. Defaults to NULL. If left NULL, it will
use the environment variable \code{DATABRICKS_HOST}}

\item{token}{The Databricks authentication token. Defaults to NULL. If left NULL, it will
use the environment variable \code{DATABRICKS_TOKEN}}

\item{confirm}{Should the user be prompted to confirm that the correct
information is being used for deployment? Defaults to \code{interactive()}}

\item{...}{Additional named arguments passed to \code{rsconnect::deployApp()} function}
}
\value{
No value is returned to R. Only output to the console.
}
\description{
This is a convenience function that is meant to make it easier for
you to publish your Databricks backed content to a publishing server. It is
meant to be primarily used with Posit Connect.
}
