--API DOLAR

CREATE TABLE cotizacion_dolar (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATETIME DEFAULT GETDATE(),
    tipo VARCHAR(10),        -- 'oficial' o 'blue'
    compra DECIMAL(10,2),
    venta DECIMAL(10,2),
    promedio DECIMAL(10,2)
);

CREATE OR ALTER PROCEDURE sp_actualizar_cotizacion_dolar
AS
BEGIN
    DECLARE @Json NVARCHAR(MAX);

    -- Leer el archivo JSON local
    SELECT @Json = BulkColumn
    FROM OPENROWSET(BULK 'C:/tp-bdd-aplicada/scripts/Reportes/dolar.json', SINGLE_CLOB) AS j;

    -- Insertar los valores desde el JSON
    INSERT INTO cotizacion_dolar (tipo, compra, venta, promedio)
    SELECT 
        'oficial',
        TRY_CAST(JSON_VALUE(@Json, '$.oficial.value_buy') AS DECIMAL(10,2)),
        TRY_CAST(JSON_VALUE(@Json, '$.oficial.value_sell') AS DECIMAL(10,2)),
        TRY_CAST(JSON_VALUE(@Json, '$.oficial.value_avg') AS DECIMAL(10,2))
    UNION ALL
    SELECT 
        'blue',
        TRY_CAST(JSON_VALUE(@Json, '$.blue.value_buy') AS DECIMAL(10,2)),
        TRY_CAST(JSON_VALUE(@Json, '$.blue.value_sell') AS DECIMAL(10,2)),
        TRY_CAST(JSON_VALUE(@Json, '$.blue.value_avg') AS DECIMAL(10,2));
END;
GO




