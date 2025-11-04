--API DOLAR
--Habilitamos acceso a datos externos

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;

use BDDATP
go



CREATE TABLE tpo.cotizacion_dolar (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATETIME DEFAULT GETDATE(),
    tipo VARCHAR(10),        -- 'oficial' o 'blue'
    compra DECIMAL(10,2),
    venta DECIMAL(10,2),
    promedio DECIMAL(10,2)
);
go

CREATE OR ALTER PROCEDURE tpo.sp_actualizar_cotizacion_dolar
AS
BEGIN
    DECLARE @Object INT,
            @ResponseText NVARCHAR(MAX),
            @Json NVARCHAR(MAX);

    -- Crear el objeto HTTP
    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
    EXEC sp_OAMethod @Object, 'open', NULL, 'GET', 
                     'https://api.bluelytics.com.ar/v2/latest', false;
    EXEC sp_OAMethod @Object, 'send';
    EXEC sp_OAGetProperty @Object, 'responseText', @ResponseText OUT;
    EXEC sp_OADestroy @Object;

    SET @Json = @ResponseText;

    -- Insertar los valores desde el JSON usando OPENJSON
    INSERT INTO cotizacion_dolar (tipo, compra, venta, promedio)
    SELECT 
        'oficial',
        JSON_VALUE(@Json, '$.oficial.value_buy'),
        JSON_VALUE(@Json, '$.oficial.value_sell'),
        JSON_VALUE(@Json, '$.oficial.value_avg')
    UNION ALL
    SELECT 
        'blue',
        JSON_VALUE(@Json, '$.blue.value_buy'),
        JSON_VALUE(@Json, '$.blue.value_sell'),
        JSON_VALUE(@Json, '$.blue.value_avg');
END;
GO
