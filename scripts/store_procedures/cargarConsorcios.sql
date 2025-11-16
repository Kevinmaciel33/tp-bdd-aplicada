CREATE OR ALTER PROCEDURE [tpo].[sp_importarConsorcios]
    @RutaArchivoCSV NVARCHAR(255)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
   
    DECLARE @BulkInsertSQL NVARCHAR(MAX);
	DECLARE @ExisteArchivo INT;

    EXEC master.dbo.xp_fileexist @RutaArchivoCSV, @ExisteArchivo OUTPUT;

    IF @ExisteArchivo = 0
    BEGIN
        PRINT 'ERROR: El archivo no existe en la ruta especificada: ' + @RutaArchivoCSV;
        RETURN;
    END

    PRINT 'Archivo encontrado: ' + @RutaArchivoCSV;

    DROP TABLE IF EXISTS #consorcios_staging;

    CREATE TABLE #consorcios_staging (
        id_consorcio_csv CHAR(11),
        nombre_csv varchar(20),
        direccion_csv varchar(20),
        unidades_csv char(4),
		m2_csv varchar(10),
    );

    SET @BulkInsertSQL = 
        N'BULK INSERT #consorcios_staging ' +
        N'FROM ''' + @RutaArchivoCSV + N''' ' + 
        N'WITH ( ' +
        N'    FIELDTERMINATOR = '','', ' +
        N'    ROWTERMINATOR = ''\n'', ' +
        N'    FIRSTROW = 2, ' +
        N'    CODEPAGE = ''ACP'' ' +
        N');';

    BEGIN TRY
        EXECUTE sp_executesql @BulkInsertSQL;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        PRINT 'ERROR en BULK INSERT: ' + @ErrorMessage;
        RETURN;
    END CATCH

    INSERT INTO tpo.Consorcio (
        IdConsorcio,
        Nombre,
        Direccion,
        Unidades,
		M2total
    )
    SELECT
        RIGHT(id_consorcio_csv, len(id_consorcio_csv)-charindex(' ',id_consorcio_csv)),
        nombre_csv,
        direccion_csv,
        try_cast(unidades_csv as int),
		try_cast(m2_csv as decimal)
    FROM
        #consorcios_staging
    WHERE id_consorcio_csv IS NOT NULL;

    DECLARE @FilasInsertadas INT = @@ROWCOUNT;
    PRINT 'Proceso completado. Filas insertadas en Consorcio: ' + CAST(@FilasInsertadas AS VARCHAR(10));

	DROP TABLE IF EXISTS #consorcios_staging
END
