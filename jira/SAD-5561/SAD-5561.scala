import org.apache.hadoop.fs.{Path,FileSystem}

val javascriptInfoIndex = 37
val platformIndex = 38
val givtIndex = 80
val fraudScoresIndex = 95

val mobileAppPattern = """ mapp=1""".r

val HDFS_BASE = "/user/thresher/quality/logs"
val JIRA = "SAD-5561"
val YEAR = "2019"
val MONTH = "04"
var DAY = "01"
var HOUR = "12"

val fraudScoreKeys = List("sivt", "givta", "givtb", "givts", "givtc", "givtt")

def isDesktop(qlogFields : Array[String]) : Boolean = { 
    qlogFields(platformIndex) != "mob" && qlogFields(platformIndex) != "tab" 
}

def isMobileWeb(qlogFields:Array[String]) : Boolean = {
    ! isDesktop(qlogFields) && ! mobileAppPattern.findFirstIn(qlogFields(javascriptInfoIndex)).isDefined
}

def isMobileApp(qlogFields:Array[String]) : Boolean = {
    ! isDesktop(qlogFields) && mobileAppPattern.findFirstIn(qlogFields(javascriptInfoIndex)).isDefined
}

def isGivt(qlogFields:Array[String]) : Boolean = {
    qlogFields(givtIndex) == "1"
}

def scores2Dict(
    line : String
) : scala.collection.immutable.Map[String,String] = {
    if ( line.contains("=") ) {
        line.replaceAll("[{} ]","").split(",").map(_.split("=")).map(v => v(0) -> v(1)).toMap
    } else {
        scala.collection.immutable.Map[String,String]()
    }
}

def scoreCountsMapGenerator(line : String) : scala.collection.mutable.Map[String,Long] = {
    var scoreCounts : scala.collection.mutable.Map[String,Long] = scala.collection.mutable.Map()
    val chunks = line.split("\t")
    val fraudScores = scores2Dict(chunks(fraudScoresIndex))
 
    val desktopFlag = isDesktop(chunks)
    val mobileWebFlag = isMobileWeb(chunks)
    val mobileAppFlag = isMobileApp(chunks)

    scoreCounts += ("TOTAL" -> 1)
 
    scoreCounts += ("desktop" -> (if(desktopFlag) 1 else 0))
    scoreCounts += ("mobileWeb" -> (if(mobileWebFlag) 1 else 0))
    scoreCounts += ("mobileApp" -> (if(mobileAppFlag) 1 else 0))

    scoreCounts += ("sivt" -> (if(fraudScores.contains("sivt")) 1 else 0))
    scoreCounts += ("givt" -> (if(isGivt(chunks)) 1 else 0))

    fraudScoreKeys foreach { 
        key => {
            if (fraudScores.contains(key)) {
                scoreCounts += (s"${key}_desktop" -> (if (desktopFlag) 1 else 0))
                scoreCounts += (s"${key}_mobileWeb" -> (if (mobileWebFlag) 1 else 0))
                scoreCounts += (s"${key}_mobileApp" -> (if (mobileAppFlag) 1 else 0))
            }
        }
    }

    scoreCounts
}
 
def mapCountingReducer(
    countsThis:scala.collection.mutable.Map[String,Long]
    , countsThat:scala.collection.mutable.Map[String,Long]
) : scala.collection.mutable.Map[String,Long] = {
    (countsThis.keys ++ countsThat.keys) foreach {
        key => countsThis(key) = countsThis.getOrElse(key,0L).toLong + countsThat.getOrElse(key,0L).toLong
    }
    countsThis
}


for (day <- 1 to 30) {
    for (hour <- 0 to 23) {
        DAY = f"$day%02d"
        HOUR = f"$hour%02d"

        val INPUT = s"$HDFS_BASE/$YEAR/$MONTH/$DAY/$HOUR/impressions/*"
        val OUTPUT = s"${JIRA}.V2/$YEAR/$MONTH/$DAY/$HOUR"

        println(s"Looking at input from [$INPUT]")

        @transient val fs = FileSystem.get(sc.hadoopConfiguration)
        //FileSystem.get(sc.hadoopConfiguration).delete(new Path(OUTPUT), true)
        if ( fs.exists(new Path(OUTPUT) ) ) {
            println("\tAlready Exists. Skipping.")
        } else {
            println(s"Writing to [$OUTPUT]")
            val oneHourData = sc.textFile(INPUT).
                map(line => (s"$YEAR-$MONTH-$DAY-$HOUR", scoreCountsMapGenerator(line))).
                reduceByKey(mapCountingReducer(_,_)).
                toDF().
                write.
                json(OUTPUT)
        }
    }
}