CREATE EXTERNAL TABLE t(`a` string, `b` array<string>)
PARTITIONED BY (`p` string)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT 'x' OUTPUTFORMAT 'y'
LOCATION 's3://{{bucket}}/t/'
TBLPROPERTIES ('k'='v');