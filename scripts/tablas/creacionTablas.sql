--verifica si existe la tabla
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'Consorcio')
BEGIN
	CREATE TABLE tpo.Consorcio (
	IdConsorcio INT NOT NULL,
	Nombre VARCHAR(100) NOT NULL,
	Direccion VARCHAR(120) NOT NULL,
	Unidades INT NOT NULL,
	M2total DECIMAL(10,2) NOT NULL,

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
	Anio INT NOT NULL,
	Total DECIMAL(12,2) NOT NULL,

	CONSTRAINT Pk_Expensa  PRIMARY KEY(IdExpensa), 
	CONSTRAINT Ck_Mes CHECK (Mes between 1 and 12 ),
	CONSTRAINT Ck_Anio CHECK (Anio BETWEEN 2000 AND 2026), 
	CONSTRAINT Ck_Total CHECK(Total>=0),
	CONSTRAINT Fk_Consorcio_Expensa FOREIGN KEY(IdConsorcio) REFERENCES tpo.Consorcio (IdConsorcio)
	);
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'Persona')
BEGIN
	CREATE TABLE tpo.Persona(
    DNI INT NOT NULL,
    Nombre VARCHAR(50) NOT NULL,
    Apellido VARCHAR(50) NOT NULL,
    Email VARCHAR(60) NOT NULL,
    Telefono VARCHAR(10) NOT NULL,
    Cuenta VARCHAR(22) NOT NULL,
    Tipo CHAR(1)

	CONSTRAINT Pk_DNI PRIMARY KEY (DNI) 
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'UnidadFuncional')
BEGIN
	CREATE TABLE tpo.UnidadFuncional (
	IdUf INT NOT NULL IDENTITY(1,1),
	IdConsorcio INT NOT NULL,
	IdPropietario INT NULL,
	IdInquilino INT NULL,
	NroUf INT NOT NULL,
	Cuenta VARCHAR(50) NULL,
	Piso VARCHAR(2) NOT NULL,
	Depto VARCHAR(3) NOT NULL,
	Coeficiente DECIMAL(5,4) NOT NULL,
	M2 DECIMAL(10,2) NOT NULL,

	CONSTRAINT Pk_IdUf PRIMARY KEY(IdUf),
	CONSTRAINT Ck_NroUf CHECK(NroUf>0),
	CONSTRAINT Ck_M2_Uf CHECK(M2>0),
	constraint fk_Propietario foreign key (IdPropietario) references tpo.Persona (DNI),
	constraint fk_Inquilino foreign key (IdInquilino) references tpo.Persona (DNI),
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
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'Proveedor')
BEGIN
	CREATE TABLE tpo.Proveedor (
	IdProveedor INT NOT NULL IDENTITY(1,1),
	IdConsorcio INT NOT NULL,
	Nombre VARCHAR (60) NOT NULL,
	Detalle VARCHAR(50) NULL,
	Tipo VARCHAR(50) NOT NULL,

	CONSTRAINT PkProveedor PRIMARY KEY(IdProveedor),
	CONSTRAINT Fk_Proveedor_Consorcio FOREIGN KEY(IdConsorcio) REFERENCES tpo.Consorcio (IdConsorcio)
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'GastoOrdinario')
BEGIN
	CREATE TABLE tpo.GastoOrdinario (
	IdGastoOrd INT NOT NULL IDENTITY(1,1),
	IdConsorcio INT NOT NULL,
	Mes varchar(10) NOT NULL,
	Categoria VARCHAR(50),
	IdProveedor INT  NULL, --Puede no aplicar
	--Detalle VARCHAR(50),
	Importe DECIMAL(10,2),

	CONSTRAINT PkGastoOrd PRIMARY KEY(IdGastoOrd),
	CONSTRAINT FkProveedor FOREIGN KEY(IdProveedor) REFERENCES tpo.Proveedor(IdProveedor),
	CONSTRAINT FK_Consorcio_GastoOrd FOREIGN KEY(IdConsorcio) REFERENCES tpo.Consorcio(IdConsorcio),
	CONSTRAINT Importe CHECK(Importe>0)
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'GastoExtraordinario')
BEGIN
	CREATE TABLE tpo.GastoExtraordinario (
	IdGastoExt INT NOT NULL IDENTITY(1,1),
	IdConsorcio INT NOT NULL,
	Mes INT NOT NULL,
	Descripcion VARCHAR(50),
	EnCuotas BIT NOT NULL, --1 si 0 no
	CuotaActual INT NULL, --Puede no aplicar en cuotas
	ImporteCuota DECIMAL(10,2) NULL,
	ImporteTotal DECIMAL(10,2) NOT NULL,

	CONSTRAINT PkGastoExt PRIMARY KEY(IdGastoExt),
	CONSTRAINT FKConsorcio_GastoExt FOREIGN KEY(IdConsorcio) REFERENCES tpo.Consorcio(IdConsorcio),
	CONSTRAINT CkCuotaActual CHECK(CuotaActual>=1),
	CONSTRAINT Mess CHECK(Mes between 1 and 12),
	CONSTRAINT ImporteTotal CHECK(ImporteTotal>0)
	);
END
go

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
	TABLE_SCHEMA = 'tpo' AND TABLE_NAME = 'DetalleExpensa')
BEGIN
	CREATE TABLE tpo.DetalleExpensa (
	IdDetalle INT IDENTITY(1,1),
	IdExpensa INT NOT NULL,
	TipoGasto CHAR(1) NOT NULL,  -- O=Ordinario, E=Extraordinario 
	Porcentaje DECIMAL(5,2) NOT NULL ,
	--SaldoAnterior
	--PagosRecibidos
	--Deuda
	--InteresesMora
	TotalOrd DECIMAL(12,2) NULL,
	TotalExt DECIMAL(12,2) NULL,
	Total DECIMAL(12,2) NOT NULL,

	CONSTRAINT PkIdDetalle PRIMARY KEY (IdDetalle),
	CONSTRAINT FK_DetalleExpensa_Expensa FOREIGN KEY (IdExpensa) REFERENCES tpo.Expensa(IdExpensa),
	CONSTRAINT Ck_TipoGasto CHECK(TipoGasto IN('O','E')),
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
	--MesPago INT NOT NULL,
	FechaPago DATE NOT NULL, 
	Cuenta varchar(22) NOT NULL,
	Importe DECIMAL(10,2) NOT NULL,

	CONSTRAINT Pk_Pago PRIMARY KEY (IdPago),
	CONSTRAINT Fk_Pago_DetalleExp FOREIGN KEY (IdDetalleExp) REFERENCES tpo.DetalleExpensa(IdDetalle),
	CONSTRAINT Fk_Pago_Uf FOREIGN KEY (IdUf) REFERENCES tpo.UnidadFuncional(IdUf),
	CONSTRAINT Ck_Importe CHECK (Importe > 0)
	);
END
go



