CREATE OR ALTER PROCEDURE [tpo].[sp_CargarGastosOrdinarios]
    @RutaArchivoJSON NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validar existencia del archivo
    DECLARE @ExisteArchivo INT;
    EXEC master.dbo.xp_fileexist @RutaArchivoJSON, @ExisteArchivo OUTPUT;
    IF @ExisteArchivo = 0
    BEGIN
        PRINT 'ERROR: El archivo no existe en la ruta: ' + @RutaArchivoJSON;
        RETURN -1;
    END
    PRINT 'Archivo encontrado. Leyendo JSON en variable...';

    -- 2. Cargar el JSON en una variable NVARCHAR(MAX)
    DECLARE @JsonContent NVARCHAR(MAX);
    DECLARE @SqlCmd NVARCHAR(MAX);
    
    SET @SqlCmd = N'
    SELECT @JsonContentOut = BulkColumn
    FROM OPENROWSET(BULK ''' + @RutaArchivoJSON + N''', SINGLE_CLOB) AS J;';
    
    BEGIN TRY
        EXEC sp_executesql @SqlCmd, N'@JsonContentOut NVARCHAR(MAX) OUTPUT', @JsonContent OUTPUT;
        PRINT 'Lectura de JSON en variable completada.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR al leer el archivo JSON con OPENROWSET.';
        PRINT 'Verifica los permisos de ADMINISTER BULK OPERATIONS.';
        PRINT ERROR_MESSAGE();
        RETURN -1;
    END CATCH;

    -- 3. Crear tabla de staging temporal
    DROP TABLE IF EXISTS #GastoStaging;
    CREATE TABLE #GastoStaging (
        IdConsorcio INT NOT NULL,
        Mes VARCHAR(10) NOT NULL,
        IdProveedor INT NULL,
        Categoria VARCHAR(50) NOT NULL,
        Importe DECIMAL(10,2) NULL
    );

    PRINT 'Parseando JSON con UNION ALL...';

    BEGIN TRY
        INSERT INTO #GastoStaging (
            IdConsorcio, Mes, IdProveedor, Categoria, Importe
        )

        SELECT
            c.IdConsorcio,
            TRIM(j.Mes) AS Mes,
            p.IdProveedor,
            'GASTOS BANCARIOS' AS Categoria,
            TRY_CAST(REPLACE(REPLACE(j.BANCARIOS, '.', ''), ',', '.') AS DECIMAL(10,2)) AS Importe
        FROM OPENJSON(@JsonContent) WITH (
                [Nombre del consorcio] VARCHAR(100), Mes VARCHAR(20), BANCARIOS VARCHAR(50) '$.BANCARIOS'
             ) AS j
        INNER JOIN tpo.Consorcio c ON TRIM(j.[Nombre del consorcio]) = c.Nombre
        LEFT JOIN tpo.Proveedor p ON p.IdConsorcio = c.IdConsorcio AND p.Tipo = 'GASTOS BANCARIOS'
        WHERE j.BANCARIOS IS NOT NULL AND j.BANCARIOS NOT IN ('0,00', '0.00')

        UNION ALL 

        SELECT
            c.IdConsorcio,
            TRIM(j.Mes) AS Mes,
            p.IdProveedor,
            'GASTOS DE LIMPIEZA' AS Categoria,
            TRY_CAST(REPLACE(REPLACE(j.LIMPIEZA, '.', ''), ',', '.') AS DECIMAL(10,2)) AS Importe
        FROM OPENJSON(@JsonContent) WITH (
                [Nombre del consorcio] VARCHAR(100), Mes VARCHAR(20), LIMPIEZA VARCHAR(50) '$.LIMPIEZA'
             ) AS j
        INNER JOIN tpo.Consorcio c ON TRIM(j.[Nombre del consorcio]) = c.Nombre
        LEFT JOIN tpo.Proveedor p ON p.IdConsorcio = c.IdConsorcio AND p.Tipo = 'GASTOS DE LIMPIEZA'
        WHERE j.LIMPIEZA IS NOT NULL AND j.LIMPIEZA NOT IN ('0,00', '0.00')

        UNION ALL 
        SELECT
            c.IdConsorcio,
            TRIM(j.Mes) AS Mes,
            p.IdProveedor,
            'GASTOS DE ADMINISTRACION' AS Categoria,
            TRY_CAST(REPLACE(REPLACE(j.ADMINISTRACION, '.', ''), ',', '.') AS DECIMAL(10,2)) AS Importe
        FROM OPENJSON(@JsonContent) WITH (
                [Nombre del consorcio] VARCHAR(100), Mes VARCHAR(20), ADMINISTRACION VARCHAR(50) '$.ADMINISTRACION'
             ) AS j
        INNER JOIN tpo.Consorcio c ON TRIM(j.[Nombre del consorcio]) = c.Nombre
        LEFT JOIN tpo.Proveedor p ON p.IdConsorcio = c.IdConsorcio AND p.Tipo = 'GASTOS DE ADMINISTRACION'
        WHERE j.ADMINISTRACION IS NOT NULL AND j.ADMINISTRACION NOT IN ('0,00', '0.00')

        UNION ALL

        SELECT
            c.IdConsorcio,
            TRIM(j.Mes) AS Mes,
            p.IdProveedor,
            'SEGUROS' AS Categoria,
            TRY_CAST(REPLACE(REPLACE(j.SEGUROS, '.', ''), ',', '.') AS DECIMAL(10,2)) AS Importe
        FROM OPENJSON(@JsonContent) WITH (
                [Nombre del consorcio] VARCHAR(100), Mes VARCHAR(20), SEGUROS VARCHAR(50) '$.SEGUROS'
             ) AS j
        INNER JOIN tpo.Consorcio c ON TRIM(j.[Nombre del consorcio]) = c.Nombre
        LEFT JOIN tpo.Proveedor p ON p.IdConsorcio = c.IdConsorcio AND p.Tipo = 'SEGUROS'
        WHERE j.SEGUROS IS NOT NULL AND j.SEGUROS NOT IN ('0,00', '0.00')
        
        UNION ALL

        SELECT
            c.IdConsorcio,
            TRIM(j.Mes) AS Mes,
            NULL AS IdProveedor, 
            'GASTOS GENERALES' AS Categoria,
            TRY_CAST(REPLACE(REPLACE(j.[GASTOS GENERALES], '.', ''), ',', '.') AS DECIMAL(10,2)) AS Importe
        FROM OPENJSON(@JsonContent) WITH (
                [Nombre del consorcio] VARCHAR(100), Mes VARCHAR(20), [GASTOS GENERALES] VARCHAR(50) '$."GASTOS GENERALES"'
             ) AS j
        INNER JOIN tpo.Consorcio c ON TRIM(j.[Nombre del consorcio]) = c.Nombre
        WHERE j.[GASTOS GENERALES] IS NOT NULL AND j.[GASTOS GENERALES] NOT IN ('0,00', '0.00')
        
        UNION ALL

        SELECT
            c.IdConsorcio,
            TRIM(j.Mes) AS Mes,
            p.IdProveedor,
            'SERVICIOS PUBLICOS-Agua' AS Categoria,
            TRY_CAST(REPLACE(REPLACE(j.[SERVICIOS PUBLICOS-Agua], '.', ''), ',', '.') AS DECIMAL(10,2)) AS Importe
        FROM OPENJSON(@JsonContent) WITH (
                [Nombre del consorcio] VARCHAR(100), Mes VARCHAR(20), [SERVICIOS PUBLICOS-Agua] VARCHAR(50) '$."SERVICIOS PUBLICOS-Agua"'
             ) AS j
        INNER JOIN tpo.Consorcio c ON TRIM(j.[Nombre del consorcio]) = c.Nombre
        LEFT JOIN tpo.Proveedor p ON p.IdConsorcio = c.IdConsorcio AND p.Tipo = 'SERVICIOS PUBLICOS' AND p.Nombre = 'AYSA'
        WHERE j.[SERVICIOS PUBLICOS-Agua] IS NOT NULL AND j.[SERVICIOS PUBLICOS-Agua] NOT IN ('0,00', '0.00')

        UNION ALL

        SELECT
            c.IdConsorcio,
            TRIM(j.Mes) AS Mes,
            p.IdProveedor,
            'SERVICIOS PUBLICOS-Luz' AS Categoria,
            TRY_CAST(REPLACE(REPLACE(j.[SERVICIOS PUBLICOS-Luz], '.', ''), ',', '.') AS DECIMAL(10,2)) AS Importe
        FROM OPENJSON(@JsonContent) WITH (
                [Nombre del consorcio] VARCHAR(100), Mes VARCHAR(20), [SERVICIOS PUBLICOS-Luz] VARCHAR(50) '$."SERVICIOS PUBLICOS-Luz"'
             ) AS j
        INNER JOIN tpo.Consorcio c ON TRIM(j.[Nombre del consorcio]) = c.Nombre
        LEFT JOIN tpo.Proveedor p ON p.IdConsorcio = c.IdConsorcio AND p.Tipo = 'SERVICIOS PUBLICOS' AND p.Nombre = 'EDENOR'
        WHERE j.[SERVICIOS PUBLICOS-Luz] IS NOT NULL AND j.[SERVICIOS PUBLICOS-Luz] NOT IN ('0,00', '0.00');

        PRINT 'Carga a Staging completada. ' + CAST(@@ROWCOUNT AS VARCHAR) + ' filas en staging.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR parseando el JSON o haciendo el UNION ALL.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS #GastoStaging;
        RETURN -1;
    END CATCH;
    
    BEGIN TRY
        INSERT INTO tpo.GastoOrdinario (
            IdConsorcio, Mes, IdProveedor, Categoria, Importe
        )
        SELECT
            s.IdConsorcio, s.Mes, s.IdProveedor, s.Categoria, s.Importe
        FROM #GastoStaging s
        WHERE NOT EXISTS (
            SELECT 1
            FROM tpo.GastoOrdinario g
            WHERE g.IdConsorcio = s.IdConsorcio
              AND g.Mes = s.Mes
              AND g.Categoria = s.Categoria
        );

        PRINT 'INSERT completado. ' + CAST(@@ROWCOUNT AS VARCHAR) + ' nuevos gastos insertados.';
    
    END TRY
    BEGIN CATCH
        PRINT 'ERROR durante el INSERT final en tpo.GastoOrdinario.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS #GastoStaging;
        RETURN -1;
    END CATCH;

    DROP TABLE IF EXISTS #GastoStaging;
    PRINT 'Proceso completado.';
    SET NOCOUNT OFF;
END
GO
