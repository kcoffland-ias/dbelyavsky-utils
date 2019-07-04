SELECT
    SUM(grossImps) AS grossImps,
    SUM(totalEligibleForBrandSafety) as totalEligibleForBrandSafety,
    CAST(SUM(passedImps) AS SIGNED) AS passedImps,
    ROUND(100 * SUM(passedImps) / SUM(totalEligibleForBrandSafety), 2) AS passedPct,
    CAST(SUM(totalNetEligibleImps) AS SIGNED) AS totalNetEligibleImps,
    CAST(SUM(totalNetMeasuredImps) AS SIGNED) AS totalNetMeasuredImps,
    ROUND(100 * SUM(totalNetMeasuredImps) / SUM(totalNetEligibleImps), 2) AS totalNetMeasuredPct,
    SUM(totalNetInViewImps) AS totalNetInViewImps,
    ROUND(100 * SUM(totalNetInViewImps) / SUM(totalNetMeasuredImps), 2) AS totalNetInViewPct,
    SUM(fraudulentImps) AS fraudulentImps,
    ROUND(100 * SUM(fraudulentImps) / SUM(grossImps), 2) AS fraudulentPct
    , THIS_PERIOD.campaignId,THIS_PERIOD.campaignName,THIS_PERIOD.publisherId,THIS_PERIOD.publisherName,THIS_PERIOD.hitDate
     , SUM(customMetricsId2_totalNetInViewImps) AS customMetricsId2_totalNetInViewImps,
    ROUND(100 * SUM(customMetricsId2_totalNetInViewImps) / SUM(totalNetMeasuredImps), 2) AS customMetricsId2_totalNetInViewPct
     ,   IF(THIS_PERIOD.minDate >= '2016-09-16',
        (
        THIS_PERIOD.grossBillableImps  +
        ROUND(
        IF(THIS_PERIOD.regularVIDEOInViewImps+THIS_PERIOD.regularVIDEOOutOfViewImps > 0,
            (THIS_PERIOD.regularInViewGt2qUnblockedImps100)/(THIS_PERIOD.regularVIDEOInViewImps+THIS_PERIOD.regularVIDEOOutOfViewImps)*(THIS_PERIOD.regularVIDEOUnblockedImps-THIS_PERIOD.regularVIDEOSuspiciousImps),
            0)
        +
        IF(THIS_PERIOD.parentVIDEOInViewImps+THIS_PERIOD.parentVIDEOOutOfViewImps > 0,
           (THIS_PERIOD.parentInViewGt2qUnblockedImps100)/(THIS_PERIOD.parentVIDEOInViewImps+THIS_PERIOD.parentVIDEOOutOfViewImps)*(THIS_PERIOD.parentVIDEOUnblockedImps + THIS_PERIOD.childVIDEOUnblockedImps - THIS_PERIOD.parentVIDEOSuspiciousImps - THIS_PERIOD.childVIDEOSuspiciousImps),
           0)
          )
        )
        ,

        ROUND(
        IF(THIS_PERIOD.regularInViewImps+THIS_PERIOD.regularOutOfViewImps > 0,
            (THIS_PERIOD.regularInViewGt2qUnblockedImps100+THIS_PERIOD.regularEstimatedDisplayBillableImps+THIS_PERIOD.regularRawBillableDisplayImps)/(THIS_PERIOD.regularInViewImps+THIS_PERIOD.regularOutOfViewImps)*(THIS_PERIOD.regularUnblockedImps-THIS_PERIOD.regularSuspiciousImps),
            0)
        +
        IF(THIS_PERIOD.parentInViewImps+THIS_PERIOD.parentOutOfViewImps > 0,
           (THIS_PERIOD.parentInViewGt2qUnblockedImps100+THIS_PERIOD.parentEstimatedDisplayBillableImps+THIS_PERIOD.parentRawBillableDisplayImps)/(THIS_PERIOD.parentInViewImps+THIS_PERIOD.parentOutOfViewImps)*(THIS_PERIOD.parentUnblockedImps + THIS_PERIOD.childUnblockedImps - THIS_PERIOD.parentSuspiciousImps - THIS_PERIOD.childSuspiciousImps),
           0)
        )
      ) AS customMetricsId2_totalBillableImpressions
FROM
(
        SELECT
            totalNetEligibleImps,
            totalNetMeasuredImps,
            totalNetInViewImps,
            grossImps,
            totalEligibleForBrandSafety,
            passedImps,
            fraudulentImps
                ,
                customMetricsId2_totalNetInViewImps,
                customMetricsId2_totalNetInViewPct
                    ,
                    trueViewViewableImps,
                    trueViewViewablePct,
                    trueViewMeasurableImps,
                    trueViewMeasurablePct,
                    minDate,
                    grossBillableImps,
                    regularUnblockedImps,
                    parentUnblockedImps,
                    childUnblockedImps,
                    regularSuspiciousImps,
                    parentSuspiciousImps,
                    childSuspiciousImps,
                    regularInViewImps,
                    regularOutOfViewImps,
                    parentInViewImps,
                    parentOutOfViewImps,
                    regularInViewGt2qUnblockedImps100,
                    regularRawBillableDisplayImps,
                    regularEstimatedDisplayBillableImps,
                    parentInViewGt2qUnblockedImps100,
                    parentRawBillableDisplayImps,
                    parentEstimatedDisplayBillableImps,
                    regularVIDEOUnblockedImps,
                    parentVIDEOUnblockedImps,
                    childVIDEOUnblockedImps,
                    regularVIDEOSuspiciousImps,
                    parentVIDEOSuspiciousImps,
                    childVIDEOSuspiciousImps,
                    regularVIDEOInViewImps,
                    regularVIDEOOutOfViewImps,
                    parentVIDEOInViewImps,
                    parentVIDEOOutOfViewImps

            , FRAUD.campaignId,FRAUD.campaignName,FRAUD.publisherId,FRAUD.publisherName,FRAUD.hitDate
        FROM
        (
            SELECT
                FLOOR(SUM(COALESCE(PASSED_IMPS, IMPS) + COALESCE(FLAGGED_IMPS, 0) - COALESCE(SUSPICIOUS_PASSED_IMPS, SUSPICIOUS_IMPS) - COALESCE(SUSPICIOUS_FLAGGED_IMPS, 0))) AS totalNetEligibleImps,
                CAST((FLOOR(SUM(
                    IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                        IF(Q_DATA_IMPS > IMPS, ((COALESCE(IN_VIEW_PASSED_IMPS, 0) + COALESCE(IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(IN_VIEW_PASSED_IMPS ,0) + COALESCE(IN_VIEW_FLAGGED_IMPS ,0))
                        ,
                        FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS
                    )
                )) + FLOOR(SUM(
                    IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                        IF(Q_DATA_IMPS > IMPS, ((COALESCE(NOT_IN_VIEW_PASSED_IMPS ,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(NOT_IN_VIEW_PASSED_IMPS, 0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0))
                        ,
                        0
                    )
                ))) AS SIGNED) AS totalNetMeasuredImps,
                FLOOR(SUM(IF(Q_DATA_IMPS > IMPS, ((COALESCE(IN_VIEW_PASSED_IMPS, 0) + COALESCE(IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(IN_VIEW_PASSED_IMPS ,0) + COALESCE(IN_VIEW_FLAGGED_IMPS ,0)))) AS totalNetInViewImps
                 , CAST(
                    SUM(
                      IF (MCM_1_SRC = 2
                      	,
                            ROUND( MCM_1_NON_SUSPICIOUS_IMPS * ( IF(Q_DATA_IMPS > IMPS,
                        (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                        * IMPS / Q_DATA_IMPS
                        ,
                        (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                      )
                    ) / IMPS )
                        , 0
                      )
                    ) AS SIGNED) AS customMetricsId2_totalNetInViewImps,
                    ROUND(100 * CAST(
                SUM(
                  IF (MCM_1_SRC = 2
                  	,
                        ROUND( MCM_1_NON_SUSPICIOUS_IMPS * ( IF(Q_DATA_IMPS > IMPS,
                    (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                    * IMPS / Q_DATA_IMPS
                    ,
                    (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                  )
                ) / IMPS )
                    , 0
                  )
                ) AS SIGNED) / CAST((FLOOR(SUM(
                    IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                        IF(Q_DATA_IMPS > IMPS, ((COALESCE(IN_VIEW_PASSED_IMPS, 0) + COALESCE(IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(IN_VIEW_PASSED_IMPS ,0) + COALESCE(IN_VIEW_FLAGGED_IMPS ,0))
                        ,
                        FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS
                    )
                )) + FLOOR(SUM(
                    IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                        IF(Q_DATA_IMPS > IMPS, ((COALESCE(NOT_IN_VIEW_PASSED_IMPS ,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(NOT_IN_VIEW_PASSED_IMPS, 0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0))
                        ,
                        0
                    )
                ))) AS SIGNED), 2) AS customMetricsId2_totalNetInViewPct
                 , NULL AS trueViewViewableImps,
                    NULL AS trueViewViewablePct,
                    NULL AS trueViewMeasurableImps,
                    NULL AS trueViewMeasurablePct
                 ,         MIN(HIT_DATE) as minDate,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) , GROSS_BILLABLE_DISPLAY_IMPS, 0))  as grossBillableImps,

                        SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, PASSED_IMPS+FLAGGED_IMPS, 0))  as regularUnblockedImps,
                        SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, PASSED_IMPS+FLAGGED_IMPS, 0))  as parentUnblockedImps,
                        SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 3, PASSED_IMPS+FLAGGED_IMPS, 0))  as childUnblockedImps,
                        SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as regularSuspiciousImps,
                        SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as parentSuspiciousImps,
                        SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 3, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as childSuspiciousImps,
                        ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as regularInViewImps,
                        ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as regularOutOfViewImps,
                        ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as parentInViewImps,
                        ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as parentOutOfViewImps,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, FULLY_IN_VIEW_THRU_2D_IMPS, 0))  as regularInViewGt2qUnblockedImps100,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NOT NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 1, BILLABLE_DISPLAY_IMPS, 0))  as regularRawBillableDisplayImps,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 1, FULLY_IN_VIEW_0S_PASSED_IMPS+FULLY_IN_VIEW_0S_FLAGGED_IMPS, 0))  as regularEstimatedDisplayBillableImps,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, FULLY_IN_VIEW_THRU_2D_IMPS, 0))  as parentInViewGt2qUnblockedImps100,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NOT NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 2, BILLABLE_DISPLAY_IMPS, 0))  as parentRawBillableDisplayImps,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 2, FULLY_IN_VIEW_0S_PASSED_IMPS+FULLY_IN_VIEW_0S_FLAGGED_IMPS, 0))  as parentEstimatedDisplayBillableImps,

                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, COALESCE(PASSED_IMPS, IMPS)+COALESCE(FLAGGED_IMPS,0), 0))  as regularVIDEOUnblockedImps,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, PASSED_IMPS+FLAGGED_IMPS, 0))  as parentVIDEOUnblockedImps,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 3, PASSED_IMPS+FLAGGED_IMPS, 0))  as childVIDEOUnblockedImps,

                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, COALESCE(SUSPICIOUS_PASSED_IMPS, SUSPICIOUS_IMPS)+COALESCE(SUSPICIOUS_FLAGGED_IMPS,0), 0))  as regularVIDEOSuspiciousImps,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as parentVIDEOSuspiciousImps,
                        SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 3, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as childVIDEOSuspiciousImps,

                        ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as regularVIDEOInViewImps,
                        ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as regularVIDEOOutOfViewImps,
                        ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as parentVIDEOInViewImps,
                        ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as parentVIDEOOutOfViewImps
                , CAMPAIGN_ID as campaignId, CAMPAIGN_NAME as campaignName,PUBLISHER_ID as publisherId, PUBLISHER_NAME as publisherName,HIT_DATE as hitDate
            FROM
                (
                SELECT
                    'IAS' AS MEASUREMENT_SOURCE_TYPE,
                    MEDIA_TYPE_ID,
                    IMPS,
                    Q_DATA_IMPS,
                    SUSPICIOUS_IMPS,
                    COALESCE(PASSED_IMPS, 0) AS PASSED_IMPS,
                    COALESCE(FLAGGED_IMPS, 0) AS FLAGGED_IMPS,
                    COALESCE(SUSPICIOUS_PASSED_IMPS, 0) AS SUSPICIOUS_PASSED_IMPS,
                    COALESCE(SUSPICIOUS_FLAGGED_IMPS, 0) AS SUSPICIOUS_FLAGGED_IMPS,
                    IN_VIEW_PASSED_IMPS,
                    IN_VIEW_FLAGGED_IMPS,
                    NOT_IN_VIEW_PASSED_IMPS,
                    NOT_IN_VIEW_FLAGGED_IMPS

                     , AGG_AGENCY_QUALITY_V3.MCM_1_SRC,
                    AGG_AGENCY_QUALITY_V3.MCM_1_NON_SUSPICIOUS_IMPS,
                    NULL AS TRUE_VIEW_VIEWABLE_IMPS,
                    NULL AS TRUE_VIEW_MEASURABLE_IMPS,
                    NULL AS FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS
                        , AGG_AGENCY_QUALITY_V3.GROSS_BILLABLE_DISPLAY_IMPS
                        , AGG_AGENCY_QUALITY_V3.BILLABLE_DISPLAY_IMPS
                        , AGG_AGENCY_QUALITY_V3.FULLY_IN_VIEW_0S_PASSED_IMPS
                        , AGG_AGENCY_QUALITY_V3.FULLY_IN_VIEW_0S_FLAGGED_IMPS
                        , AGG_AGENCY_QUALITY_V3.ROADBLOCK_STATUS
                        , AGG_AGENCY_QUALITY_V3.FULLY_IN_VIEW_THRU_2D_IMPS

                    , CAMPAIGN_ID, CAMPAIGN_NAME,PUBLISHER_ID, PUBLISHER_NAME,HIT_DATE
                FROM
                    AGG_AGENCY_QUALITY_V3
                WHERE
                    (HIT_DATE >= '2018-01-16' AND HIT_DATE <= '2018-01-22')
                    AND ( CAMPAIGN_ID IN (SELECT CAMPAIGN_ID FROM ADV_ENTITY WHERE TEAM_ID IN (94)) AND CAMPAIGN_ID > 0  AND CAMPAIGN_ID IN (123966,121966,122253,119247,119246,127649,122254,121028,123421,123423,119235,122244,119233,119242,122796,122243,122349,128039,122352,127171,122350,122250,122251,104908,123109,61243)  )
                ) AGG_AGENCY_QUALITY_V3
            GROUP BY CAMPAIGN_ID,PUBLISHER_ID,HIT_DATE
        ) VIEWABILITY
        LEFT JOIN
        (
            SELECT
                SUM(IF(GROSS_IMPS=0, IMPS, GROSS_IMPS)) AS grossImps,
                SUM(IF(GROSS_IMPS=0, IMPS, GROSS_IMPS)) AS totalEligibleForBrandSafety,
                SUM(PASSED_IMPS) AS passedImps,
                (SUM(SIVT_IMPS) + COALESCE(SUM(GIVT_IMPS), 0)) AS fraudulentImps
                , CAMPAIGN_ID as campaignId, CAMPAIGN_NAME as campaignName,PUBLISHER_ID as publisherId, PUBLISHER_NAME as publisherName,HIT_DATE as hitDate
            FROM
                AGG_AGENCY_FRAUD
            WHERE
                (HIT_DATE >= '2018-01-16' AND HIT_DATE <= '2018-01-22')
                AND ( CAMPAIGN_ID IN (SELECT CAMPAIGN_ID FROM ADV_ENTITY WHERE TEAM_ID IN (94)) AND CAMPAIGN_ID > 0  AND CAMPAIGN_ID IN (123966,121966,122253,119247,119246,127649,122254,121028,123421,123423,119235,122244,119233,119242,122796,122243,122349,128039,122352,127171,122350,122250,122251,104908,123109,61243)  )
            GROUP BY CAMPAIGN_ID,PUBLISHER_ID,HIT_DATE
        ) FRAUD ON VIEWABILITY.campaignId=FRAUD.campaignId AND VIEWABILITY.publisherId=FRAUD.publisherId

        UNION ALL

        SELECT
            FLOOR(SUM(COALESCE(PASSED_IMPS, IMPS) + COALESCE(FLAGGED_IMPS, 0) - COALESCE(SUSPICIOUS_PASSED_IMPS, SUSPICIOUS_IMPS) - COALESCE(SUSPICIOUS_FLAGGED_IMPS, 0))) AS totalNetEligibleImps,
            CAST((FLOOR(SUM(
                IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                    IF(Q_DATA_IMPS > IMPS, ((COALESCE(IN_VIEW_PASSED_IMPS, 0) + COALESCE(IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(IN_VIEW_PASSED_IMPS ,0) + COALESCE(IN_VIEW_FLAGGED_IMPS ,0))
                    ,
                    FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS
                )
            )) + FLOOR(SUM(
                IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                    IF(Q_DATA_IMPS > IMPS, ((COALESCE(NOT_IN_VIEW_PASSED_IMPS ,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(NOT_IN_VIEW_PASSED_IMPS, 0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0))
                    ,
                    0
                )
            ))) AS SIGNED) AS totalNetMeasuredImps,
            FLOOR(SUM(IF(Q_DATA_IMPS > IMPS, ((COALESCE(IN_VIEW_PASSED_IMPS, 0) + COALESCE(IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(IN_VIEW_PASSED_IMPS ,0) + COALESCE(IN_VIEW_FLAGGED_IMPS ,0)))) AS totalNetInViewImps,
            SUM(IF(GROSS_IMPS=0, IMPS, GROSS_IMPS)) AS grossImps,
            0 AS totalEligibleForBrandSafety,
            SUM(PASSED_IMPS) AS passedImps,
            (SUM(SIVT_IMPS) + COALESCE(SUM(GIVT_IMPS), 0)) AS fraudulentImps
             , CAST(
                SUM(
                  IF (MCM_1_SRC = 2
                  	,  IF(MEASUREMENT_SOURCE_TYPE = 'PMI', MCM_1_NON_SUSPICIOUS_IMPS,
                        ROUND( MCM_1_NON_SUSPICIOUS_IMPS * ( IF(Q_DATA_IMPS > IMPS,
                    (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                    * IMPS / Q_DATA_IMPS
                    ,
                    (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                  )
                ) / IMPS )
                       )
                    , 0
                  )
                ) AS SIGNED) AS customMetricsId2_totalNetInViewImps,
                ROUND(100 * CAST(
            SUM(
              IF (MCM_1_SRC = 2
              	,  IF(MEASUREMENT_SOURCE_TYPE = 'PMI', MCM_1_NON_SUSPICIOUS_IMPS,
                    ROUND( MCM_1_NON_SUSPICIOUS_IMPS * ( IF(Q_DATA_IMPS > IMPS,
                (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                * IMPS / Q_DATA_IMPS
                ,
                (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
              )
            ) / IMPS )
                   )
                , 0
              )
            ) AS SIGNED) / CAST((FLOOR(SUM(
                IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                    IF(Q_DATA_IMPS > IMPS, ((COALESCE(IN_VIEW_PASSED_IMPS, 0) + COALESCE(IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(IN_VIEW_PASSED_IMPS ,0) + COALESCE(IN_VIEW_FLAGGED_IMPS ,0))
                    ,
                    FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS
                )
            )) + FLOOR(SUM(
                IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                    IF(Q_DATA_IMPS > IMPS, ((COALESCE(NOT_IN_VIEW_PASSED_IMPS ,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(NOT_IN_VIEW_PASSED_IMPS, 0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0))
                    ,
                    0
                )
            ))) AS SIGNED), 2) AS customMetricsId2_totalNetInViewPct
             , SUM(TRUE_VIEW_VIEWABLE_IMPS) AS trueViewViewableImps,
                ROUND(100 * SUM(TRUE_VIEW_VIEWABLE_IMPS)/SUM(TRUE_VIEW_MEASURABLE_IMPS), 2) AS trueViewViewablePct,
                SUM(TRUE_VIEW_MEASURABLE_IMPS) AS trueViewMeasurableImps,
                ROUND(100 * SUM(TRUE_VIEW_MEASURABLE_IMPS)/FLOOR(SUM(COALESCE(PASSED_IMPS, IMPS) + COALESCE(FLAGGED_IMPS, 0) - COALESCE(SUSPICIOUS_PASSED_IMPS, SUSPICIOUS_IMPS) - COALESCE(SUSPICIOUS_FLAGGED_IMPS, 0))), 2) AS trueViewMeasurablePct
             ,         MIN(HIT_DATE) as minDate,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) , GROSS_BILLABLE_DISPLAY_IMPS, 0))  as grossBillableImps,

                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, PASSED_IMPS+FLAGGED_IMPS, 0))  as regularUnblockedImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, PASSED_IMPS+FLAGGED_IMPS, 0))  as parentUnblockedImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 3, PASSED_IMPS+FLAGGED_IMPS, 0))  as childUnblockedImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as regularSuspiciousImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as parentSuspiciousImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 3, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as childSuspiciousImps,
                    ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as regularInViewImps,
                    ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as regularOutOfViewImps,
                    ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as parentInViewImps,
                    ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as parentOutOfViewImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, FULLY_IN_VIEW_THRU_2D_IMPS, 0))  as regularInViewGt2qUnblockedImps100,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NOT NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 1, BILLABLE_DISPLAY_IMPS, 0))  as regularRawBillableDisplayImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 1, FULLY_IN_VIEW_0S_PASSED_IMPS+FULLY_IN_VIEW_0S_FLAGGED_IMPS, 0))  as regularEstimatedDisplayBillableImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, FULLY_IN_VIEW_THRU_2D_IMPS, 0))  as parentInViewGt2qUnblockedImps100,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NOT NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 2, BILLABLE_DISPLAY_IMPS, 0))  as parentRawBillableDisplayImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 2, FULLY_IN_VIEW_0S_PASSED_IMPS+FULLY_IN_VIEW_0S_FLAGGED_IMPS, 0))  as parentEstimatedDisplayBillableImps,

                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, COALESCE(PASSED_IMPS, IMPS)+COALESCE(FLAGGED_IMPS,0), 0))  as regularVIDEOUnblockedImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, PASSED_IMPS+FLAGGED_IMPS, 0))  as parentVIDEOUnblockedImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 3, PASSED_IMPS+FLAGGED_IMPS, 0))  as childVIDEOUnblockedImps,

                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, COALESCE(SUSPICIOUS_PASSED_IMPS, SUSPICIOUS_IMPS)+COALESCE(SUSPICIOUS_FLAGGED_IMPS,0), 0))  as regularVIDEOSuspiciousImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as parentVIDEOSuspiciousImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 3, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as childVIDEOSuspiciousImps,

                    ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as regularVIDEOInViewImps,
                    ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as regularVIDEOOutOfViewImps,
                    ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as parentVIDEOInViewImps,
                    ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as parentVIDEOOutOfViewImps
            , CAMPAIGN_ID as campaignId, CAMPAIGN_NAME as campaignName,PUBLISHER_ID as publisherId, PUBLISHER_NAME as publisherName,HIT_DATE as hitDate
        FROM
            (
            SELECT
                'PMI' AS MEASUREMENT_SOURCE_TYPE,
                MEDIA_TYPE_ID,
                (IMPS + GENERAL_INVALID_IMPS) AS GROSS_IMPS,
                IMPS,
                IMPS as Q_DATA_IMPS,
                NULL as PASSED_IMPS,
                NULL as FLAGGED_IMPS,
                NULL as SUSPICIOUS_PASSED_IMPS,
                NULL as SUSPICIOUS_FLAGGED_IMPS,
                IN_VIEW_IMPS as IN_VIEW_PASSED_IMPS,
                0 as IN_VIEW_FLAGGED_IMPS,
                NOT_IN_VIEW_IMPS as NOT_IN_VIEW_PASSED_IMPS,
                0 as NOT_IN_VIEW_FLAGGED_IMPS,
                SUSPICIOUS_IMPS AS SIVT_IMPS,
                SUSPICIOUS_IMPS,
                GENERAL_INVALID_IMPS AS GIVT_IMPS

                 ,
                    2 AS MCM_1_SRC,
                        GROUPM_IN_VIEW_IMPS AS MCM_1_NON_SUSPICIOUS_IMPS,
                        TRUE_VIEW_VIEWABLE_IMPS,
                        TRUE_VIEW_MEASURABLE_IMPS,
                        NULL AS FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS
                            , GROUPM_IN_VIEW_IMPS AS GROSS_BILLABLE_DISPLAY_IMPS
                            , NULL AS BILLABLE_DISPLAY_IMPS
                            , NULL AS FULLY_IN_VIEW_0S_PASSED_IMPS
                            , NULL AS FULLY_IN_VIEW_0S_FLAGGED_IMPS
                            , NULL AS ROADBLOCK_STATUS
                            , GROUPM_IN_VIEW_IMPS AS FULLY_IN_VIEW_THRU_2D_IMPS

                , CAMPAIGN_PM.CAMPAIGN_ID as CAMPAIGN_ID, CAMPAIGN.NAME as CAMPAIGN_NAME,PUBLISHER_PM.PUBLISHER_ID as PUBLISHER_ID, PUBLISHER_PM.NAME as PUBLISHER_NAME,HIT_DATE
            FROM
                AGG_PARTNER_MEASURED_VIEWABILITY VIEWABILITY_PM
                    JOIN (SELECT ID, MEASUREMENT_SOURCE_ID, NAME, CAMPAIGN_ID FROM PARTNER_MEASURED_CAMPAIGN where CAMPAIGN_ID > 0 ) CAMPAIGN_PM ON (VIEWABILITY_PM.PARTNER_MEASURED_CAMPAIGN_ID=CAMPAIGN_PM.ID AND
                               VIEWABILITY_PM.MEASUREMENT_SOURCE_ID = CAMPAIGN_PM.MEASUREMENT_SOURCE_ID)
                    JOIN CAMPAIGN ON CAMPAIGN_PM.CAMPAIGN_ID=CAMPAIGN.ID
                    LEFT JOIN (SELECT ms.ID as MEASUREMENT_SOURCE_ID, pub.NAME as NAME, pe.PUBLISHER_ID as PUBLISHER_ID FROM MEASUREMENT_SOURCE ms LEFT JOIN PUB_ENTITY pe
                                ON ms.PUB_ENTITY_ID = pe.ID LEFT JOIN PUBLISHER pub on pe.PUBLISHER_ID = pub.ID) PUBLISHER_PM ON VIEWABILITY_PM.MEASUREMENT_SOURCE_ID = PUBLISHER_PM.MEASUREMENT_SOURCE_ID

            WHERE
                (HIT_DATE >= '2018-01-16' AND HIT_DATE <= '2018-01-22')
                AND ( CAMPAIGN_PM.CAMPAIGN_ID IN (SELECT CAMPAIGN_ID FROM ADV_ENTITY WHERE TEAM_ID IN (94)) AND CAMPAIGN_ID > 0  AND CAMPAIGN_ID IN (123966,121966,122253,119247,119246,127649,122254,121028,123421,123423,119235,122244,119233,119242,122796,122243,122349,128039,122352,127171,122350,122250,122251,104908,123109,61243)  )
            ) PM
        GROUP BY CAMPAIGN_ID,PUBLISHER_ID,HIT_DATE

        UNION ALL

        SELECT
            FLOOR(SUM(COALESCE(PASSED_IMPS, IMPS) + COALESCE(FLAGGED_IMPS, 0) - COALESCE(SUSPICIOUS_PASSED_IMPS, SUSPICIOUS_IMPS) - COALESCE(SUSPICIOUS_FLAGGED_IMPS, 0))) AS totalNetEligibleImps,
            CAST((FLOOR(SUM(
                IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                    IF(Q_DATA_IMPS > IMPS, ((COALESCE(IN_VIEW_PASSED_IMPS, 0) + COALESCE(IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(IN_VIEW_PASSED_IMPS ,0) + COALESCE(IN_VIEW_FLAGGED_IMPS ,0))
                    ,
                    FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS
                )
            )) + FLOOR(SUM(
                IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                    IF(Q_DATA_IMPS > IMPS, ((COALESCE(NOT_IN_VIEW_PASSED_IMPS ,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(NOT_IN_VIEW_PASSED_IMPS, 0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0))
                    ,
                    0
                )
            ))) AS SIGNED) AS totalNetMeasuredImps,
            FLOOR(SUM(IF(Q_DATA_IMPS > IMPS, ((COALESCE(IN_VIEW_PASSED_IMPS, 0) + COALESCE(IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(IN_VIEW_PASSED_IMPS ,0) + COALESCE(IN_VIEW_FLAGGED_IMPS ,0)))) AS totalNetInViewImps,
            SUM(IF(GROSS_IMPS=0, IMPS, GROSS_IMPS)) AS grossImps,
            0 AS totalEligibleForBrandSafety,
            SUM(PASSED_IMPS) AS passedImps,
            (SUM(SIVT_IMPS) + COALESCE(SUM(GIVT_IMPS), 0)) AS fraudulentImps
             , CAST(
                SUM(
                  IF (MCM_1_SRC = 2
                  	,  IF(MEASUREMENT_SOURCE_TYPE = 'PMI', MCM_1_NON_SUSPICIOUS_IMPS,
                        ROUND( MCM_1_NON_SUSPICIOUS_IMPS * ( IF(Q_DATA_IMPS > IMPS,
                    (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                    * IMPS / Q_DATA_IMPS
                    ,
                    (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                  )
                ) / IMPS )
                       )
                    , 0
                  )
                ) AS SIGNED) AS customMetricsId2_totalNetInViewImps,
                ROUND(100 * CAST(
            SUM(
              IF (MCM_1_SRC = 2
              	,  IF(MEASUREMENT_SOURCE_TYPE = 'PMI', MCM_1_NON_SUSPICIOUS_IMPS,
                    ROUND( MCM_1_NON_SUSPICIOUS_IMPS * ( IF(Q_DATA_IMPS > IMPS,
                (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
                * IMPS / Q_DATA_IMPS
                ,
                (COALESCE(IN_VIEW_PASSED_IMPS,0) + COALESCE(IN_VIEW_FLAGGED_IMPS,0) + COALESCE(NOT_IN_VIEW_PASSED_IMPS,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS,0))
              )
            ) / IMPS )
                   )
                , 0
              )
            ) AS SIGNED) / CAST((FLOOR(SUM(
                IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                    IF(Q_DATA_IMPS > IMPS, ((COALESCE(IN_VIEW_PASSED_IMPS, 0) + COALESCE(IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(IN_VIEW_PASSED_IMPS ,0) + COALESCE(IN_VIEW_FLAGGED_IMPS ,0))
                    ,
                    FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS
                )
            )) + FLOOR(SUM(
                IF (FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS IS NULL,
                    IF(Q_DATA_IMPS > IMPS, ((COALESCE(NOT_IN_VIEW_PASSED_IMPS ,0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0)) / (Q_DATA_IMPS / IMPS)), COALESCE(NOT_IN_VIEW_PASSED_IMPS, 0) + COALESCE(NOT_IN_VIEW_FLAGGED_IMPS, 0))
                    ,
                    0
                )
            ))) AS SIGNED), 2) AS customMetricsId2_totalNetInViewPct
             , SUM(TRUE_VIEW_VIEWABLE_IMPS) AS trueViewViewableImps,
                ROUND(100 * SUM(TRUE_VIEW_VIEWABLE_IMPS)/SUM(TRUE_VIEW_MEASURABLE_IMPS), 2) AS trueViewViewablePct,
                SUM(TRUE_VIEW_MEASURABLE_IMPS) AS trueViewMeasurableImps,
                ROUND(100 * SUM(TRUE_VIEW_MEASURABLE_IMPS)/FLOOR(SUM(COALESCE(PASSED_IMPS, IMPS) + COALESCE(FLAGGED_IMPS, 0) - COALESCE(SUSPICIOUS_PASSED_IMPS, SUSPICIOUS_IMPS) - COALESCE(SUSPICIOUS_FLAGGED_IMPS, 0))), 2) AS trueViewMeasurablePct
             ,         MIN(HIT_DATE) as minDate,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) , GROSS_BILLABLE_DISPLAY_IMPS, 0))  as grossBillableImps,

                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, PASSED_IMPS+FLAGGED_IMPS, 0))  as regularUnblockedImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, PASSED_IMPS+FLAGGED_IMPS, 0))  as parentUnblockedImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 3, PASSED_IMPS+FLAGGED_IMPS, 0))  as childUnblockedImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as regularSuspiciousImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as parentSuspiciousImps,
                    SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 3, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as childSuspiciousImps,
                    ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as regularInViewImps,
                    ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as regularOutOfViewImps,
                    ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as parentInViewImps,
                    ROUND(SUM( IF(COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as parentOutOfViewImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, FULLY_IN_VIEW_THRU_2D_IMPS, 0))  as regularInViewGt2qUnblockedImps100,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NOT NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 1, BILLABLE_DISPLAY_IMPS, 0))  as regularRawBillableDisplayImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 1, FULLY_IN_VIEW_0S_PASSED_IMPS+FULLY_IN_VIEW_0S_FLAGGED_IMPS, 0))  as regularEstimatedDisplayBillableImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, FULLY_IN_VIEW_THRU_2D_IMPS, 0))  as parentInViewGt2qUnblockedImps100,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NOT NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 2, BILLABLE_DISPLAY_IMPS, 0))  as parentRawBillableDisplayImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (1, 4, 5, 6, 111, 121, 131, 221, 231) AND BILLABLE_DISPLAY_IMPS IS NULL AND COALESCE(ROADBLOCK_STATUS, 1) = 2, FULLY_IN_VIEW_0S_PASSED_IMPS+FULLY_IN_VIEW_0S_FLAGGED_IMPS, 0))  as parentEstimatedDisplayBillableImps,

                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, COALESCE(PASSED_IMPS, IMPS)+COALESCE(FLAGGED_IMPS,0), 0))  as regularVIDEOUnblockedImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, PASSED_IMPS+FLAGGED_IMPS, 0))  as parentVIDEOUnblockedImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 3, PASSED_IMPS+FLAGGED_IMPS, 0))  as childVIDEOUnblockedImps,

                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, COALESCE(SUSPICIOUS_PASSED_IMPS, SUSPICIOUS_IMPS)+COALESCE(SUSPICIOUS_FLAGGED_IMPS,0), 0))  as regularVIDEOSuspiciousImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as parentVIDEOSuspiciousImps,
                    SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 3, SUSPICIOUS_PASSED_IMPS+SUSPICIOUS_FLAGGED_IMPS, 0))  as childVIDEOSuspiciousImps,

                    ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as regularVIDEOInViewImps,
                    ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 1, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as regularVIDEOOutOfViewImps,
                    ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), IN_VIEW_PASSED_IMPS+IN_VIEW_FLAGGED_IMPS), 0)))  as parentVIDEOInViewImps,
                    ROUND(SUM( IF(COALESCE(MEDIA_TYPE_ID, 1) IN (2, 3, 112, 122, 132, 222, 232) AND COALESCE(ROADBLOCK_STATUS, 1) = 2, IF(Q_DATA_IMPS > IMPS, ((NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS)/(Q_DATA_IMPS/IMPS)), NOT_IN_VIEW_PASSED_IMPS+NOT_IN_VIEW_FLAGGED_IMPS), 0)))  as parentVIDEOOutOfViewImps
            , CAMPAIGN_ID as campaignId, CAMPAIGN_NAME as campaignName,PUBLISHER_ID as publisherId, PUBLISHER_NAME as publisherName,HIT_DATE as hitDate
        FROM
            (
            SELECT
                'PMI' AS MEASUREMENT_SOURCE_TYPE,
                MEDIA_TYPE_ID,
                (IMPS + GENERAL_INVALID_IMPS - FACEBOOK_INVALID_IMPS) AS GROSS_IMPS,
                IF (CAST((MEDIA_TYPE_ID MOD 10) AS SIGNED) = 1,
                    (DETERMINISTIC_IMPS + SUSPICIOUS_IMPS),
                    (IMPS - FACEBOOK_INVALID_IMPS)
                ) as IMPS,
                IF (CAST((MEDIA_TYPE_ID MOD 10) AS SIGNED) = 1,
                    (DETERMINISTIC_IMPS + SUSPICIOUS_IMPS),
                    (IMPS - FACEBOOK_INVALID_IMPS)
                ) as Q_DATA_IMPS,
                NULL as PASSED_IMPS,
                NULL as FLAGGED_IMPS,
                NULL as SUSPICIOUS_PASSED_IMPS,
                NULL as SUSPICIOUS_FLAGGED_IMPS,
                IN_VIEW_IMPS as IN_VIEW_PASSED_IMPS,
                0 as IN_VIEW_FLAGGED_IMPS,
                IF (CAST((MEDIA_TYPE_ID MOD 10) AS SIGNED) = 1,
                    (MEASURED_IMPS - IN_VIEW_IMPS),
                    (IMPS - FACEBOOK_INVALID_IMPS - SUSPICIOUS_IMPS - IN_VIEW_IMPS)
                ) as NOT_IN_VIEW_PASSED_IMPS,
                0 as NOT_IN_VIEW_FLAGGED_IMPS,
                SUSPICIOUS_IMPS AS SIVT_IMPS,
                SUSPICIOUS_IMPS,
                GENERAL_INVALID_IMPS AS GIVT_IMPS

                 ,
                    2 AS MCM_1_SRC,
                        IF (CAST((MEDIA_TYPE_ID MOD 10) AS SIGNED) = 1,
                            FULL_IN_VIEW_IMPS,
                            PASS_THRU_VIEW_IMPS
                        ) AS MCM_1_NON_SUSPICIOUS_IMPS,
                        NULL AS TRUE_VIEW_VIEWABLE_IMPS,
                        NULL AS TRUE_VIEW_MEASURABLE_IMPS,
                        IF (CAST((MEDIA_TYPE_ID MOD 10) AS SIGNED) = 1,
                            FULL_VIEW_ENABLED_IMPS,
                            NULL
                        ) AS FACEBOOK_GROUPM_DISPLAY_MEASURED_IMPS
                            , NULL AS GROSS_BILLABLE_DISPLAY_IMPS
                            , NULL AS BILLABLE_DISPLAY_IMPS
                            , NULL AS FULLY_IN_VIEW_0S_PASSED_IMPS
                            , NULL AS FULLY_IN_VIEW_0S_FLAGGED_IMPS
                            , NULL AS ROADBLOCK_STATUS
                            , NULL AS FULLY_IN_VIEW_THRU_2D_IMPS

                , CAMPAIGN_PM.CAMPAIGN_ID as CAMPAIGN_ID, CAMPAIGN.NAME as CAMPAIGN_NAME,PUBLISHER_PM.PUBLISHER_ID as PUBLISHER_ID, PUBLISHER_PM.NAME as PUBLISHER_NAME,HIT_DATE
            FROM
                AGG_FACEBOOK_VIEWABILITY
                    JOIN PARTNER_MEASURED_CAMPAIGN_MAPPING MAPPING ON (AGG_FACEBOOK_VIEWABILITY.MEASUREMENT_SOURCE_ID = MAPPING.MEASUREMENT_SOURCE_ID AND AGG_FACEBOOK_VIEWABILITY.AD_ID = MAPPING.EXT_MAPPING_ID)
                    JOIN (SELECT ID, MEASUREMENT_SOURCE_ID, NAME, CAMPAIGN_ID, STATUS FROM PARTNER_MEASURED_CAMPAIGN where CAMPAIGN_ID > 0 ) CAMPAIGN_PM ON (MAPPING.EXT_CAMPAIGN_ID=CAMPAIGN_PM.ID AND
                               AGG_FACEBOOK_VIEWABILITY.MEASUREMENT_SOURCE_ID = CAMPAIGN_PM.MEASUREMENT_SOURCE_ID)
                    JOIN CAMPAIGN ON CAMPAIGN_PM.CAMPAIGN_ID=CAMPAIGN.ID
                    LEFT JOIN (SELECT ms.ID as MEASUREMENT_SOURCE_ID, pub.NAME as NAME, pe.PUBLISHER_ID as PUBLISHER_ID FROM MEASUREMENT_SOURCE ms LEFT JOIN PUB_ENTITY pe
                                ON ms.PUB_ENTITY_ID = pe.ID LEFT JOIN PUBLISHER as pub on pe.PUBLISHER_ID = pub.ID) PUBLISHER_PM ON AGG_FACEBOOK_VIEWABILITY.MEASUREMENT_SOURCE_ID = PUBLISHER_PM.MEASUREMENT_SOURCE_ID

            WHERE
                (HIT_DATE >= '2018-01-16' AND HIT_DATE <= '2018-01-22')
                AND ( CAMPAIGN_PM.CAMPAIGN_ID IN (SELECT CAMPAIGN_ID FROM ADV_ENTITY WHERE TEAM_ID IN (94)) AND CAMPAIGN_ID > 0  AND CAMPAIGN_ID IN (123966,121966,122253,119247,119246,127649,122254,121028,123421,123423,119235,122244,119233,119242,122796,122243,122349,128039,122352,127171,122350,122250,122251,104908,123109,61243)  )
            ) FB
        GROUP BY CAMPAIGN_ID,PUBLISHER_ID,HIT_DATE
) THIS_PERIOD
GROUP BY campaignId,publisherId,hitDate
 HAVING grossImps >= 0
 ORDER BY grossImps desc
