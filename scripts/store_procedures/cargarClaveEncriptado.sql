CREATE OR ALTER PROCEDURE tpo.cargarClaveEncriptado
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT * FROM sys.symmetric_keys 
        WHERE name = '##MS_DatabaseMasterKey##'
    )
    BEGIN
        PRINT 'Creando MASTER KEY...';
        CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'ClaveMaestra@2024';
    END
    ELSE
    BEGIN
        PRINT 'MASTER KEY ya existe.';
    END


    IF NOT EXISTS (
        SELECT * FROM sys.certificates 
        WHERE name = 'CertificadoTP'
    )
    BEGIN
        PRINT 'Creando CERTIFICADO...';
        CREATE CERTIFICATE CertificadoTP
        WITH SUBJECT = 'Certificado para cifrado de datos sensibles';
    END
    ELSE
    BEGIN
        PRINT 'CERTIFICADO ya existe.';
    END


    IF NOT EXISTS (
        SELECT * FROM sys.symmetric_keys 
        WHERE name = 'ClaveTP'
    )
    BEGIN
        PRINT 'Creando CLAVE SIMÉTRICA...';
        CREATE SYMMETRIC KEY ClaveTP
        WITH ALGORITHM = AES_256
        ENCRYPTION BY CERTIFICATE CertificadoTP;
    END
    ELSE
    BEGIN
        PRINT 'CLAVE SIMÉTRICA ya existe.';
    END

    PRINT '✔ Infraestructura de cifrado lista.';
END;
GO
