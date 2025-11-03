CREATE OR ALTER PROCEDURE [tpo].[sp_cargarUnidadesFuncionales]
    @RutaArchivoTXT NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BulkInsertSQL NVARCHAR(MAX);
    DECLARE @ExisteArchivo INT;

    -- 1. Verificar si el archivo existe
    EXEC master.dbo.xp_fileexist @RutaArchivoTXT, @ExisteArchivo OUTPUT;
    IF @ExisteArchivo = 0
    BEGIN
        PRINT 'ERROR: El archivo no existe en la ruta especificada: ' + @RutaArchivoTXT;
        RETURN -1;
    END
    PRINT 'Archivo encontrado: ' + @RutaArchivoTXT;

    DROP TABLE IF EXISTS #uf_staging;
    CREATE TABLE #uf_staging (
        nombre_consorcio_csv VARCHAR(100),
        nro_uf_csv VARCHAR(10),
        piso_csv VARCHAR(10),
        depto_csv VARCHAR(10),
        coeficiente_csv VARCHAR(10),
        m2_uf_csv VARCHAR(10),
        bauleras_csv VARCHAR(5),
        cochera_csv VARCHAR(5),
        m2_baulera_csv VARCHAR(10),
        m2_cochera_csv VARCHAR(10)
    );

    SET @BulkInsertSQL = 
        N'BULK INSERT #uf_staging ' +
        N'FROM ''' + @RutaArchivoTXT + N''' ' +
        N'WITH ( ' +
        N'    FIELDTERMINATOR = ''\t'', ' + 
        N'    ROWTERMINATOR = ''\n'', ' +
        N'    FIRSTROW = 2, ' +
        N'    CODEPAGE = ''ACP'' ' +
        N');';

    BEGIN TRY
        EXECUTE sp_executesql @BulkInsertSQL;

        UPDATE #uf_staging SET
            nombre_consorcio_csv = TRIM(nombre_consorcio_csv),
            nro_uf_csv = TRIM(nro_uf_csv),
            piso_csv = TRIM(piso_csv),
            depto_csv = TRIM(depto_csv),
            coeficiente_csv = TRIM(coeficiente_csv),
            m2_uf_csv = TRIM(m2_uf_csv),
            bauleras_csv = TRIM(bauleras_csv),
            cochera_csv = TRIM(cochera_csv),
            m2_baulera_csv = TRIM(m2_baulera_csv),
            m2_cochera_csv = TRIM(m2_cochera_csv);
            
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        PRINT 'ERROR en BULK INSERT: ' + @ErrorMessage;
        DROP TABLE IF EXISTS #uf_staging;
        RETURN -1;
    END CATCH;

    BEGIN TRY
        INSERT INTO tpo.UnidadFuncional (
            IdConsorcio, 
            IdPropietario,      --null por ahora
            IdInquilino,        --null por ahora
            NroUf, 
            Cuenta,           --null por ahora
            Piso, 
            Depto, 
            Coeficiente, 
            M2
        )
        SELECT 
            c.IdConsorcio,
            NULL,            
            NULL,            
            TRY_CAST(s.nro_uf_csv AS INT),
            NULL,        
            s.piso_csv,
            s.depto_csv,
            TRY_CAST(REPLACE(s.coeficiente_csv, ',', '.') AS DECIMAL(5,4)),
            TRY_CAST(s.m2_uf_csv AS DECIMAL(10,2))
        FROM #uf_staging s
        INNER JOIN tpo.Consorcio c ON s.nombre_consorcio_csv = c.Nombre 

        DECLARE @UFsInsertadas INT = @@ROWCOUNT;
        PRINT 'Filas insertadas en tpo.UnidadFuncional: ' + CAST(@UFsInsertadas AS VARCHAR(10));
    END TRY

    BEGIN CATCH
        DECLARE @ErrorMessageUF NVARCHAR(MAX) = ERROR_MESSAGE();
        PRINT 'ERROR insertando en tpo.UnidadFuncional: ' + @ErrorMessageUF;
        DROP TABLE IF EXISTS #uf_staging;
        RETURN -1;
    END CATCH;

    DROP TABLE IF EXISTS #espacio_extra;
    SELECT 
        uf.IdUf,
        TRIM(s.bauleras_csv) AS bauleras_csv,
        TRIM(s.m2_baulera_csv) AS m2_baulera_csv,
        TRIM(s.cochera_csv) AS cochera_csv,
        TRIM(s.m2_cochera_csv) AS m2_cochera_csv
    INTO #espacio_extra
    FROM #uf_staging s
    INNER JOIN tpo.Consorcio c 
		ON TRIM(s.nombre_consorcio_csv) = c.Nombre
    INNER JOIN tpo.UnidadFuncional uf 
		ON c.IdConsorcio = uf.IdConsorcio AND TRY_CAST(TRIM(s.nro_uf_csv) AS INT) = uf.NroUf;
    
    PRINT 'Insertando Bauleras...';
    INSERT INTO tpo.EspacioExtra (
		IdUf, 
		TipoEspacio,
		M2EspacioExtra
		)
    SELECT 
        m.IdUf,
        'Baulera',
        TRY_CAST(REPLACE(m.m2_baulera_csv, ',', '.') AS DECIMAL(10,2))
    FROM #espacio_extra m
    WHERE m.bauleras_csv = 'SI' AND TRY_CAST(REPLACE(m.m2_baulera_csv, ',', '.') AS DECIMAL(10,2)) > 0;

    DECLARE @BaulerasInsertadas INT = @@ROWCOUNT;
    PRINT 'Bauleras insertadas: ' + CAST(@BaulerasInsertadas AS VARCHAR(10));

    PRINT 'Insertando Cocheras...';
    INSERT INTO tpo.EspacioExtra (
		IdUf, 
		TipoEspacio,
		M2EspacioExtra
	)
    SELECT 
        m.IdUf,
        'Cochera',
        TRY_CAST(REPLACE(m.m2_cochera_csv, ',', '.') AS DECIMAL(10,2))
    FROM #espacio_extra m
    WHERE m.cochera_csv = 'SI' AND TRY_CAST(REPLACE(m.m2_cochera_csv, ',', '.') AS DECIMAL(10,2)) > 0;
    
    DECLARE @CocherasInsertadas INT = @@ROWCOUNT;
    PRINT 'Cocheras insertadas: ' + CAST(@CocherasInsertadas AS VARCHAR(10));

    DROP TABLE IF EXISTS ##espacio_extra
    DROP TABLE IF EXISTS #uf_staging
    
    PRINT 'Proceso completado.'
END
GO
