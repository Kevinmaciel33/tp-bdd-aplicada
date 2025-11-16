CREATE OR ALTER PROCEDURE [tpo].[sp_cargarProveedores]
    @RutaArchivoTXT NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExisteArchivo INT;
    EXEC master.dbo.xp_fileexist @RutaArchivoTXT, @ExisteArchivo OUTPUT;
    IF @ExisteArchivo = 0
    BEGIN
        PRINT 'ERROR: El archivo no existe en la ruta: ' + @RutaArchivoTXT;
        RETURN -1;
    END
    PRINT 'Archivo encontrado: ' + @RutaArchivoTXT;

    DROP TABLE IF EXISTS #prov_staging;
    CREATE TABLE #prov_staging (
        ColumnaVacia VARCHAR(100),
        Tipo VARCHAR(100),
        Nombre VARCHAR(100),
        Detalle VARCHAR(100),
        NombreConsorcio VARCHAR(100)
    );

    DECLARE @BulkInsertSQL NVARCHAR(MAX);
    SET @BulkInsertSQL = 
        N'BULK INSERT #prov_staging ' +
        N'FROM ''' + @RutaArchivoTXT + N''' ' +
        N'WITH ( ' +
        N'    FIELDTERMINATOR = '','', ' +  
        N'    ROWTERMINATOR = ''\n'', ' + 
        N'    FIRSTROW = 3, ' +          
        N'    CODEPAGE = ''ACP'' ' +
        N');';

    BEGIN TRY
        EXECUTE sp_executesql @BulkInsertSQL;
        PRINT 'BULK INSERT completado. ' + CAST(@@ROWCOUNT AS VARCHAR) + ' filas cargadas a staging.';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        PRINT 'ERROR en BULK INSERT: ' + @ErrorMessage;
        DROP TABLE IF EXISTS #prov_staging;
        RETURN -1;
    END CATCH;
    
    BEGIN TRY
        INSERT INTO tpo.Servicio(
            Categoria,
			Nombre,
			--Detalle,
			NombreConsorcio
        )
        SELECT
			TRIM(s.Tipo) AS Tipo,
			REPLACE(TRIM(s.Nombre), 'Ã“', 'O')
			+ CASE
					WHEN TRIM(s.Detalle) IS NOT NULL AND TRIM(s.Detalle) <> ''
					THEN ' - ' + TRIM(s.Detalle)
					ELSE ''
			END	
			as Nombre,
            --TRIM(s.Nombre) AS Nombre,
            --NULLIF(TRIM(Detalle2), '') AS Detalle,
            c.Nombre
        FROM #prov_staging s
        INNER JOIN tpo.Consorcio c ON TRIM(s.NombreConsorcio) = c.Nombre
        WHERE s.Tipo IS NOT NULL

        PRINT 'INSERT completado. ' + CAST(@@ROWCOUNT AS VARCHAR) + ' servicios insertados';

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessageInsert NVARCHAR(MAX) = ERROR_MESSAGE();
        PRINT 'ERROR: ' + @ErrorMessageInsert;
        DROP TABLE IF EXISTS #prov_staging;
        RETURN -1;
    END CATCH;

    DROP TABLE IF EXISTS #prov_staging;
    PRINT 'Proceso completado.';

END
GO
