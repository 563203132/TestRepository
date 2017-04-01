USE OmniCourseContent;
GO

CREATE PROCEDURE ImportContentMapToBUByAchModel_FR
    @courseTypeLevel NVARCHAR(100) , -- like 'FRv1Bk1', 'FRv1Bk2'
    @achModel INT ,
    @countryCode NVARCHAR(100) ,
    @businessLineCode NVARCHAR(100)
AS
    BEGIN

        BEGIN TRAN;

        --DECLARE @courseTypeLevelCode NVARCHAR(100) = @courseTypeLevel;
        --DECLARE @ach INT = @achModel;
        --DECLARE @country NVARCHAR(100) = @countryCode;
        --DECLARE @businessLine NVARCHAR(100) = @businessLineCode;

		DECLARE @courseTypeLevelCode NVARCHAR(100) = 'FRv1Bk5';
        DECLARE @ach INT = 3;
        DECLARE @country NVARCHAR(100) = 'CN';
        DECLARE @businessLine NVARCHAR(100) = 'OWN';

/***************************************************
*                    Content Map                   *
***************************************************/
        INSERT  INTO OmniCourseContent.dbo.ContentMap
                ( Name ,
                  CourseTypeLevelCode ,
                  AchPerSession ,
                  Country ,
                  BusinessLine ,
                  CreatedBy ,
                  UpdatedBy ,
                  CreatedDateTimeUtc ,
                  UpdatedDateTimeUtc
			
                )
                SELECT  src.CONTENT_MAP_CODE ,
                        'FRv1Bk' + SUBSTRING(src.CONTENT_MAP_CODE, 11, 1) ,
                        src.ACH_MODEL ,
                        src.COUNTRY ,
                        src.BUSINESS_LINE ,
                        'System' ,
                        'System' ,
                        GETUTCDATE() ,
                        GETUTCDATE()
                FROM    ImportingContentMapFR.dbo.Content_Map$ src
                        LEFT JOIN OmniCourseContent.dbo.ContentMap cm ON cm.Name = src.CONTENT_MAP_CODE
                WHERE   cm.Id IS NULL
                        AND src.COUNTRY = @country
                        AND src.BUSINESS_LINE = @businessLine
                        AND 'FRv1Bk' + SUBSTRING(src.CONTENT_MAP_CODE, 11, 1) = @courseTypeLevelCode
                        AND src.ACH_MODEL = @ach;

/***************************************************
*                    Course Unit                   *
***************************************************/
        INSERT  INTO OmniCourseContent.dbo.CourseUnit
                ( Name ,
                  CourseTypeLevelCode ,
                  OrderingSequence ,
                  CreatedBy ,
                  UpdatedBy ,
                  CreatedDateTimeUtc ,
                  UpdatedDateTimeUtc
                )
                SELECT  UNIT ,
                        a.CourseTypeLevelCode ,
                        ROW_NUMBER() OVER ( PARTITION BY a.CourseTypeLevelCode ORDER BY UNIT ) ,
                        'System' ,
                        'System' ,
                        GETUTCDATE() ,
                        GETUTCDATE()
                FROM    ( SELECT DISTINCT
                                    src.UNIT ,
                                    'FRv1Bk' + SUBSTRING(src.CONTENT_MAP_CODE,
                                                         11, 1) AS CourseTypeLevelCode
                          FROM      ImportingContentMapFR.[dbo].[Content_Map_Unit_Session$] src
                                    INNER JOIN ImportingContentMapFR.dbo.[Content_Map$] srcCm ON src.CONTENT_MAP_CODE = srcCm.CONTENT_MAP_CODE
                          WHERE     srcCm.COUNTRY = @country
                                    AND srcCm.BUSINESS_LINE = @businessLine
                                    AND 'FRv1Bk'
                                    + SUBSTRING(srcCm.CONTENT_MAP_CODE, 11, 1) = @courseTypeLevelCode
                                    AND srcCm.ACH_MODEL = @ach
                        ) a
                        LEFT JOIN OmniCourseContent.dbo.CourseUnit cu ON cu.CourseTypeLevelCode = a.CourseTypeLevelCode
                                                              AND cu.Name = a.UNIT
                WHERE   cu.Id IS NULL;

/***************************************************
*                   Progress Test Content          *
***************************************************/
        INSERT  INTO OmniCourseContent.dbo.ProgressTestContent
                ( Name ,
                  CourseTypeLevelCode ,
                  OrderingSequence ,
                  CreatedBy ,
                  UpdatedBy ,
                  CreatedDateTimeUtc ,
                  UpdatedDateTimeUtc
			
                )
                SELECT  t.PROGRESS_TEST ,
                        t.CourseTypeLevelCode ,
                        ROW_NUMBER() OVER ( PARTITION BY t.CourseTypeLevelCode ORDER BY PROGRESS_TEST ) ,
                        'System' ,
                        'System' ,
                        GETUTCDATE() ,
                        GETUTCDATE()
                FROM    ( SELECT DISTINCT
                                    src.PROGRESS_TEST ,
                                    'FRv1Bk' + SUBSTRING(src.CONTENT_MAP_CODE,
                                                         11, 1) AS CourseTypeLevelCode
                          FROM      ImportingContentMapFR.dbo.Content_Map_Unit_Progress_Test$ src
                                    INNER JOIN ImportingContentMapFR.dbo.[Content_Map$] srcCm ON src.CONTENT_MAP_CODE = srcCm.CONTENT_MAP_CODE
                          WHERE     srcCm.COUNTRY = @country
                                    AND srcCm.BUSINESS_LINE = @businessLine
                                    AND 'FRv1Bk'
                                    + SUBSTRING(srcCm.CONTENT_MAP_CODE, 11, 1) = @courseTypeLevelCode
                                    AND srcCm.ACH_MODEL = @ach
                        ) t
                        LEFT JOIN OmniCourseContent.dbo.ProgressTestContent ptc ON ptc.CourseTypeLevelCode = t.CourseTypeLevelCode
                                                              AND ptc.Name = t.PROGRESS_TEST
                WHERE   ptc.Id IS NULL;

/***************************************************
*              Progress Test                       *
***************************************************/
		INSERT  INTO OmniCourseContent.dbo.ProgressTest
			    ( Name,
			      ContentMapId,
			      ProgressTestContentKey,
				  OrderingSequence,
			      CreatedBy,
			      UpdatedBy,
			      CreatedDateTimeUtc,
			      UpdatedDateTimeUtc
			    )
			    SELECT  t.PROGRESS_TEST ,
                        t.contentMapId ,
                        t.ptcId ,
						t.ptcOrderingSequence ,
                        'System' ,
                        'System' ,
                        GETUTCDATE() ,
                        GETUTCDATE()
			    FROM	( SELECT DISTINCT 
								    pt.PROGRESS_TEST ,
									pt.CONTENT_MAP_CODE ,
								    cm.Id as contentMapId ,
								    ptc.Id as ptcId ,
								    ptc.OrderingSequence as ptcOrderingSequence
				          FROM      ImportingContentMapFR.dbo.Content_Map_Unit_Progress_Test$ pt
						            INNER JOIN ImportingContentMapFR.dbo.[Content_Map$] src ON pt.CONTENT_MAP_CODE = src.CONTENT_MAP_CODE
						            INNER JOIN OmniCourseContent.dbo.ContentMap cm ON pt.CONTENT_MAP_CODE = cm.Name
                                                                        AND cm.CourseTypeLevelCode = 'FRv1Bk'
                                                                        + SUBSTRING(pt.CONTENT_MAP_CODE,
                                                                        11, 1)
                                    INNER JOIN OmniCourseContent.dbo.ProgressTestContent ptc ON ptc.CourseTypeLevelCode = 'FRv1Bk'
                                                                        + SUBSTRING(pt.CONTENT_MAP_CODE,
                                                                        11, 1)
                                                                        AND ptc.Name = pt.PROGRESS_TEST
				          WHERE     pt.CONTENT_MAP_CODE IS NOT NULL
                                    AND pt.PROGRESS_TEST IS NOT NULL
                                    AND pt.UNIT IS NOT NULL
                                    AND src.COUNTRY = @country
                                    AND src.BUSINESS_LINE = @businessLine
                                    AND 'FRv1Bk' + SUBSTRING(src.CONTENT_MAP_CODE, 11, 1) = @courseTypeLevelCode
                                    AND src.ACH_MODEL = @ach
					    ) t
                        LEFT JOIN OmniCourseContent.dbo.ProgressTest opt ON t.contentMapId = opt.ContentMapId
                                                              AND opt.Name = t.PROGRESS_TEST
				WHERE   opt.Id IS NULL
                ORDER BY t.contentMapId ,
                        SUBSTRING(t.CONTENT_MAP_CODE, 11, 1);

/***************************************************
*              Unit Progress Test                  *
***************************************************/
        INSERT  INTO OmniCourseContent.dbo.UnitProgressTest
                ( ProgressTestId ,
                  CourseUnitId ,
                  CreatedBy ,
                  UpdatedBy ,
                  CreatedDateTimeUtc ,
                  UpdatedDateTimeUtc
			
                )
                SELECT  opt.Id ,
                        cu.Id ,
                        'System' ,
                        'System' ,
                        GETUTCDATE() ,
                        GETUTCDATE()
                FROM    ImportingContentMapFR.dbo.Content_Map_Unit_Progress_Test$ pt
                        INNER JOIN ImportingContentMapFR.dbo.[Content_Map$] src ON pt.CONTENT_MAP_CODE = src.CONTENT_MAP_CODE
                        INNER JOIN OmniCourseContent.dbo.CourseUnit cu ON pt.UNIT = cu.Name
                                                              AND cu.CourseTypeLevelCode = 'FRv1Bk'
                                                              + SUBSTRING(pt.CONTENT_MAP_CODE,
                                                              11, 1)
                        INNER JOIN OmniCourseContent.dbo.ProgressTestContent ptc ON ptc.CourseTypeLevelCode = 'FRv1Bk'
                                                              + SUBSTRING(pt.CONTENT_MAP_CODE,
                                                              11, 1)
                                                              AND ptc.Name = pt.PROGRESS_TEST
                        INNER JOIN OmniCourseContent.dbo.ProgressTest opt ON opt.ProgressTestContentKey = ptc.Id
                        LEFT JOIN OmniCourseContent.dbo.UnitProgressTest upt ON opt.Id = upt.ProgressTestId
                WHERE   pt.CONTENT_MAP_CODE IS NOT NULL
                        AND pt.PROGRESS_TEST IS NOT NULL
                        AND pt.UNIT IS NOT NULL
                        AND upt.Id IS NULL
                        AND src.COUNTRY = @country
                        AND src.BUSINESS_LINE = @businessLine
                        AND 'FRv1Bk' + SUBSTRING(src.CONTENT_MAP_CODE, 11, 1) = @courseTypeLevelCode
                        AND src.ACH_MODEL = @ach
                ORDER BY opt.Id ;

/***************************************************
*                    Unit Session                  *
***************************************************/
        INSERT  INTO OmniCourseContent.dbo.Lesson
                ( ContentMapId ,
                  CourseUnitId ,
                  LessonSequence ,
                  LessonContentId ,
				  LessonTypeCode ,
                  CreatedBy ,
                  UpdatedBy ,
                  CreatedDateTimeUtc ,
                  UpdatedDateTimeUtc
			
                )
                SELECT  cm.Id ,
                        cu.Id ,
                        ROW_NUMBER() OVER ( PARTITION BY src.CONTENT_MAP_CODE,
                                            UNIT ORDER BY UNIT_SESSION ) ,
                        NULL ,
						'CR' ,
                        'System' ,
                        'System' ,
                        GETUTCDATE() ,
                        GETUTCDATE()
                FROM    ImportingContentMapFR.dbo.Content_Map_Unit_Session$ src
                        INNER JOIN ImportingContentMapFR.dbo.[Content_Map$] srcCM ON src.CONTENT_MAP_CODE = srcCM.CONTENT_MAP_CODE
                        INNER JOIN OmniCourseContent.dbo.ContentMap cm ON src.CONTENT_MAP_CODE = cm.Name
                        INNER JOIN OmniCourseContent.dbo.CourseUnit cu ON src.UNIT = cu.Name
                                                              AND cu.CourseTypeLevelCode = 'FRv1Bk'
                                                              + SUBSTRING(src.CONTENT_MAP_CODE,
                                                              11, 1)
                        LEFT JOIN OmniCourseContent.dbo.Lesson le ON le.CourseUnitId = cu.Id
                                                              AND cm.Id = le.ContentMapId
                                                              AND CONVERT(NVARCHAR(100), le.LessonSequence) = RIGHT(src.UNIT_SESSION,
                                                              1)
                WHERE   le.Id IS NULL
                        AND srcCM.COUNTRY = @country
                        AND srcCM.BUSINESS_LINE = @businessLine
                        AND 'FRv1Bk' + SUBSTRING(srcCM.CONTENT_MAP_CODE, 11, 1) = @courseTypeLevelCode
                        AND srcCM.ACH_MODEL = @ach;

		-- Session content
        SET IDENTITY_INSERT dbo.LessonContent ON;
        INSERT  INTO dbo.LessonContent
                ( Id ,
                  CreatedBy ,
                  UpdatedBy ,
                  CreatedDateTimeUtc ,
                  UpdatedDateTimeUtc
	            )
                SELECT  le.Id ,
                        'System' ,
                        'System' ,
                        GETUTCDATE() ,
                        GETUTCDATE()
                FROM    dbo.Lesson le
                        LEFT JOIN dbo.LessonContent lc ON le.Id = lc.Id
                WHERE   lc.Id IS NULL;
        SET IDENTITY_INSERT dbo.LessonContent OFF;

		UPDATE dbo.Lesson SET LessonContentId = Id

		-- CoverInClass
        INSERT  INTO dbo.CoveredInClass
                ( Name ,
                  Comment ,
                  CreatedBy ,
                  UpdatedBy ,
                  CreatedDateTimeUtc ,
                  UpdatedDateTimeUtc
                )
                SELECT  cm.CourseTypeLevelCode + '-' + cm.Country + '-'
                        + cm.BusinessLine + '-'
                        + CAST(CAST(cm.AchPerSession AS INT) AS NVARCHAR(1))
                        + '-' + cu.Name + '-Session'
                        + CONVERT(NVARCHAR(2), le.LessonSequence),
						'',
						'System',
						'System',
						GETUTCDATE(),
						GETUTCDATE()
                FROM    dbo.LessonContent lc
                        INNER JOIN dbo.Lesson le ON le.LessonContentId = lc.Id
                        INNER JOIN dbo.ContentMap cm ON le.ContentMapId = cm.Id
                        INNER JOIN dbo.CourseUnit cu ON le.CourseUnitId = cu.Id
                        LEFT JOIN dbo.CoveredInClass cic ON lc.Id = cic.Id
                WHERE   cic.Id IS NULL;

		UPDATE dbo.LessonContent SET CoveredInClassKey=Id
		
        IF @@ERROR <> 0
            BEGIN
                ROLLBACK TRAN;
            END;
        ELSE
            BEGIN
                COMMIT;
            END;
    END;