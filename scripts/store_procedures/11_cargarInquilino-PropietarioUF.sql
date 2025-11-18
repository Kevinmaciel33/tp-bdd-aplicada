CREATE OR ALTER PROCEDURE [tpo].[sp_agregarCuentasUF]
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

    DROP TABLE IF EXISTS #staging_cuentas_uf;
    CREATE TABLE #staging_cuentas_uf (
        CVU_CBU_Raw VARCHAR(50),
        NombreConsorcio_Raw VARCHAR(100),
        NroUf_Raw VARCHAR(10),
        Piso_Raw VARCHAR(10),
        Depto_Raw VARCHAR(10)
    );

    DECLARE @BulkInsertSQL NVARCHAR(MAX);
    SET @BulkInsertSQL = 
        N'BULK INSERT #staging_cuentas_uf ' +
        N'FROM ''' + @RutaArchivoTXT + N''' ' +
        N'WITH ( ' +
        N'    FIELDTERMINATOR = ''|'', ' +  
        N'    ROWTERMINATOR = ''\n'', ' + 
        N'    FIRSTROW = 2, ' +           
        N'    CODEPAGE = ''ACP'' ' +
        N');';

    BEGIN TRY
        EXECUTE sp_executesql @BulkInsertSQL;
        PRINT 'BULK INSERT a Staging completado. ' + CAST(@@ROWCOUNT AS VARCHAR) + ' filas cargadas.';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        PRINT 'ERROR en BULK INSERT: ' + @ErrorMessage;
        PRINT 'Revisa los permisos, el delimitador (|) y el ROWTERMINATOR (fin de l�nea).';
        DROP TABLE IF EXISTS #staging_cuentas_uf;
        RETURN -1;
    END CATCH;

    
    BEGIN TRY
        UPDATE uf
        SET
            uf.Cuenta = TRIM(s.CVU_CBU_Raw)
        FROM
            tpo.UnidadFuncional AS uf
        INNER JOIN tpo.Consorcio AS c ON uf.IdConsorcio = c.IdConsorcio
        INNER JOIN #staging_cuentas_uf AS s ON
            c.Nombre = TRIM(s.NombreConsorcio_Raw)
            AND uf.NroUf = TRY_CAST(TRIM(s.NroUf_Raw) AS INT)
            AND uf.Piso = TRIM(s.Piso_Raw)
            AND uf.Depto = TRIM(s.Depto_Raw);

        PRINT 'UPDATE completado. ' + CAST(@@ROWCOUNT AS VARCHAR) + ' filas actualizadas en tpo.UnidadFuncional.';

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessageUpdate NVARCHAR(MAX) = ERROR_MESSAGE();
        PRINT 'ERROR durante el UPDATE: ' + @ErrorMessageUpdate;
        DROP TABLE IF EXISTS #staging_cuentas_uf;
        RETURN -1;
    END CATCH;

    DROP TABLE IF EXISTS #staging_cuentas_uf;
    PRINT 'Proceso completado .';
    SET NOCOUNT OFF;
END
GO
