-- Replace [ADF_Managed_Identity] with the name of your ADF Managed Identity

-- See https://docs.microsoft.com/en-us/azure/data-factory/data-factory-service-identity for more information
--		about managed identities in ADF.

CREATE USER [ADF_Managed_Identity] FROM  EXTERNAL PROVIDER  WITH DEFAULT_SCHEMA=[dbo];
--ALTER ROLE db_datareader ADD MEMBER [ADF_Managed_Identity]; -- Optional
--ALTER ROLE db_datawriter ADD MEMBER [ADF_Managed_Identity]; -- Optional
GRANT SELECT  ON pbi.ActivityEvents TO [ADF_Managed_Identity];
GRANT INSERT  ON pbi.ActivityEvents TO [ADF_Managed_Identity];

GRANT EXECUTE ON [pbi].[ActivityEvents_Dedup]	TO [ADF_Managed_Identity];
GRANT EXECUTE ON [pbi].[GetActivityEventDates]	TO [ADF_Managed_Identity];
GRANT EXECUTE ON [pbi].[RunId_I]				TO [ADF_Managed_Identity];
GRANT EXECUTE ON [pbi].[Watermark_S]			TO [ADF_Managed_Identity];
