DROP TRIGGER [tpo].[cifrarDatosPersonales]
go

CREATE OR ALTER TRIGGER [tpo].[cifrarDatosPersonales]
ON [tpo].[Persona]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    OPEN SYMMETRIC KEY ClaveTP
    DECRYPTION BY CERTIFICATE CertificadoTP;

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
        I.DNI,
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Nombre)),
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Apellido)),
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Email)),
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Telefono)),
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Cuenta)),
        I.IdTipo
    FROM
        inserted AS I;

    CLOSE SYMMETRIC KEY ClaveTP;
END;