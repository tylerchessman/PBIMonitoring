# PBIMonitoring
A framework to retrieve/store PBI Activity Event in an Azure SQL Database.  Includes a sample Power BI Report to query/analyze the activity events..

### Summary
Power BI logs a variety of usage and security related information that are accessible from different APIs (learn more from the official documentation, https://docs.microsoft.com/en-us/power-bi/admin/service-admin-auditing).  The Power BI Activity logs (https://powerbi.microsoft.com/en-us/blog/the-power-bi-activity-log-makes-it-easy-to-download-activity-data-for-custom-usage-reporting/), introduced in December of 2019, can be accessed by Power BI Administrators through a REST API or PowerShell cmdlet.  For long-term retention, and ease of reporting, it is important to extract and store these events in some type of repository.

The frameork in this repository uses Azure Data Factory, Azure Data Lake Gen2 storage, and Azure SQL DB to automate the extraction and storage of the activity events.  A sample Power BI Report (which uses the Azure SQL DB) is also included to demonstrate how to query/use the activity events.

Note that metadata about PBI artifacts (e.g., a report’s author, initial creation date, sensitivity label) can also be obtained via other PBI REST APIs; with a bit of additional effort, the framework can be adapted to retrieve/store this metadata.


### Getting Started
Please refer to the Word document (PBIMonitoringFramework_V1.docx) for step-by-step details on how to get started.
