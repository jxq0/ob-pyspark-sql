(require 'org-macs)
(org-assert-version)

(require 'dash)
(require 'ob)
(require 'ob-python)

(defconst ob-pyspark-sql-main "
import os

def init_spark():
    from pyspark.sql import SparkSession
    from pyspark.sql import functions as F

    session = (
        SparkSession.builder.master('local[5]')
        .config('spark.driver.bindAddress', 'localhost')
        .getOrCreate()
    )

    return session


def read_csv(spark):
    for f in csv_files:
        file_path = f
        table_name = os.path.splitext(os.path.basename(f))[0]

        spark.read.csv(
            file_path,
            header=True,
            inferSchema=True,
        ).createOrReplaceTempView(table_name)

    if len(csv_files_map) % 2 != 0:
        raise ValueError('csv_files_map should be a list of pairs')

    it = iter(csv_files_map)
    for f in it:
        file_path = f
        table_name = next(it)
        spark.read.csv(
            file_path,
            header=True,
            inferSchema=True,
        ).createOrReplaceTempView(table_name)

def df_to_table(df):
    table = list()
    table.append(df.columns)
    table.append(None)

    for row in df.collect():
        table.append([row[col] for col in df.columns])

    return table

def run():
    spark = init_spark()
    read_csv(spark)

    return df_to_table(spark.sql(sql))


run()
")

(defcustom ob-pyspark-sql-main-file nil
  "The python code to run."
  :type 'string
  :group 'ob-pyspark-sql)

(defcustom ob-pyspark-sql-default-session "pyspark-sql"
  "The default python session."
  :type 'string
  :group 'ob-pyspark-sql)

(defun org-babel-execute:pyspark-sql (body params)
  (-let* (((&alist :csv_files :csv_files_map :session) params)
          (real-session (if (string= session "none")
                            ob-pyspark-sql-default-session
                          session))
          (new-params (append
                       (list (cons :var (cons 'sql body))
                             (cons :var (cons 'csv_files csv_files))
                             (cons :var (cons 'csv_files_map csv_files_map))
                             (cons :session real-session))
                       params))
          (main (if (and ob-pyspark-sql-main-file
                         (file-exists-p ob-pyspark-sql-main-file))
                    (with-temp-buffer
                      (insert-file-contents ob-pyspark-sql-main-file)
                      (buffer-string))
                  ob-pyspark-sql-main)))
    (message "%s" load-file-name)
    (org-babel-execute:python main new-params)))

(define-derived-mode pyspark-sql-mode
  sql-mode "pyspark-sql"
  "Major mode for pyspark sql.")

(provide 'ob-pyspark-sql)