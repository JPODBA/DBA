use BA_DBA
go
CREATE OR ALTER PROCEDURE PR_DBA_DISKSPACE
	@debug bit = 1,
	@FazCarga bit = 1
AS
/************************************************************************
 Autor: Equipe DBA\Jo�o Paulo Oliveira	
 Data de cria��o: 06/01/2023
 Data de Atualiza��o: 01/02/2023 - Valida��o SQL  
 Data de Atualiza��o: 17/11/2023 - Ajuste do Delete
 Funcionalidade: Displays the free space,free space percentage plus total drive size for a server.  
*************************************************************************/
SET NOCOUNT ON

DECLARE @hr int
DECLARE @fso int
DECLARE @drive char(1)
DECLARE @odrive int
DECLARE @TotalSize varchar(20)
DECLARE @MB bigint ; 

SET @MB = 1048576

CREATE TABLE #drives (drive char(1) PRIMARY KEY,
                      FreeSpace int NULL,
                      TotalSize int NULL)

INSERT #drives(drive,FreeSpace) 
EXEC master.dbo.xp_fixeddrives



EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

DECLARE dcur CURSOR LOCAL FAST_FORWARD
FOR SELECT drive from #drives
ORDER by drive

OPEN dcur

FETCH NEXT FROM dcur INTO @drive

WHILE @@FETCH_STATUS=0
BEGIN

        EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @drive
        IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
        
        EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @TotalSize OUT
        IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive
                        
        UPDATE #drives
        SET TotalSize=@TotalSize/@MB
        WHERE drive=@drive
        
        FETCH NEXT FROM dcur INTO @drive

END

CLOSE dcur
DEALLOCATE dcur

EXEC @hr=sp_OADestroy @fso
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

IF(@Debug = 1)
BEGIN
	--Select * from #drives
	SELECT drive,
				 FreeSpace as 'Livre(MB)',
				 TotalSize as 'Total(MB)',
				 CAST((FreeSpace/(TotalSize*1.0))*100.0 as int) as 'Livre(%)'
	FROM #drives
	ORDER BY drive
END


Insert BA_DBA.DBO.DBA_MONITOR_ESPA�O_DISK
SELECT drive,
			 FreeSpace as 'Livre(MB)',
			 TotalSize as 'Total(MB)',
			 CAST((FreeSpace/(TotalSize*1.0))*100.0 as int) as 'Livre(%)',
			 Getdate()
FROM #drives



DELETE FROM BA_DBA.DBO.DBA_MONITOR_ESPA�O_DISK WHERE Data_Hor�rio <= CONVERT(CHAR(8),DATEADD(WEEK, -1, GETDATE()),112)

DROP TABLE IF EXISTS #drives

RETURN
GO 
--DROP TABLE IF EXISTS DBA_MONITOR_ESPA�O_DISK
IF(OBJECT_ID('BA_DBA..DBA_MONITOR_ESPA�O_DISK') IS NULL) 
BEGIN
CREATE TABLE BA_DBA.DBO.DBA_MONITOR_ESPA�O_DISK (
	drive        CHAR(3), 
	FreeSpace    INT NULL,
	TotalSize    INT NULL, 
	Livre			   INT NULL,
	Data_Hor�rio DATETIME
)
END

--Select * from DBA_MONITOR_ESPA�O_DISK order by Data_Hor�rio desc

/*
Vai dar pau se n�o alterar essa configura��o.
sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
sp_configure 'Ole Automation Procedures', 1;  
GO  
RECONFIGURE;  
GO  
*/