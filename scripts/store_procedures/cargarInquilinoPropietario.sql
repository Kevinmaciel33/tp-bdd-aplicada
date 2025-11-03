CREATE OR ALTER PROCEDURE [tpo].[sp_cargarInquilinoPropietario]
    @RutaArchivoCSV NVARCHAR(255)
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

    DROP TABLE IF EXISTS #persona_staging;

    CREATE TABLE #persona_staging (
        nombre_csv VARCHAR(60),
        apellido_csv VARCHAR(60),
        dni_csv varchar(20),
        email_csv VARCHAR(100),
        telefono_csv VARCHAR(50),
        cvu_cbu_csv VARCHAR(50),    
        tipo_inquilino_csv varchar(5)
    );

    SET @BulkInsertSQL = 
        N'BULK INSERT #persona_staging ' +
        N'FROM ''' + @RutaArchivoCSV + N''' ' + 
        N'WITH ( ' +
        N'    FIELDTERMINATOR = '';'', ' +
        N'    ROWTERMINATOR = ''\n'', ' +
        N'    FIRSTROW = 2, ' +
        N'    CODEPAGE = ''ACP'' ' +
        N');';

    BEGIN TRY
        EXECUTE sp_executesql @BulkInsertSQL;

		UPDATE #persona_staging SET
            nombre_csv = TRIM(nombre_csv),
            apellido_csv = TRIM(apellido_csv),
            dni_csv = TRIM(dni_csv),
            email_csv = TRIM(email_csv),
            telefono_csv = TRIM(telefono_csv),
            cvu_cbu_csv = TRIM(cvu_cbu_csv),
            tipo_inquilino_csv = TRIM(tipo_inquilino_csv);

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        PRINT 'ERROR en BULK INSERT: ' + @ErrorMessage;
        RETURN;
    END CATCH;

	--SELECT TOP 10 * FROM #persona_staging;
	WITH personas_sin_duplicados AS (
		SELECT
			tpo.corregirTexto(nombre_csv) AS nombre,
			tpo.corregirTexto(apellido_csv) AS apellido,
			TRY_CAST(dni_csv AS INT) AS dni,
			tpo.corregirTexto(email_csv) AS email,
			telefono_csv AS telefono,
			cvu_cbu_csv AS cuenta,
			CASE
				WHEN tipo_inquilino_csv = '1' THEN 1 
				ELSE 0 
			END AS tipo,
			ROW_NUMBER() OVER (PARTITION BY TRY_CAST(dni_csv AS INT) ORDER BY (SELECT NULL)) AS rn
		FROM #persona_staging
		WHERE TRY_CAST(dni_csv AS INT) IS NOT NULL
	)

		INSERT INTO tpo.Persona (
            Nombre, 
            Apellido,
            DNI,
            Email,
            Telefono,
            Cuenta,
            Tipo
        )
		SELECT p.nombre, 
            p.apellido, 
            p.dni, 
            p.email, 
            p.telefono, 
            p.cuenta, 
            p.tipo
		FROM personas_sin_duplicados p
		WHERE rn = 1  -- solo una fila por cada dni
		AND p.dni IS NOT NULL
		AND NOT EXISTS (
			SELECT 1 FROM tpo.Persona pe WHERE pe.DNI = p.dni
	);

    DECLARE @FilasInsertadas INT = @@ROWCOUNT;
    PRINT 'Proceso completado. Filas insertadas en Persona: ' + CAST(@FilasInsertadas AS VARCHAR(10));

	DROP TABLE IF EXISTS #persona_staging;
END
go
create or alter function tpo.corregirTexto (@texto varchar(50))
returns varchar(50)
as
begin
	declare @resultado varchar(50);

	SET @resultado = LTRIM(RTRIM(@texto)); --saca espacios al inicio y al final
    SET @resultado = REPLACE(@resultado, 'ñ', 'n'); -- cambia ñ por n
	---saca las tildes
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
    

	if  charindex('@',@resultado) > 0 --si es email elimina espacios intermedios, y lo pone en minuscula
	begin
		SET @resultado = REPLACE(@resultado, ' ', '');
		SET @resultado = LOWER(@resultado);
	end
	else -- si es texto normal lo pone todo mayuscula
		SET @resultado = UPPER(@resultado);


	return @resultado
end
go
