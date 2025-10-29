SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[cargarInquilinoPropietario]
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
        nombre_csv NVARCHAR(255),
        apellido_csv NVARCHAR(255),
        dni_csv int,
        email_csv VARCHAR(255),
        telefono_csv VARCHAR(50),
        cvu_cbu_csv VARCHAR(50),    
        tipo_inquilino_csv VARCHAR(10)
    );

    SET @BulkInsertSQL = 
        N'BULK INSERT #persona_staging ' +
        N'FROM ''' + @RutaArchivoCSV + N''' ' + 
        N'WITH ( ' +
        N'    FIELDTERMINATOR = '';'', ' +
        N'    ROWTERMINATOR = ''\n'', ' +
        N'    FIRSTROW = 1, ' +
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

    INSERT INTO dbo.persona (
        dni,
        nombre,
        apellido,
        email,
        telefono,
        cuenta,
        tipo
    )
    SELECT
        dni_csv,
        dbo.corregirTexto(nombre_csv),
        dbo.corregirTexto(apellido_csv),
        dbo.corregirTexto(email_csv),
        TRIM(telefono_csv),
        TRIM(cvu_cbu_csv) AS cuenta, 
        CASE
            WHEN TRIM(tipo_inquilino_csv) = '1' THEN 1
            ELSE 0
        END AS tipo
    FROM
        #persona_staging
    WHERE dni_csv IS NOT NULL;

    DECLARE @FilasInsertadas INT = @@ROWCOUNT;
    PRINT 'Proceso de importación completado. Filas insertadas en dbo.persona: ' + CAST(@FilasInsertadas AS VARCHAR(10));
	
	DROP TABLE IF EXISTS #persona_staging;

END
create function corregirTexto (@texto varchar(50))
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
