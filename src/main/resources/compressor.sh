#!/usr/bin/env bash

# defaults
QUEUE="default"
PROPERTIES_FILE='/etc/camus-compressor/camus-compressor.properties'
EXECUTORS=2
SPARK_MASTER='yarn'
SPARK_CONFIG=""
DRIVER_MEMORY="1g"
EXECUTOR_MEMORY="1g"
APP_NAME=""

function usage {
  echo "Usage: SPARK_SUBMIT=spark-submit2.3.0 compressor.sh [-a APP_NAME] [-n executor_memory] [-d driver_memory] [-c compression_format] [-e number_of_executors] [[-c conf]...] -P properties-file"
  echo "  Default queue is \"default\""
  echo "  Default number of executors is 2"
  echo "  Default driver memory is 1g"
  echo "  Default executor memory is 1g"
  echo "  Conf is passed as --conf to spark-submit, so you can use it multiple times:"
  echo "     - SPARK_SUBMIT=/usr/bin/spark-submit ./compressor.sh -c spark.executor.instances=10 -c spark.executor.memory=4g ..."
  echo "     - SPARK_SUBMIT=/usr/bin/spark-submit ./compressor.sh -c \"spark.executor.extraJavaOptions=-XX:+PrintGCDetails -XX:+PrintGCTimeStamps\" ..."
  echo "  Note that Camus Compressor requires Spark 1.6."
  echo "  You can set SPARK_SUBMIT as an environment variable: export SPARK_SUBMIT=/usr/bin/spark-submit. "
  echo "  If it is not set, /usr/bin/spark-submit1.6 is used."
  exit 1
}

if [ "$SPARK_SUBMIT" == "" ]; then
    SPARK_SUBMIT="spark-submit2.3.0"
fi

while getopts ":q:e:P:c:m:d:n:a:" opt; do
  case $opt in
    q)
      QUEUE=$OPTARG
      ;;
    e)
      EXECUTORS=$OPTARG
      ;;
    P)
      PROPERTIES_FILE="$OPTARG"
      ;;
    m)
      SPARK_MASTER="$OPTARG"
      ;;
    d)
      DRIVER_MEMORY="$OPTARG"
      ;;
    n)
      EXECUTOR_MEMORY="$OPTARG"
      ;;
    a)
      APP_NAME="--name $OPTARG"
      ;;
    c)
      SPARK_CONFIG="$SPARK_CONFIG --conf $OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      usage
      ;;
  esac
done

if [ ! -f "$PROPERTIES_FILE" ]; then
    "$PROPERTIES_FILE is not a regular file and cannot be used as Camus-compressor configuration"
    usage
    exit 1
fi

$SPARK_SUBMIT --properties-file $PROPERTIES_FILE \
  --class pl.allegro.tech.hadoop.compressor.Compressor \
  --queue $QUEUE \
  --driver-memory $DRIVER_MEMORY \
  --executor-memory $EXECUTOR_MEMORY \
  --master "$SPARK_MASTER" \
  --deploy-mode cluster \
  --num-executors $EXECUTORS \
  --conf spark.yarn.appMasterEnv.JAVA_HOME=/opt/jre1.8.0 \
  --conf spark.executorEnv.JAVA_HOME=/opt/jre1.8.0 \
  --conf spark.yarn.user.classpath.first=true \
  $APP_NAME \
  $SPARK_CONFIG \
  /usr/lib/hadoop-tools/camus-compressor/compressor.jar
