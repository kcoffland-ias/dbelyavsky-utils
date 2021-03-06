#!/bin/bash

#
# a script to ease the running of tests on Q2
#

NOTIFY_LIST="${USER}@integralads.com"
PROCESS_BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd | rev | cut -d'/' -f2- | rev )

[[ `hostname` = s-etl01* ]] && SOURCE_USER=etlstage || SOURCE_USER=thresher

function print_usage {
    cat - <<-EOU
    Usage: $0 -m -a [-i <JOBID>] [-d <YYYY-MM-DD>] [-h <HOUR>] [-f] [-q <QLOG_PATH>] [-j <JIRA>] [ -c [-u] [-o] ] [-r <URI>]
        -m  run the 'merge_and_score' phase
        -a  run the 'aggregate' phase
        -i  the JobID, format YYYYMMDDHH00, this over-writes DATE and HOUR options
        -d  date to run for, defaults to 'yesterday'
        -h  hour to run for, defaults to '12'
        -f  run for the full day (overrides -h)
        -q  supply an alternative path to the qlog intall dir, defaults to 'qlog' (i.e. will look for $HOME/qlog)
        -j  specify the JIRA which is being tested (for status emails), defaults to 'NOJIRA'
        -g  generate TODO files (overrides -c)
        -c  copy(download) the data into /user/$USER space before running Q2
            by default only the /user/$SOURCE_USER/status/ias/{mergeandscore|aggregate}/archive/* files are copied 
            to /user/$USER/status/ias/{mergeandscore|aggregate}/todo/
            -u  user data, actually copy the raw data into USER space
                this will re-create todo files to use /user/$USER/event and /user/$USER/dt/raw
            -o  overwrite existing, by default the script will check if the data exist before copying
        -r  when downloading data (including referential) use this namenode URI as source
EOU
}

while getopts 'i:d:h:cfq:j:maur:g' opt; do
    case $opt in
    i  ) JOBID=${OPTARG} ;;
    d  ) DATE=$(date --date "${OPTARG}" '+%Y-%m-%d') ;;
    h  ) HOUR=${OPTARG} ;;
    c  ) COPY_DATA=true ;;
    f  ) FULL_DAY=true ;;
    g  ) GENERATE_TODO=true ;;
    q  ) QLOG=${OPTARG} ;;
    j  ) JIRA=${OPTARG} ;;
    m  ) RUN_MERGE_AND_SCORE=true ;;
    a  ) RUN_AGGREGATE=true ;;
    u  ) USER_DATA=false ;;
    r  ) SRC_DATA_HOST=${OPTARG} ;;
    o  ) OVERWRITE=${OPTARG} ;;
    \? ) echo "Unknown option: -$OPTARG" >&2; print_usage; exit 1;;
    :  ) echo "Missing option argument for -$OPTARG" >&2; print_usage; exit 1;;
    *  ) echo "Unimplemented option: -$OPTARG" >&2; print_usage; exit 1;;
    esac
done


# set defaults for omitted params
: ${JOBID:=""}
: ${DATE:=$(date --date "yesterday" '+%Y-%m-%d')}
: ${HOUR:=12}
: ${COPY_DATA:=false}
: ${FULL_DAY:=false}
: ${GENERATE_TODO:=false}
: ${QLOG:=qlog}
: ${JIRA:=NOJIRA}
: ${RUN_MERGE_AND_SCORE:=false}
: ${RUN_AGGREGATE:=false}
: ${USER_DATA:=false}
: ${SRC_DATA_HOST:=""}
#: ${SRC_DATA_HOST:="hdfs://p-hdpnn02.nj01.303net.pvt"}
: ${OVERWRITE:=false}

[[ ${FULL_DAY} == true ]] && HOUR=00

[[ ${GENERATE_TODO} == true ]] && COPY_DATA=false

[[ "${COPY_DATA}" == "false" 
    && "${RUN_MERGE_AND_SCORE}" == "false" 
    && "${RUN_AGGREGATE}" == "false" 
    && "${GENERATE_TODO}" == "false" ]] && {
    print_usage
    echo "At least one of [-g|-c|-m|-a] must be specified"
    exit 0
}

[[ "${JOBID}" != "" ]] && {
    DATE=$(echo $JOBID | cut -c1-4,5-6,7-8 --output-delimiter='-')
    HOUR=$(echo $JOBID | cut -c9-10)
} || {
    JOBID=$(date --date "$DATE $HOUR:00" '+%Y%m%d%H00')   
}

ALL_PARAMS_STRING="
Processed Parameters\n
\tJOBID               = ${JOBID}\n
\tDATE                = ${DATE}\n
\tHOUR                = ${HOUR}\n
\tCOPY_DATA           = ${COPY_DATA}\n
\tFULL_DAY            = ${FULL_DAY}\n
\tGENERATE_TODO       = ${GENERATE_TODO}\n
\tQLOG                = ${QLOG}\n
\tJIRA                = ${JIRA}\n
\tRUN_MERGE_AND_SCORE = ${RUN_MERGE_AND_SCORE}\n
\tRUN_AGGREGATE       = ${RUN_AGGREGATE}\n
\tUSER_DATA           = ${USER_DATA}\n
\tSRC_DATA_HOST       = ${SRC_DATA_HOST}\n
\tOVERWRITE           = ${OVERWRITE}\n
"

echo -e ${ALL_PARAMS_STRING}

MY_PATH=$(dirname $0)
PREVDATE=$(date --date "$DATE -1 day" '+%Y-%m-%d')
NEXTDATE=$(date --date "$DATE +1 day" '+%Y-%m-%d')

DATEPATH=$(date --date "$DATE" '+%Y/%m/%d')
PREVDATEPATH=$(date --date "$PREVDATE" '+%Y/%m/%d')
NEXTDATEPATH=$(date --date "$NEXTDATE" '+%Y/%m/%d')

YESTERDAYPATH=$(date --date "-1 day" '+%Y/%m/%d')

DATESTAMP=$(date --date "$DATE" '+%Y%m%d')
PREVDATESTAMP=$(date --date "$PREVDATE" '+%Y%m%d')
NEXTDATESTAMP=$(date --date "$NEXTDATE" '+%Y%m%d')

DISTCP_CMD="hadoop distcp -D mapreduce.map.memory.mb=2024 -log /tmp/$0.distcp.${RANDOM}.log -m 600"
[[ "${OVERWRITE}" == "true" ]] && DISTCP_CMD+=" -overwrite "

SITELET_SCORING="sitelet_scoring"
INVISIBLE_FILE="${SITELET_SCORING}/conf/dev/invisible.txt"
echo "Looking for ${INVISIBLE_FILE}"
if [[ ! -f ${HOME}/${INVISIBLE_FILE} ]]; then
    for dirName in \
        "${HOME}/etlscripts/${SITELET_SCORING}" \
        "${HOME}/src/etlscripts/${SITELET_SCORING}"
    do
        echo "Trying ${dirName}"
        if [[ -d ${dirName} ]]; then
            echo "Found! Creating a symlink"
            ln -s ${dirName} ${HOME}/${SITELET_SCORING} 
            break
        fi
    done
fi

if [[ -f ${HOME}/${INVISIBLE_FILE} ]]; then
    echo "Confirmed: $(ls -l ${HOME}/${INVISIBLE_FILE})"
else
    echo "Could not locate ${INVISIBLE_FILE}"
    echo "You're going to have a bad time."
    echo "Bye"
    exit 1 
fi

PROCESS_FW_LOGS="process_fw_logs"
EVENT_AGG_CONF="${PROCESS_FW_LOGS}/conf/dev/EventAgg.base.conf"
echo "Looking for ${EVENT_AGG_CONF}"
for dirName in \
    "${HOME}" \
    "${HOME}/etlscripts" \
    "${HOME}/src/etlscripts" 
do
    echo "... in ${dirName}"
    if [[ -f $dirName/${EVENT_AGG_CONF} ]]; then
        cp $dirName/${EVENT_AGG_CONF} ${HOME}/${QLOG}/conf/dev
        break
    fi
done

if [[ ! -f ${HOME}/${QLOG}/conf/dev/EventAgg.base.conf ]]; then
    echo "Could not locate ${EVENT_AGG_CONF} and it isn't found in ${HOME}/${QLOG}/conf/dev"
    echo "You're going to have a bad time."
    echo "Bye"
    exit 1
fi

echo "Looking for $HOME/dev.inf"
[[ -f $HOME/dev.inf ]] && echo "OK!" || { 
    echo "Not Found!  (hint: look for in in etlscripts)" 
    exit 1
}

for fName in Q2_ms_conf.sh Q2_agg_conf.sh; do
    echo "Verify that the ${fName} startup scripts are present"
    if [[ ! -e ${HOME}/${QLOG}/bin/${fName} ]] ; then
        echo "  ${HOME}/${QLOG}/bin/${fName} not found.  Will create a symlink."
        [[ -e ${HOME}/${QLOG}/bin/Q2.sh ]] && ln -s ${HOME}/${QLOG}/bin/Q2.sh ${HOME}/${QLOG}/bin/${fName} || {
            echo "  ${HOME}/${QLOG}/bin/Q2.sh not found."
            exit 1
        }
    else
        echo "  ${HOME}/${QLOG}/bin/${fName} : OK"
    fi
done

echo "Creatting required dirs"
for d in status/ias/{aggregate,mergeandscore}/{todo,archive,in_progress}
do
    echo "    $d"
    hdfs dfs -mkdir -p $d
done

echo "Cleaning up any previous progress tracking"
hdfs dfs -rm -r -skipTrash -f \
	quality/progress/score/in_progress/* \
	quality/progress/distribute/{archive,in_progress,todo}/* \
	quality/progress/aggregate3/in_progress/*

# get the PLACEMENT data (this is static, only need to get it once)
echo "Refreshing quality/evidence/placement && quality/evidence/site_placement"
hdfs dfs -mkdir -p quality/evidence/placement quality/evidence/site_placement
hdfs dfs -test -e quality/evidence/placement/part-r-00000.gz \
    || hdfs dfs -cp -f /user/$SOURCE_USER/quality/evidence/placement/part-r-00000.gz quality/evidence/placement
hdfs dfs -test -e quality/evidence/site_placement/part-r-00000.gz \
    || hdfs dfs -cp -f /user/$SOURCE_USER/quality/evidence/site_placement/part-r-00000.gz quality/evidence/site_placement

# get the FRAUD EVIDENCE data
echo "Refreshing quality/evidence/fraud/${PREVDATEPATH}"
hdfs dfs -mkdir -p quality/evidence/fraud/${PREVDATEPATH} quality/evidence/fraud/${DATEPATH} quality/evidence/fraud/${YESTERDAYPATH}
hdfs dfs -test -e quality/evidence/fraud/${PREVDATEPATH}/* \
    || hdfs dfs -cp -f ${SRC_DATA_HOST}/user/$SOURCE_USER/quality/evidence/fraud/${PREVDATEPATH}/* quality/evidence/fraud/${PREVDATEPATH}
hdfs dfs -test -e quality/evidence/fraud/${DATEPATH}/* \
    || hdfs dfs -cp -f ${SRC_DATA_HOST}/user/$SOURCE_USER/quality/evidence/fraud/${DATEPATH}/* quality/evidence/fraud/${DATEPATH}
hdfs dfs -test -e quality/evidence/fraud/${YESTERDAYPATH}/* \
    || hdfs dfs -cp -f ${SRC_DATA_HOST}/user/$SOURCE_USER/quality/evidence/fraud/${YESTERDAYPATH}/* quality/evidence/fraud/${YESTERDAYPATH}

# get the INTENDED DURATION data
echo "Refreshing video/intended_duration/${PREVDATEPATH} && video/intended_duration_cm/${PREVDATEPATH}"
hdfs dfs -mkdir -p video/intended_duration/${PREVDATEPATH} video/intended_duration_cm/${PREVDATEPATH}
hdfs dfs -test -e video/intended_duration/${PREVDATEPATH}/* \
    || hdfs dfs -cp -f ${SRC_DATA_HOST}/user/$SOURCE_USER/video/intended_duration/${PREVDATEPATH}/* video/intended_duration/${PREVDATEPATH}
hdfs dfs -test -e video/intended_duration_cm/${PREVDATEPATH}/* \
    || hdfs dfs -cp -f ${SRC_DATA_HOST}/user/$SOURCE_USER/video/intended_duration_cm/${PREVDATEPATH}/* video/intended_duration_cm/${PREVDATEPATH}

[[ "${COPY_DATA}" == "true" ]] && {
if [[ "${USER_DATA}" == "true" ]];
then
        if [[ "${FULL_DAY}" == "true" ]]; 
        then
            echo "FULL_DAY=${FULL_DAY}"

            echo "STARTING COPY OF EVENT FOR ${DATEPATH}"
            hdfs dfs -test -e event/${DATEPATH} && echo "event/${DATEPATH} already exists"

            hdfs dfs -rm -skipTrash -f copy_files_list \
                && hdfs dfs -ls ${SRC_DATA_HOST}/user/$SOURCE_USER/event/${DATEPATH}/ \
                | grep -v ^Found | rev | cut -d'/' -f2 | rev | sort | uniq \
                | awk "{print \"${SRC_DATA_HOST}/user/$SOURCE_USER/event/\"\$1}" \
                | hdfs dfs -put - copy_files_list \
                && echo "Found source dirs" && hdfs dfs -text copy_files_list | sed 's/^/    /g' \
                && ${DISTCP_CMD} -f copy_files_list event/
            echo "FINISHED COPY OF EVENT FOR ${DATEPATH}"

            echo "STARTING COPY OF DT/RAW FOR ${DATEPATH}"
            hdfs dfs -test -e dt/raw/${DATEPATH} && echo "dt/raw/${DATEPATH} already exists"
            
            hdfs dfs -rm -skipTrash -f copy_files_list \
                && hdfs dfs -ls ${SRC_DATA_HOST}/user/$SOURCE_USER/dt/raw/${DATEPATH}/ \
                | grep -v ^Found | rev | cut -d'/' -f2 | rev | sort | uniq | uniq \
                | awk "{print \"${SRC_DATA_HOST}/user/$SOURCE_USER/dt/raw/\"\$1}" \
                | hdfs dfs -put - copy_files_list \
                && echo "Found source dirs" && hdfs dfs -text copy_files_list | sed 's/^/    /g' \
                && ${DISTCP_CMD} -f copy_files_list dt/raw/
            echo "FINISHED COPY OF DT/RAW FOR ${DATEPATH}"

            #### Set up todo ###################
            for hour in range -w 0 23; do
                echo "GENERATING TODO FOR ${DATEPATH}${hour}"
                SRC_PATH="/user/$SOURCE_USER/status/ias/mergeandscore/archive/${DATESTAMP}${hour}*"
                DEST_PATH="status/ias/mergeandscore/todo/"
                TMP_PATH=/tmp/todo.${RANDOM}
                hdfs dfs -rm -skipTrash ${DEST_PATH}/*
                hdfs dfs -text ${SRC_PATH} | sed 's/\/user\/$SOURCE_USER\///' > ${TMP_PATH}
                hdfs dfs -copyFromLocal ${TMP_PATH} ${DEST_PATH}
                rm -f ${TMP_PATH}
                echo "FINISHED GENERATING TODO FOR ${DATEPATH}${hour}"
            done
        else
            echo "FULL_DAY=${FULL_DAY}"
            # get the FW data
            echo "STARTING COPY OF EVENT FOR ${DATEPATH}, HOUR:${HOUR}"
            hdfs dfs -test -e event/${DATEPATH}/${HOUR} && echo "event/${DATEPATH}/${HOUR} already exists"
            hdfs dfs -mkdir -p event/${DATEPATH}/${HOUR}/00
            ${DISTCP_CMD} ${SRC_DATA_HOST}/user/$SOURCE_USER/event/${DATEPATH}/${HOUR}/00/* event/${DATEPATH}/${HOUR}/00/
            echo "FINISHED COPY OF EVENT FOR ${DATEPATH}/${HOUR}"

            # get the DT data
            echo "STARTING COPY OF DT/RAW FOR ${DATEPATH}, HOUR:${HOUR}"
            hdfs dfs -test -e dt/raw/${DATEPATH}/${HOUR} && echo "dt/raw/${DATEPATH}/${HOUR} already exists"
            hdfs dfs -mkdir -p dt/raw/${DATEPATH}/${HOUR}/00
            ${DISTCP_CMD} ${SRC_DATA_HOST}/user/$SOURCE_USER/dt/raw/${DATEPATH}/${HOUR}/00/* dt/raw/${DATEPATH}/${HOUR}/00/
            echo "FINISHED COPY OF DT/RAW FOR ${DATEPATH}/${HOUR}"

            #### Set up todo ###################
            echo "GENERATING TODO FOR ${DATEPATH}${HOUR}"
            SRC_PATH="/user/$SOURCE_USER/status/ias/mergeandscore/archive/${DATESTAMP}${HOUR}*"
            DEST_PATH="status/ias/mergeandscore/todo"
            TMP_PATH=/tmp/todo.${RANDOM}
            hdfs dfs -rm -skipTrash ${DEST_PATH}/*
            hdfs dfs -text ${SRC_PATH} | sed 's/\/user\/$SOURCE_USER\///' > ${TMP_PATH}
            hdfs dfs -copyFromLocal ${TMP_PATH} ${DEST_PATH}
            rm -f ${TMP_PATH}
            echo "FINISHED GENERATING TODO FOR ${DATEPATH}${HOUR}"
        fi
    else    # only copy the todo files
        echo "FULL_DAY=${FULL_DAY}"
        if [[ "${FULL_DAY}" == "true" ]]; 
        then
            echo "STARTING COPY OF TODO FOR ${DATEPATH}"
            [[ "${RUN_MERGE_AND_SCORE}" == "true" ]] && {
                SRC_PATH="/user/$SOURCE_USER/status/ias/mergeandscore/archive/${DATESTAMP}*"
                DEST_PATH="status/ias/mergeandscore/todo"
                hdfs dfs -test -e ${DEST_PATH}/${DATESTAMP}* && echo "${DEST_PATH}/${DATESTAMP}* already exists"
                ${DISTCP_CMD} ${SRC_PATH} ${DEST_PATH}
            }
            [[ "${RUN_AGGREGATE}" == "true" && "${RUN_MERGE_AND_SCORE}" != "true" ]] && {
                SRC_PATH="/user/$SOURCE_USER/status/ias/aggregate/archive/${DATESTAMP}*"
                DEST_PATH="status/ias/aggregate/todo"
                hdfs dfs -test -e ${DEST_PATH}/${DATESTAMP}* && echo "${DEST_PATH}/${DATESTAMP}* already exists"
                ${DISTCP_CMD} ${SRC_PATH} ${DEST_PATH}
            }
        else
            echo "STARTING COPY OF TODO FOR ${DATESTAMP}${HOUR}"
            [[ "${RUN_MERGE_AND_SCORE}" == "true" ]] && {
                SRC_PATH="/user/$SOURCE_USER/status/ias/mergeandscore/archive/${DATESTAMP}${HOUR}*"
                DEST_PATH="status/ias/mergeandscore/todo"
                hdfs dfs -test -e ${DEST_PATH}/${DATESTAMP}${HOUR}* && echo "${DEST_PATH}/${DATESTAMP}${HOUR}* already exists"
                #${DISTCP_CMD} ${SRC_PATH} ${DEST_PATH}
                hdfs dfs -cp ${SRC_PATH} ${DEST_PATH}
            }
            [[ "${RUN_AGGREGATE}" == "true" && "${RUN_MERGE_AND_SCORE}" != "true" ]] && {
                SRC_PATH="/user/$SOURCE_USER/status/ias/aggregate/archive/${DATESTAMP}${HOUR}*"
                DEST_PATH="status/ias/aggregate/todo"
                hdfs dfs -test -e ${DEST_PATH}/${DATESTAMP}${HOUR}* && echo "${DEST_PATH}/${DATESTAMP}${HOUR}* already exists."
                ${DISTCP_CMD} ${SRC_PATH} ${DEST_PATH}
            }
        fi
        echo "FINISHED COPY OF TODO FOR ${DATEPATH}"
    fi
}

#### RUN Q2 !!!!!!!
[[ "${RUN_MERGE_AND_SCORE}" == "true" ]] && {
    [[ ${GENERATE_TODO} == "true" ]] && {
        echo "Generating todo files:"

        tmpDir=/tmp/todo.${RANDOM}
        mkdir -p ${tmpDir}

        targetTodoDir='status/ias/mergeandscore/todo'

        RANGE=${HOUR}
        [[ ${FULL_DAY} == true ]] && RANGE=$(seq -w 0 23)

        for hour in ${RANGE}; do
            _DATE=$(date --date "${DATE} ${hour}:00")
            dateTime=$(date --date "${_DATE}" '+%Y%m%d%H00')
            dateTimePath=$(date --date "${_DATE}" '+%Y/%m/%d/%H/00')
            dateTimeMinusOneHour=$(date --date "$_DATE -1 hour" '+%Y%m%d%H00')
            dateTimeMinusOneHourPath=$(date --date "$_DATE -1 hour" '+%Y/%m/%d/%H/00')
            dateTimePlusOneHour=$(date --date "$_DATE +1 hour" '+%Y%m%d%H00')
            dateTimePlusOneHourPath=$(date --date "$_DATE +1 hour" '+%Y/%m/%d/%H/00')

            flagFileName=${dateTime}
            echo "    [${flagFileName}]"

            flagFileText=""
            flagFileText+="--inputdir=/user/$SOURCE_USER/merged/${dateTimeMinusOneHourPath}"
            flagFileText+=",/user/$SOURCE_USER/merged/${dateTimePath}"
            flagFileText+=",/user/$SOURCE_USER/dt/raw/${dateTimeMinusOneHourPath}"
            flagFileText+=",/user/$SOURCE_USER/dt/raw/${dateTimePath}"
            flagFileText+=",/user/$SOURCE_USER/dt/raw/${dateTimePlusOneHourPath}"
            flagFileText+=" --start=${dateTime} --end=${dateTimePlusOneHour}"

            echo ${flagFileText} > ${tmpDir}/${flagFileName}
        done

        hdfs dfs -copyFromLocal ${tmpDir}/* ${targetTodoDir}
    }

    hdfs dfs -rm -f -skipTrash status/ias/aggregate/todo/* \
        status/ias/mergeandscore/{in_progress,archive}/${DATESTAMP}${HOUR}*

    CMD_MERGE_AND_SCORE="${HOME}/${QLOG}/bin/pyrun.sh q2_merge_and_score.py --config ${HOME}/${QLOG}/conf/dev/q2_merge_and_score.json"
    echo "${CMD_MERGE_AND_SCORE}"
    echo $(${CMD_MERGE_AND_SCORE})

    # backup the log file
    LOGFILE=${HOME}/log/q2_merge_and_score_$(date +%Y%m).log
    LOGFILE_NEW=${LOGFILE}.${JIRA}
    [[ -f ${LOGFILE_NEW} ]] && {
        mv ${LOGFILE_NEW} ${LOGFILE_NEW}.$(date +%Y%m%d%H%M%S)
    }
    mv ${LOGFILE} ${LOGFILE_NEW}

    # capture stats
    MERGE_AND_SCORE_STATS=$(tail ${LOGFILE_NEW})
    MERGE_AND_SCORE_STATS+=$(echo "")
    MERGE_AND_SCORE_STATS+=$(${MY_PATH}/getStats.sh ${LOGFILE_NEW})
    MERGE_AND_SCORE_STATS+=$(echo "")
}

[[ "${RUN_AGGREGATE}" == "true" ]] && {
    hdfs dfs -rm -f -skipTrash \
        status/ias/aggregate_consumer_status_dir/todo/${DATESTAMP}${HOUR}* \
        status/ias/aggregate/{in_progess,archive}/${DATESTAMP}${HOUR}*


    CMD_AGGREGATE="${HOME}/${QLOG}/bin/pyrun.sh q2_aggregate.py --ds-agg --force --config ${HOME}/${QLOG}/conf/dev/q2_aggregate.json"
    echo "${CMD_AGGREGATE}"
    echo $(${CMD_AGGREGATE})

    # backup the log file
    LOGFILE=${HOME}/log/q2_aggregate_$(date +%Y%m).log
    LOGFILE_NEW=${LOGFILE}.${JIRA}
    [[ -f ${LOGFILE_NEW} ]] && {
        mv ${LOGFILE_NEW} ${LOGFILE_NEW}.$(date +%Y%m%d%H%M%S)
    }
    mv ${LOGFILE} ${LOGFILE_NEW}

    # capture stats
    AGGREGATE_STATS=$(tail ${LOGFILE_NEW})
    AGGREGATE_STATS+=$(echo "")
    AGGREGATE_STATS+=$(${MY_PATH}/getStats.sh ${LOGFILE_NEW})
    AGGREGATE_STATS+=$(echo "")
}
#### FINISHED Q2 !!!!!!

# send completion notification with some stats
mail -s "Q2 completed under ${USER}@${HOSTNAME}, for ${JIRA}" ${NOTIFY_LIST} << EOM
    * Q2 completed under ${USER}@${HOSTNAME} 
    * $(echo -e ${ALL_PARAMS_STRING})

    ------------------- Merge And Score --------------------

    ${MERGE_AND_SCORE_STATS:-Did not run}

    ------------------- Aggregate --------------------------

    ${AGGREGATE_STATS:-Did not run}

    --------------------------------------------------------

    script: ${0}
EOM
