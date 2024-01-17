import os


def init_spark():
    from pyspark.sql import SparkSession
    from pyspark.sql import functions as F

    session = (
        SparkSession.builder.master("local[5]")
        .config("spark.driver.bindAddress", "localhost")
        .getOrCreate()
    )

    return session


def read_files(spark):
    for f in csv_files:
        file_path = f
        table_name = os.path.splitext(os.path.basename(f))[0]
        file_extension = os.path.splitext(f)[1]

        reader = spark.read
        if file_extension == ".csv":
            reader.csv(
                file_path,
                header=True,
                inferSchema=True,
            ).createOrReplaceTempView(table_name)
        elif file_extension == ".json":
            reader.json(file_path, multiLine=True).createOrReplaceTempView(
                table_name
            )
        else:
            raise ValueError("Unknown file type")

    if len(csv_files_map) % 2 != 0:
        raise ValueError("csv_files_map should be a list of pairs")

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
    read_files(spark)

    return df_to_table(spark.sql(sql))


print("new")
run()
