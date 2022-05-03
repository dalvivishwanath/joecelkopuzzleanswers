DROP TABLE IF EXISTS dbo.FiscalYear;

CREATE TABLE dbo.FiscalYear
(
  [fiscal_year]	    INTEGER						NOT NULL
 ,[start_date]	    DATE						NOT NULL
 ,[end_date]		DATE						NOT NULL 
 ,CONSTRAINT		CHK_Date_Range			    CHECK ([start_date] < [end_date])
 ,CONSTRAINT		CHK_Date_No_of_Days		    CHECK (DATEDIFF(DAY,[start_date],[end_date]) >= 364 OR DATEDIFF(DAY,[start_date],[end_date]) = 365)
 ,CONSTRAINT		CHK_fiscal_year			    CHECK (fiscal_year= YEAR([start_date]))
 ,CONSTRAINT		CHK_start_date_month_date	CHECK (FORMAT([start_date], 'MM-dd') = '04-01' )
 ,CONSTRAINT		CHK_end_date_month_date		CHECK (FORMAT([end_date], 'MM-dd') = '03-31')
 ,CONSTRAINT		PK_FiscalYear_fiscalyear_startdate_end_date PRIMARY KEY	CLUSTERED ([fiscal_year], [start_date], [end_date])
);

--Sample data -- acceptable test cases - right data 

INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2010', '2010-04-01', '2011-03-31'); --non leap year
INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2022', '2022-04-01', '2023-03-31'); --non leap year
INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2023', '2023-04-01', '2024-03-31'); --non leap year
INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2024', '2024-04-01', '2025-03-31'); --leap year

--Query the inserted data

SELECT * FROM dbo.FiscalYear;

--check any random date to find the fiscal_year

SELECT [fiscal_year] FROM dbo.FiscalYear WHERE '2022-08-24' BETWEEN [start_date] AND [end_date];
SELECT [fiscal_year] FROM dbo.FiscalYear WHERE '2024-03-31' BETWEEN [start_date] AND [end_date];

--Sample data -- wrong test cases - wrong data 

INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2021', '2021-04-01', '2022-03-30'); --date difference lower than 364
INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2021', '2021-04-01', '2021-04-02'); --date difference greater than 365
INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2022', '2021-04-01', '2022-03-31'); --start_date's year is not equal to fiscal year
INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2021', '2022-04-01', '2021-03-31'); --wrong date range
INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2021', '2021-04-02', '2022-04-01'); --start date's month and date is not in correct format '04-01'
INSERT INTO dbo.FiscalYear ([fiscal_year], [start_date], [end_date]) VALUES ('2024', '2024-04-01', '2025-03-31'); --duplicate entry - primary key error