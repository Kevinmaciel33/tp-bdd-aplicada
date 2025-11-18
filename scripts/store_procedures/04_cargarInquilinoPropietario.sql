/*
Este script carga a la base de datos las personas con sus datos e indica propietario o inquilino.
18/11/2025
Com2900G10
Grupo 10
Bases de datos aplicadas
Integrantes:
-Kevin Maciel
-Marcos kouvach
-Agostina salas
-Keila Álvarez Da Silva*/
DROP FUNCTION IF EXISTS tpo.corregirTexto;
GO

CREATE FUNCTION tpo.corregirTexto (@texto VARCHAR(50))
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @resultado VARCHAR(50);

    SET @resultado = LTRIM(RTRIM(@texto));

    SET @resultado = REPLACE(@resultado, 'ñ', 'n');
    SET @resultado = REPLACE(@resultado, 'á', 'a');
    SET @resultado = REPLACE(@resultado, 'é', 'e');
    SET @resultado = REPLACE(@resultado, 'í', 'i');
    SET @resultado = REPLACE(@resultado, 'ó', 'o');
    SET @resultado = REPLACE(@resultado, 'ú', 'u');
    SET @resultado = REPLACE(@resultado, 'Á', 'A');
    SET @resultado = REPLACE(@resultado, 'É', 'E');
    SET @resultado = REPLACE(@resultado, 'Í', 'I');
    SET @resultado = REPLACE(@resultado, 'Ó', 'O');
    SET @resultado = REPLACE(@resultado, 'Ú', 'U');

    IF CHARINDEX('@', @resultado) > 0
    BEGIN
        SET @resultado = REPLACE(@resultado, ' ', '');
        SET @resultado = LOWER(@resultado);
    END
    ELSE
    BEGIN
        SET @resultado = UPPER(@resultado);
    END

    RETURN @resultado;
END
GO

CREATE OR ALTER PROCEDURE [tpo].[sp_cargarInquilinoPropietario]
    @RutaArchivoCSV NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

   
    DECLARE @ExisteArchivo INT;
    EXEC master.dbo.xp_fileexist @RutaArchivoCSV, @ExisteArchivo OUTPUT;

    IF @ExisteArchivo = 0
    BEGIN
        PRINT 'ERROR: El archivo no existe en la ruta especificada: ' + @RutaArchivoCSV;
        RETURN -1;
    END

    PRINT 'Archivo encontrado: ' + @RutaArchivoCSV;

    
    DROP TABLE IF EXISTS #persona_staging;

    CREATE TABLE #persona_staging (
        nombre_csv VARCHAR(60),
        apellido_csv VARCHAR(60),
        dni_csv VARCHAR(20),
        email_csv VARCHAR(100),
        telefono_csv VARCHAR(50),
        cvu_cbu_csv VARCHAR(50),
        tipo_inquilino_csv VARCHAR(5)
    );

    
    BEGIN TRY
        DECLARE @BulkInsertSQL NVARCHAR(MAX) =
        N'BULK INSERT #persona_staging
          FROM ''' + @RutaArchivoCSV + N'''
          WITH (
                DATAFILETYPE = ''char'',
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''0x0A'',
                FIRSTROW = 2,
                CODEPAGE = ''65001''
          );';

        EXEC sp_executesql @BulkInsertSQL;

    
        UPDATE #persona_staging
        SET nombre_csv        = TRIM(nombre_csv),
            apellido_csv      = TRIM(apellido_csv),
            dni_csv           = TRIM(dni_csv),
            email_csv         = TRIM(email_csv),
            telefono_csv      = TRIM(telefono_csv),
            cvu_cbu_csv       = TRIM(cvu_cbu_csv),
            tipo_inquilino_csv = TRIM(tipo_inquilino_csv);
    END TRY
    BEGIN CATCH
        PRINT 'ERROR en BULK INSERT: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;

    PRINT 'Insert Personas'
    ;WITH personas_sin_duplicados AS (
        SELECT
            tpo.corregirTexto(nombre_csv) AS nombre,
            tpo.corregirTexto(apellido_csv) AS apellido,
            TRY_CAST(dni_csv AS INT) AS dni,
            tpo.corregirTexto(email_csv) AS email,
            telefono_csv AS telefono,
            cvu_cbu_csv AS cuenta,

            CASE 
			WHEN TRIM(tipo_inquilino_csv) LIKE '%1%' THEN '1'
			ELSE '0'
			END AS tipo,

            ROW_NUMBER() OVER (
                PARTITION BY TRY_CAST(dni_csv AS INT)
                ORDER BY (SELECT NULL)
            ) AS rn
        FROM #persona_staging
        WHERE TRY_CAST(dni_csv AS INT) IS NOT NULL
    )

    INSERT INTO tpo.Persona (
        DNI,
        Nombre,
        Apellido,
        Email,
        Telefono,
        Cuenta,
        IdTipo
    )
    SELECT 
        p.dni,
        CONVERT(VARBINARY(MAX), P.Nombre),
        CONVERT(VARBINARY(MAX), P.apellido),
        CONVERT(VARBINARY(MAX), P.email),
        CONVERT(VARBINARY(MAX), P.telefono),
        CONVERT(VARBINARY(MAX), P.cuenta),
        P.tipo
    FROM personas_sin_duplicados p
    WHERE p.rn = 1
      AND p.dni IS NOT NULL
      AND NOT EXISTS (
            SELECT 1 
            FROM tpo.Persona pe
            WHERE pe.DNI = p.dni
      );

    PRINT 'Filas insertadas en Persona: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

    DROP TABLE IF EXISTS #persona_staging;

    SET NOCOUNT OFF;
END
GO
