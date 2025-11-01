




CREATE PROCEDURE [dbo].[cargarInquilinoPropietarioUF]
    @RutaArchivoCSV NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BulkInsertSQL NVARCHAR(MAX);
    DECLARE @ExisteArchivo INT;

    -- Verifica que el archivo exista
    EXEC master.dbo.xp_fileexist @RutaArchivoCSV, @ExisteArchivo OUTPUT;

    IF @ExisteArchivo = 0
    BEGIN
        PRINT 'ERROR: El archivo no existe en la ruta especificada: ' + @RutaArchivoCSV;
        RETURN;
    END

    PRINT 'Archivo encontrado: ' + @RutaArchivoCSV;

    DROP TABLE IF EXISTS #UF_staging;

    -- Crea tabla temporal para staging
    CREATE TABLE #UF_staging (
        cvu_cbu_csv VARCHAR(50),
        nombreConsorcio_csv NVARCHAR(100),
        nroUF_csv INT,
        piso_csv VARCHAR(5),
        depto_csv VARCHAR(5)
    );

    -- Carga el CSV a la tabla temporal
    SET @BulkInsertSQL = 
        N'BULK INSERT #UF_staging ' +
        N'FROM ''' + @RutaArchivoCSV + N''' ' +
        N'WITH ( ' +
        N'    FIELDTERMINATOR = ''|'', ' +   -- separador de columnas
        N'    ROWTERMINATOR = ''\n'', ' +
        N'    FIRSTROW = 2, ' +              -- salta el encabezado
        N'    CODEPAGE = ''ACP'' ' +
        N');';

    BEGIN TRY
        EXEC sp_executesql @BulkInsertSQL;
    END TRY
    BEGIN CATCH
        PRINT 'ERROR al cargar el archivo: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;

    DECLARE @IdConsorcio INT;

    -- Tomamos el consorcio del CSV
    SELECT TOP 1 @IdConsorcio = c.IdConsorcio
    FROM Consorcio c
    JOIN #UF_staging s ON c.Nombre = s.nombreConsorcio_csv;

    IF @IdConsorcio IS NULL
    BEGIN
        PRINT 'ERROR: El consorcio no existe en la base de datos.';
        RETURN;
    END

    -- Inserta las unidades funcionales
    INSERT INTO UnidadFuncional (IdConsorcio, NroUf, Cuenta, Piso, Depto, Coeficiente, M2)
    SELECT
        @IdConsorcio,
        nroUF_csv,
        cvu_cbu_csv,
        piso_csv,
        depto_csv,
        0.0,   -- coeficiente se calculará aparte
        0.0    -- m2 se puede cargar en otro proceso
    FROM #UF_staging;

    DECLARE @FilasInsertadas INT = @@ROWCOUNT;
    PRINT 'Importación completada. Filas insertadas en UnidadFuncional: ' + CAST(@FilasInsertadas AS VARCHAR(10));

    DROP TABLE IF EXISTS #UF_staging;
END
GO




