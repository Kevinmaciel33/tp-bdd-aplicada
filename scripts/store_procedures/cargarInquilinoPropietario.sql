SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[cargarInquilinoPropietario]
    @RutaArchivoCSV NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
   
    DECLARE @BulkInsertSQL NVARCHAR(MAX);

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
        TRIM(nombre_csv),
        TRIM(apellido_csv),
        TRIM(email_csv),
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
END
