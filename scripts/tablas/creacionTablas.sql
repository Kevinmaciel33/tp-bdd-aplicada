--verifica si existe la tabla
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'Consorcio')
BEGIN
	CREATE TABLE tpo.Consorcio (
	IdConsorcio INT NOT NULL,
	Nombre VARCHAR(100) NOT NULL,
	Direccion VARCHAR(120) NOT NULL,
	Unidades INT NOT NULL,
	M2total DECIMAL(10,2) NOT NULL

	CONSTRAINT Pk_Consorcio  PRIMARY KEY(IdConsorcio),
	CONSTRAINT CK_M2 CHECK(M2total>0)
	)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'Expensa')
BEGIN
	CREATE TABLE tpo.Expensa (
	IdExpensa INT NOT NULL IDENTITY(1,1),
	IdConsorcio INT NOT NULL,
	Mes INT NOT NULL,
	FechaGeneracion DATE NOT NULL,
	vto1 DATE NOT NULL,
	vto2 DATE NOT NULL,
	SaldoAnterior DECIMAL(12,2) NOT NULL,
	IngresosPagoTermino DECIMAL(12,2) NOT NULL,
	IngresosPagoAdeudado DECIMAL(12,2) NOT NULL,
	IngresosPagoAdelantado DECIMAL(12,2) NOT NULL,
	Egresos DECIMAL(12,2) NOT NULL,
	SaldoCierre DECIMAL(12,2) NOT NULL,

	CONSTRAINT Pk_Expensa  PRIMARY KEY(IdExpensa), 
	CONSTRAINT Ck_Mes CHECK (Mes between 1 and 12 ),
	CONSTRAINT Fk_Consorcio_Expensa FOREIGN KEY(IdConsorcio) REFERENCES tpo.Consorcio (IdConsorcio)
	);
END
GO
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'TipoPersona')
BEGIN
	CREATE TABLE tpo.TipoPersona(
    IdTipo CHAR(1) NOT NULL,
    Descripcion CHAR(12) NOT NULL

	CONSTRAINT Pk_Tipo_Persona PRIMARY KEY (IdTipo),
	CONSTRAINT Ck_Tipo_Persona CHECK(IdTipo IN('0','1'))
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'Persona')
BEGIN
	CREATE TABLE tpo.Persona(
    DNI INT NOT NULL,
    Nombre VARBINARY(MAX) NOT NULL,
    Apellido VARBINARY(MAX) NOT NULL,
    Email VARBINARY(MAX) NOT NULL,
    Telefono VARBINARY(MAX) NOT NULL,
    Cuenta VARBINARY(MAX) NOT NULL,
    IdTipo CHAR(1)
	CONSTRAINT Pk_DNI PRIMARY KEY (DNI)
	CONSTRAINT FK_Persona_Tipo FOREIGN KEY (IdTipo) REFERENCES tpo.TipoPersona (IdTipo)
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'UnidadFuncional')
BEGIN
	CREATE TABLE tpo.UnidadFuncional (
	IdUf INT NOT NULL IDENTITY(1,1),
	IdConsorcio INT NOT NULL,
	NroUf INT NOT NULL,
	Cuenta VARCHAR(50) NULL,
	Piso VARCHAR(2) NOT NULL,
	Depto VARCHAR(3) NOT NULL,
	Coeficiente DECIMAL(5,4) NOT NULL,
	M2 DECIMAL(10,2) NOT NULL,

	CONSTRAINT Pk_IdUf PRIMARY KEY(IdUf),
	CONSTRAINT Ck_NroUf CHECK(NroUf>0),
	CONSTRAINT Ck_M2_Uf CHECK(M2>0),
	CONSTRAINT Fk_Consorcio_UF FOREIGN KEY(IdConsorcio) REFERENCES tpo.Consorcio (IdConsorcio)
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'EspacioExtra')
BEGIN
	CREATE TABLE tpo.EspacioExtra (
	Id INT NOT NULL IDENTITY(1,1),
	IdUf INT NOT NULL,
	TipoEspacio VARCHAR(7) NOT NULL,
	M2EspacioExtra DECIMAL(10,2)

	CONSTRAINT Fk_UnidadFuncional_EspExt FOREIGN KEY(IdUf) REFERENCES tpo.UnidadFuncional(IdUf),
	CONSTRAINT Ck_TipoEspacio CHECK (TipoEspacio IN ('Baulera', 'Cochera'))
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'Servicio')
BEGIN
	CREATE TABLE tpo.Servicio (
	IdServicio INT NOT NULL IDENTITY(1,1),
	Categoria VARCHAR(50), --GASTOS BANCARIOS
	Nombre VARCHAR(60), --BANCO CREDICOOP
	Detalle VARCHAR(50), --
	NombreConsorcio VARCHAR(20) NULL, --Aclarar el nombre del consorcio aunque no sea FK

	CONSTRAINT Pk_Servicio PRIMARY KEY(IdServicio),
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'Factura')
BEGIN
	CREATE TABLE tpo.Factura (
	IdFactura INT NOT NULL IDENTITY(1,1),
	IdExpensa INT NULL,
	IdServicio INT NULL,
	NombreConsorcio VARCHAR(20) NULL, --Aclarar el nombre del consorcio aunque no sea FK
	Mes VARCHAR(10) NOT NULL,
	Detalle VARCHAR(60) NULL, --BANCARIOS
	Tipo CHAR(1) NOT NULL, --O (ordinario)
	Importe DECIMAL(10,2) NOT NULL,
	EnCuotas CHAR(1) NOT NULL, --1 si 0 no
	CuotaActual INT NULL, --Puede no aplicar en cuotas
	CuotasTotales INT NULL, --Puede no aplicar en cuotas

	CONSTRAINT Pk_Factura PRIMARY KEY(IdFactura),
	CONSTRAINT Fk_Factura_Expensa FOREIGN KEY(IdExpensa) REFERENCES tpo.Expensa (IdExpensa),
	CONSTRAINT Fk_Factura_Servicio FOREIGN KEY (IdServicio) REFERENCES tpo.Servicio (IdServicio),
	CONSTRAINT Ck_Tipo_Gasto CHECK(Tipo IN('O','E'))
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'DetalleExpensa')
BEGIN
	CREATE TABLE tpo.DetalleExpensa (
	IdDetalle INT IDENTITY(1,1),
	IdExpensa INT NOT NULL,
	IdUf INT,
	Porcentaje DECIMAL(5,2) NOT NULL ,
	SaldoAnterior DECIMAL(12,2),
	PagosRecibidos DECIMAL(12,2),
	Deuda DECIMAL(12,2),
	InteresesMora DECIMAL(12,2),
	TotalOrd DECIMAL(12,2) NULL,
	TotalExt DECIMAL(12,2) NULL,
	Total DECIMAL(12,2) NOT NULL,

	CONSTRAINT PkIdDetalle PRIMARY KEY (IdDetalle),
	CONSTRAINT FK_DetalleExpensa_Expensa FOREIGN KEY (IdExpensa) REFERENCES tpo.Expensa(IdExpensa),
	CONSTRAINT FK_DetalleExpensa_IdUf FOREIGN KEY (IdUf) REFERENCES tpo.UnidadFuncional(IdUf),
	--CONSTRAINT Ck_TipoGasto CHECK(TipoGasto IN('O','E')),
	CONSTRAINT Porcentaje CHECK(Porcentaje>0),
	CONSTRAINT Total CHECK(Total>0)
);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'Pago')
BEGIN
	CREATE TABLE tpo.Pago (
	IdPago INT NOT NULL,
	IdDetalleExp INT NULL,
	IdUf INT NULL,
	IdConsorcio INT NULL,
	FechaPago DATE NOT NULL, 
	Cuenta varchar(22) NOT NULL,
	Importe DECIMAL(10,2) NOT NULL,

	CONSTRAINT Pk_Pago PRIMARY KEY (IdPago),
	CONSTRAINT Fk_Pago_DetalleExp FOREIGN KEY (IdDetalleExp) REFERENCES tpo.DetalleExpensa(IdDetalle),
	CONSTRAINT Ck_Importe CHECK (Importe > 0)
	);
END
go
