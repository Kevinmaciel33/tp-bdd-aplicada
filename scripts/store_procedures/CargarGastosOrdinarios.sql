CREATE PROCEDURE CargarGastosOrdinariosExistentes
    @jsonFilePath NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    DECLARE @jsonContent NVARCHAR(MAX);

    -- 1. Leer el JSON desde el archivo
    BEGIN TRY
        SELECT @jsonContent = BulkColumn
        FROM OPENROWSET (BULK @jsonFilePath, SINGLE_CLOB) AS JsonFile;
    END TRY
    BEGIN CATCH
        THROW;
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RETURN;
    END CATCH

    IF @jsonContent IS NULL
    BEGIN
        RAISERROR('El archivo JSON está vacío o no se pudo leer el contenido.', 16, 1);
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- 2. Declarar la tabla temporal para el Unpivot
    CREATE TABLE #GastosJSONUnpivot (
        NombreConsorcio NVARCHAR(100),
        Mes NVARCHAR(50),
        CategoriaGasto NVARCHAR(100),
        ImporteStr NVARCHAR(50)
    );

    -- 3. Parsing e "Unpivot" de los datos del JSON (Set-Based)
    INSERT INTO #GastosJSONUnpivot (NombreConsorcio, Mes, CategoriaGasto, ImporteStr)
    SELECT
        json_data.[Nombre del consorcio],
        json_data.Mes,
        categoria.CategoriaGasto,
        categoria.ImporteStr
    FROM OPENJSON(@jsonContent)
    WITH (
        "Nombre del consorcio" NVARCHAR(100),
        "Mes" NVARCHAR(50),
        "BANCARIOS" NVARCHAR(50),
        "LIMPIEZA" NVARCHAR(50),
        "ADMINISTRACION" NVARCHAR(50),
        "SEGUROS" NVARCHAR(50),
        "GASTOS GENERALES" NVARCHAR(50),
        "SERVICIOS PUBLICOS-Agua" NVARCHAR(50),
        "SERVICIOS PUBLICOS-Luz" NVARCHAR(50)
    ) AS json_data
    CROSS APPLY (
        -- Unión de las columnas de gasto en filas
        SELECT 'BANCARIOS' AS CategoriaGasto, json_data.[BANCARIOS] AS ImporteStr
        UNION ALL SELECT 'LIMPIEZA', json_data.[LIMPIEZA]
        UNION ALL SELECT 'ADMINISTRACION', json_data.[ADMINISTRACION]
        UNION ALL SELECT 'SEGUROS', json_data.[SEGUROS]
        UNION ALL SELECT 'GASTOS GENERALES', json_data.[GASTOS GENERALES]
        UNION ALL SELECT 'SERVICIOS PUBLICOS-Agua', json_data.[SERVICIOS PUBLICOS-Agua]
        UNION ALL SELECT 'SERVICIOS PUBLICOS-Luz', json_data.[SERVICIOS PUBLICOS-Luz]
    ) AS categoria
    WHERE REPLACE(categoria.ImporteStr, ',', '.') > 0.00; 

    ---

    -- 4. Creación de tabla de mapeo de IDs y limpieza de datos
    CREATE TABLE #MapeoGastos (
        id_consorcio INT,
        id_proveedor INT,
        Mes NVARCHAR(50),
        CategoriaGasto NVARCHAR(100),
        Importe DECIMAL(18, 2)
    );

    -- 5. Mapeo final y conversión de datos
    -- **INNER JOIN** con Consorcio y Proveedor para obtener los IDs existentes
    INSERT INTO #MapeoGastos (id_consorcio, id_proveedor, Mes, CategoriaGasto, Importe)
    SELECT
        C.id_consorcio,
        P.id_proveedor,
        T.Mes,
        T.CategoriaGasto,
        CAST(REPLACE(T.ImporteStr, ',', '.') AS DECIMAL(18, 2))
    FROM #GastosJSONUnpivot AS T
    INNER JOIN consorcio AS C ON T.NombreConsorcio = C.nombre
    INNER JOIN proveedor AS P ON C.id_consorcio = P.id_consorcio AND T.CategoriaGasto = P.nombre;

    -- Comprobación si se encontró algún dato
    IF NOT EXISTS (SELECT 1 FROM #MapeoGastos)
    BEGIN
        RAISERROR('No se encontró el Consorcio y/o Proveedor correspondiente para la carga.', 16, 1);
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DROP TABLE #GastosJSONUnpivot;
        DROP TABLE #MapeoGastos;
        RETURN;
    END


    -- 6. Inserción/Actualización en la tabla 'Expensa' (Cabecera del período)
    MERGE Expensa AS Target
    USING (
        SELECT DISTINCT id_consorcio, Mes
        FROM #MapeoGastos
    ) AS Source (id_consorcio, mes)
    ON (Target.id_consorcio = Source.id_consorcio AND Target.mes = Source.mes)
    WHEN NOT MATCHED THEN
        INSERT (id_consorcio, mes, anio, total)
        VALUES (Source.id_consorcio, Source.mes, YEAR(GETDATE()), 0.00); 

    ---
    
    -- 7. Inserción de los datos en 'gastoOrdinario'
    INSERT INTO gastoOrdinario (id_consorcio, mes, categoria, id_proveedor, nro_factura, detalle, importe)
    SELECT
        id_consorcio,
        Mes,
        CategoriaGasto,
        id_proveedor,
        NULL, -- El campo no está en el JSON
        'Gasto de ' + CategoriaGasto,
        Importe
    FROM #MapeoGastos;

    ---
    
    -- 8. Limpieza
    DROP TABLE #GastosJSONUnpivot;
    DROP TABLE #MapeoGastos;

    COMMIT TRANSACTION;

END
GO