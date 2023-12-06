#' @export
spark_connect_method.spark_method_spark_connect <- function(
    x,
    method,
    master,
    spark_home,
    config = NULL,
    app_name,
    version = NULL,
    hadoop_version,
    extensions,
    scala_version,
    ...) {

  version <-  version %||% Sys.getenv("SPARK_VERSION")

  if (version == "") {
    cli_abort("Spark `version` is required, please provide")
  }

  args <- list(...)
  envname <- args$envname

  envname <- use_envname(
    method = method,
    version = version,
    envname = envname,
    messages = TRUE,
    match_first = TRUE
  )

  if (method == "spark_connect") {
    pyspark <- import_check("pyspark", envname)
    pyspark_sql <- pyspark$sql
    conn <- pyspark_sql$SparkSession$builder$remote(master)
    con_class <- "connect_spark"
    master_label <- glue("Spark Connect - {master}")
  }

  initialize_connection(
    conn = conn,
    master_label = master_label,
    con_class = con_class,
    cluster_id = NULL,
    method = method,
    config = config
  )
}

#' @export
spark_connect_method.spark_method_databricks_connect <- function(
    x,
    method,
    master,
    spark_home,
    config,
    app_name,
    version = NULL,
    hadoop_version,
    extensions,
    scala_version,
    ...) {
  args <- list(...)
  cluster_id <- args$cluster_id
  token <- args$token
  envname <- args$envname
  host_sanitize <- args$host_sanitize %||% TRUE

  method <- method[[1]]
  token <- databricks_token(token, fail = TRUE)
  cluster_id <- cluster_id %||% Sys.getenv("DATABRICKS_CLUSTER_ID")
  master <- databricks_host(master)
  if (host_sanitize) {
    master <- sanitize_host(master)
  }
  if (is.null(version) && !is.null(cluster_id)) {
    version <- databricks_dbr_version(
      cluster_id = cluster_id,
      host = master,
      token = token
    )
  }

  envname <- use_envname(
    method = method,
    version = version,
    envname = envname,
    messages = TRUE,
    match_first = TRUE
  )

  db <- import_check("databricks.connect", envname)
  remote <- db$DatabricksSession$builder$remote(
    host = master,
    token = token,
    cluster_id = cluster_id
  )
  user_agent <- build_user_agent()
  conn <- remote$userAgent(user_agent)
  con_class <- "connect_databricks"
  cluster_info <- databricks_dbr_info(cluster_id, master, token)
  cluster_name <- substr(cluster_info$cluster_name, 1, 100)
  master_label <- glue("{cluster_name} ({cluster_id})")
  initialize_connection(
    conn = conn,
    master_label = master_label,
    con_class = con_class,
    cluster_id = cluster_id,
    method = method,
    config = config
  )
}

initialize_connection <- function(
    conn,
    master_label,
    con_class,
    cluster_id = NULL,
    method = NULL,
    config = NULL) {
  warnings <- import("warnings")
  warnings$filterwarnings(
    "ignore",
    message = "is_datetime64tz_dtype is deprecated",
    module = "pyspark"
  )
  warnings$filterwarnings(
    "ignore",
    message = "is_categorical_dtype is deprecated",
    module = "pyspark"
  )

  session <- conn$getOrCreate()
  get_version <- try(session$version, silent = TRUE)
  if (inherits(get_version, "try-error")) databricks_dbr_error(get_version)
  session$conf$set("spark.sql.session.localRelationCacheThreshold", 1048576L)

  # do we need this `spark_context` object?
  spark_context <- list(spark_context = session)

  # browser()
  sc <- structure(
    list(
      master = master_label,
      cluster_id = cluster_id,
      config = config,
      method = method,
      session = session,
      state = spark_context,
      con = structure(list(), class = c("spark_connection", "DBIConnection"))
    ),
    class = c(con_class, "pyspark_connection", "spark_connection", "DBIConnection")
  )

  sc
}
setOldClass(
  c("Hive", "spark_connection")
)


setOldClass(
  c("connect_spark", "pyspark_connection", "spark_connection")
)

setOldClass(
  c("connect_databricks", "pyspark_connection", "spark_connection")
)

python_conn <- function(x) {
  py_object <- "python.builtin.object"
  ret <- NULL
  if (inherits(x$state$spark_context, py_object)) ret <- x$state$spark_context
  if (is.null(ret) && inherits(x[[1]]$session$sparkSession, py_object)) {
    ret <- x[[1]]$session$sparkSession
  }
  if (is.null(ret)) {
    cli_abort("Could not match Python Connection to: {class(x)}")
  }
  ret
}

build_user_agent <- function() {
  product <- NULL
  in_rstudio <- FALSE
  in_connect <- FALSE

  env_var <- Sys.getenv("SPARK_CONNECT_USER_AGENT", unset = NA)
  if (!is.na(env_var)) {
    return(env_var)
  }

  if (current_product_connect()) {
    product <- "posit-connect"
  }

  if (is.null(product)) {
    check_rstudio <- try(RStudio.Version(), silent = TRUE)
    if (!inherits(check_rstudio, "try-error")) {
      prod <- "rstudio"

      edition <- check_rstudio$edition
      if (length(edition) == 0) edition <- ""

      mod <- check_rstudio$mode
      if (length(mod) == 0) mod <- ""

      if (edition == "Professional") {
        if (mod == "server") {
          prod <- "workbench-rstudio"
        } else {
          prod <- "rstudio-pro"
        }
      }

      if (Sys.getenv("R_CONFIG_ACTIVE") == "rstudio_cloud") {
        prod <- "cloud-rstudio"
      }

      product <- glue("posit-{prod}/{check_rstudio$long_version}")
    }
  }

  glue(
    paste(
      "sparklyr/{packageVersion('sparklyr')}",
      product
    )
  )
}

connection_label <- function(x) {
  x <- x[[1]]
  ret <- "Connection"
  method <- NULL
  con <- spark_connection(x)
  if (is.null(con)) {
    method <- x
  } else {
    method <- con$method
  }
  if (!is.null(method)) {
    if (method == "spark_connect") ret <- "Spark Connect"
    if (method == "databricks_connect") ret <- "Databricks Connect"
  }
  ret
}