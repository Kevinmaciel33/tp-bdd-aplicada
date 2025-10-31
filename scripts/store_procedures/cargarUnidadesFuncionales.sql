CREATE PROCEDURE [dbo].[sp_importarUnidadesDesdeTXT]
    @RutaArchivoTXT NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BulkInsertSQL NVARCHAR(MAX);
    DECLARE @ExisteArchivo INT;

    EXEC master.dbo.xp_fileexist @RutaArchivoTXT, @ExisteArchivo OUTPUT;

    IF @ExisteArchivo = 0
    BEGIN
        PRINT 'ERROR: El archivo no existe en la ruta especificada: ' + @RutaArchivoTXT;
        RETURN;
    END

    PRINT 'Archivo encontrado: ' + @RutaArchivoTXT;

    DROP TABLE IF EXISTS #uf_staging;

    CREATE TABLE #uf_staging (
        nombre_consorcio VARCHAR(50),
        nroUnidadFuncional int,
        piso VARCHAR(2),
        departamento CHAR(1),
        coeficiente VARCHAR(10),
        m2_unidad_funcional DECIMAL(10,2),
        bauleras VARCHAR(10),
        cocheras CHAR(2),
        m2_baulera CHAR(2),
        m2_cochera DECIMAL(10,2)
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
        EXEC sp_executesql @BulkInsertSQL;
    END TRY
    BEGIN CATCH
        PRINT 'ERROR en BULK INSERT: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;

    PRINT 'Datos cargados en staging correctamente.';

	UPDATE #uf_staging
    SET coeficiente = REPLACE(coeficiente, ',', '.')
    WHERE coeficiente LIKE '%,%';

    -- Insertar unidades funcionales
    INSERT INTO dbo.unidadFuncional (
		consorcio, 
		persona, 
		nro_uf, 
		cuenta, 
		piso, 
		depto, 
		coeficiente,
		m2
		)
    SELECT
        c.id_consorcio,
        null, --persona
        uf.nroUnidadFuncional,
        null, --cuenta
        uf.piso,
        uf.departamento,
        uf.coeficiente,
        uf.m2_unidad_funcional
    FROM #uf_staging uf
    INNER JOIN 
		dbo.consorcios c ON c.nombre = uf.nombre_consorcio

    DECLARE @FilasUF INT = @@ROWCOUNT;
    PRINT 'Filas insertadas en unidadFuncional: ' + CAST(@FilasUF AS VARCHAR(10));

    -- Insertar bauleras
    INSERT INTO dbo.baulera (
		uf, 
		m2
		)
    SELECT 
		u.id, 
		ufs.m2_baulera
    FROM #uf_staging ufs
    INNER JOIN 
		dbo.consorcios c ON c.nombre = ufs.nombre_consorcio
    INNER JOIN
		dbo.unidadFuncional u 
        ON u.nro_uf = ufs.nroUnidadFuncional AND u.consorcio = c.id_consorcio
    WHERE UPPER(ufs.bauleras) = 'SI'
      AND ufs.m2_baulera IS NOT NULL;

    DECLARE @FilasBauleras INT = @@ROWCOUNT;
    PRINT 'Filas insertadas en baulera: ' + CAST(@FilasBauleras AS VARCHAR(10));

    -- Insertar cocheras
    INSERT INTO dbo.cochera (
		uf, 
		m2)
    SELECT 
		u.id, 
		uf.m2_cochera
    FROM #uf_staging uf
    INNER JOIN dbo.consorcios c ON c.nombre = uf.nombre_consorcio
    INNER JOIN dbo.unidadFuncional u 
        ON u.nro_uf = uf.nroUnidadFuncional AND u.consorcio = c.id_consorcio
    WHERE UPPER(uf.cocheras) = 'SI'
      AND uf.m2_cochera IS NOT NULL;

    DECLARE @FilasCocheras INT = @@ROWCOUNT;
    PRINT 'Filas insertadas en cochera: ' + CAST(@FilasCocheras AS VARCHAR(10));

    DROP TABLE IF EXISTS #uf_staging;
END;