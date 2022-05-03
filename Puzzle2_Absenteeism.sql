--------------------------------------------------------------------------------------------------------------------------
-------------------------------- Create Absenteeism table-----------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS dbo.Absenteeism;

CREATE TABLE dbo.Absenteeism 
(
 emp_id				INTEGER		NOT NULL  
,absent_date		DATE		NOT NULL 
,reason_code		CHAR (40)	NOT NULL  
,severity_points	INTEGER		NOT NULL 
,IsActive			BIT			NOT NULL CONSTRAINT DFT_Absenteeism_IsActive DEFAULT (1)
,CONSTRAINT		    PK_Absenteeism_empidabsentdate PRIMARY KEY CLUSTERED(emp_id, absent_date)
,CONSTRAINT			CHK_Absenteeism_severitypoints CHECK (severity_points BETWEEN 0 AND 4)
 );
GO

--------------------------------------------------------------------------------------------------------------------------
-------------------------------- INSERT_Employee_Absenteeism_Details - Handing Business Rules-----------------------------
--------------------------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS dbo.INSERT_Employee_Absenteeism_Details;
GO

CREATE PROCEDURE dbo.INSERT_Employee_Absenteeism_Details 
(
	@empid			INTEGER		
   ,@absentdate		DATE		
   ,@reasoncode		CHAR(40)	
   ,@severitypoint  INTEGER		
)
AS
BEGIN

SET NOCOUNT, XACT_ABORT ON;

BEGIN TRAN

BEGIN TRY 
	--Get first day of the year and last day of the year

DECLARE @StartDateOfCurrentYear as DATE = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0)		
       ,@EndDateOfCurrentYear   as DATE = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) + 1, -1);  

DECLARE @ErrorMessage		AS NVARCHAR(4000)
	   ,@ErrorSeverity		AS INT
	   ,@ErrorState			as INT;
	
	--Rule 1 -If an employee is absent more than one day in a row, it is charged as a long-term illness, not as a typical absence. 
			--The employee does not receive severity points on the second, third, or later days, nor do those days count toward his or her 
			--total absenteeism.

	IF EXISTS (SELECT 1 FROM dbo.Absenteeism WHERE emp_id = @empid AND absent_date = DATEADD(DAY, -1, @absentdate))
		BEGIN		
			SET @reasoncode = 'Long-Term Illness (LTI)';
			
			INSERT INTO dbo.Absenteeism (emp_id, absent_date, reason_code, severity_points) 
				VALUES (@empid, @absentdate, @reasoncode, 0);
		END
	ELSE
		BEGIN
			INSERT INTO dbo.Absenteeism (emp_id, absent_date, reason_code, severity_points) 
				VALUES (@empid, @absentdate, @reasoncode, @severitypoint);
		END

	--Rule 2- check if Employee is incurring 40 or more severity points then mark the active flag as 0 to indicate employee is not active
	IF EXISTS (SELECT emp_id FROM dbo.Absenteeism 
			   WHERE emp_id = @empid AND absent_date BETWEEN @StartDateOfCurrentYear AND @EndDateOfCurrentYear  
			   GROUP BY emp_id 
			   HAVING SUM(severity_points)>=40)
	BEGIN		
		UPDATE dbo.Absenteeism
		SET    IsActive = 0 --mark the employee as InActive
		WHERE  emp_id = @empid;

		RAISERROR('Error - Employee has Incurred 40 or more severity points thus marking the employee as In Active', 10, 1) WITH NOWAIT;		
    END		

	COMMIT TRAN;
END TRY

BEGIN CATCH
			SELECT @ErrorMessage  = ERROR_MESSAGE()
			      ,@ErrorSeverity = ERROR_SEVERITY()
				  ,@ErrorState    = ERROR_STATE();		   

			IF XACT_STATE() <> 0
			ROLLBACK TRAN;

			RAISERROR(@ErrorMessage, @ErrorSeverity,@ErrorState);		
END CATCH
END

--------------------------------------------------------------------------------------------------------------------------
-------------------------------- 1st rule Test Cases ---------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

--1st rule test --If an employee is absent more than one day in a row, it is charged as a long-term illness, not as a typical absence. The employee does not receive severity points on the 
				--second, third, or later days, nor do those days count toward his or her total absenteeism.

EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 1, @absentdate = '2022-01-03', @reasoncode = 'PTO', @severitypoint = 3; --allowed 
SELECT * FROM dbo.Absenteeism;

EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 1, @absentdate = '2022-01-04', @reasoncode = 'PTO', @severitypoint = 3; --more than one day leave-- mark severity points as 0 and update reason as Long-term-illness
SELECT * FROM dbo.Absenteeism;

EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 1, @absentdate = '2022-01-05', @reasoncode = 'PTO', @severitypoint = 3; --more than one day leave-- mark severity points as 0 and update reason as Long-term-illness
SELECT * FROM dbo.Absenteeism;


--------------------------------------------------------------------------------------------------------------------------
-------------------------------- 2nd rule Test Cases ---------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

--2nd rule test --  If an employee accrues 40 severity points within a one-year period, you automatically discharge that employee. 

EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-07', @reasoncode = 'Dog bite', @severitypoint = 1; --allowed
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-09', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-11', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-13', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-15', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-17', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-19', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-21', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-23', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-01-25', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-02-21', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-02-23', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-02-25', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 

-- allowed reached 40 points - mark employee as inactive
EXEC dbo.INSERT_Employee_Absenteeism_Details @empid = 2, @absentdate = '2022-03-01', @reasoncode = 'PTO'     , @severitypoint = 3; --allowed 
GO

SELECT emp_id, SUM(severity_points) AS severitypoint FROM dbo.Absenteeism GROUP BY emp_id;

SELECT * FROM dbo.Absenteeism;
