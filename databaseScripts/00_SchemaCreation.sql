/* Azure SQL DB Schema/Table/SP creation for PBI Monitoring Example */

-- Create the PBI Schema
IF NOT EXISTS ( SELECT  *
                FROM    sys.schemas
                WHERE   name = N'pbi' )
    EXEC('CREATE SCHEMA [pbi]');
GO

/*
	Table Creation - ActityEvents, RunId, Watermark
*/
CREATE TABLE [pbi].[ActivityEvents](
	[IdIdentity] [int] IDENTITY(1,1) NOT NULL,
	[Id] [nvarchar](40) NULL,
	[RecordType] [int] NULL,
	[CreationTime] [datetime] NULL,
	[Operation] [nvarchar](100) NULL,
	[OrganizationId] [nvarchar](40) NULL,
	[UserType] [int] NULL,
	[UserKey] [nvarchar](40) NULL,
	[Workload] [nvarchar](50) NULL,
	[UserId] [nvarchar](40) NULL,
	[ClientIP] [nvarchar](15) NULL,
	[UserAgent] [nvarchar](150) NULL,
	[Activity] [nvarchar](100) NULL,
	[ItemName] [nvarchar](100) NULL,
	[WorkspaceName] [nvarchar](255) NULL,
	[DatasetName] [nvarchar](255) NULL,
	[WorkspaceId] [nvarchar](40) NULL,
	[ObjectId] [nvarchar](100) NULL,
	[DatasetId] [nvarchar](40) NULL,
	[DataConnectivityMode] [nvarchar](100) NULL,
	[IsSuccess] [bit] NULL,
	[RequestId] [nvarchar](40) NULL,
	[ActivityId] [nvarchar](40) NULL,
	[TableName] [nvarchar](100) NULL,
	[IdJobRun] [int] NULL,
	CONSTRAINT [PK_pbi_ActivityEvents] PRIMARY KEY CLUSTERED 
(
	[IdIdentity] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO
--Index for CreationTime
CREATE NONCLUSTERED INDEX IX_ActivityEvents_CreateTime ON pbi.ActivityEvents
	(
	CreationTime
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

/****** [pbi].[RunId]  ******/
CREATE TABLE [pbi].[RunId](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RunId] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_pbiRunId] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [pbi].[Watermark]  ******/
CREATE TABLE [pbi].[Watermark](
	[IdSource] [int] NOT NULL,
	[Description] [nvarchar](500) NULL,
	[SourceWatermark] [datetime2](4) NULL,
	[SinkContainer] [nvarchar](100) NULL,
	[SinkDirectory] [nvarchar](500) NULL,
 CONSTRAINT [PK_pbi_Watermark] PRIMARY KEY CLUSTERED 
(
	[IdSource] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Seed the Watermark table to start loading from 14 days ago
DECLARE @14DaysAgo DateTime2(4) = DATEADD( DAY, -14, GETDATE() );
INSERT INTO pbi.Watermark (IdSource, Description, SourceWatermark, SinkContainer, SinkDirectory)
VALUES (1, 'Load ActivityEvents from PBI REST API to Staging area in ADLSG2', @14DaysAgo, 'pbi','_Staging');
GO

/*
	Create stored procedures....
*/

/****** StoredProcedure [pbi].[Watermark_S]  ******/
CREATE PROCEDURE [pbi].[Watermark_S]
	@IdSource int, @flCheckTable bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @SourceWatermark datetime2(4);

	SELECT @SourceWatermark = SourceWatermark FROM pbi.Watermark WHERE IdSource = @IdSource;

	IF (@flCheckTable = 1)
	  BEGIN
		  DECLARE @TblWatermark datetime2(4);
		  SELECT @TblWatermark = DATEADD(s, 1, MAX(CreationTime)) FROM pbi.ActivityEvents;
		  IF @TblWatermark IS NOT NULL
		     BEGIN
				SET @SourceWatermark = @TblWatermark;
				UPDATE pbi.Watermark SET SourceWatermark = @SourceWatermark
				WHERE	IdSource = @IdSource;
			 END
	  END

	SELECT @IdSource AS IdSource, @SourceWatermark AS SourceWatermark, SinkContainer, SinkDirectory
	FROM	pbi.Watermark WHERE IdSource = @IdSource;
END
GO

/****** StoredProcedure [pbi].[GetActivityEventDates]  ******/
CREATE PROCEDURE [pbi].[GetActivityEventDates]
(
 @StartDateTime DATETIME2(3),			-- = '2019-11-27 15:45:52.879'
 @EndDateTime   DATETIME2(3)		-- = '2019-12-01 15:45:52.879'
)
AS

DECLARE @StartDate DATETIME2(3) = DATEADD(dd, DATEDIFF(dd, 0, @StartDateTime), 0);

WITH mycte AS
(
  SELECT @StartDate AS startDate, DATEADD(ss, -1, DATEADD(dd, 1, @StartDate)) as endDate
  UNION ALL
  SELECT  DATEADD(d, 1, startDate), DATEADD(ss, -1, DATEADD(d, 2, startDate))
  FROM    mycte   
  WHERE   DATEADD(d, 1, startDate) < @EndDateTime 
)
SELECT  CASE WHEN startDate < @StartDateTime THEN @StartDateTime ELSE startDate END as startDateTime,
		CASE WHEN endDate < @EndDateTime     THEN endDate ELSE @EndDateTime END AS endDateTime
FROM    mycte
OPTION (MAXRECURSION 0);
GO

/****** StoredProcedure [pbi].[RunId_I]   ******/
CREATE PROCEDURE [pbi].[RunId_I]
(
    @RunId uniqueidentifier
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
	INSERT INTO pbi.RunId (RunId) VALUES (@RunId);
    SELECT SCOPE_IDENTITY() AS [Id];
END
GO

/****** StoredProcedure [pbi].[ActivityEvents_Dedup] ******/
CREATE PROCEDURE [pbi].[ActivityEvents_Dedup]
(
    @DateStart datetime = '2020-01-01 00:00:00.000'
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	WITH CTE_ActDups AS (SELECT	IdIdentity, Id, CreationTime, ROW_NUMBER() OVER (PARTITION BY Id, CreationTime
						ORDER BY Id, CreationTime) AS RowNum
						FROM	pbi.ActivityEvents
						WHERE	CreationTime > @DateStart)
	DELETE pbi.ActivityEvents FROM pbi.ActivityEvents A INNER JOIN CTE_ActDups D
		ON A.IdIdentity = D.IdIdentity AND D.RowNum > 1;
END
GO



