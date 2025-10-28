--CREATE DATABASE Bddatp
go

use Bddatp
go

CREATE TABLE Consorcio (

IdConsorcio INT NOT NULL IDENTITY(1,1),
Nombre VARCHAR(100) NOT NULL,
Direccion VARCHAR(120) NOT NULL,
Unidades INT NOT NULL,
M2total DECIMAL(10,2) NOT NULL,

CONSTRAINT Pk_Consorcio  PRIMARY KEY(IdConsorcio),
CONSTRAINT CK_M2 CHECK(M2total>0)

);
go

CREATE TABLE Expensa (

IdExpensa INT NOT NULL IDENTITY(1,1),
IdConsorcio INT NOT NULL,
Mes INT NOT NULL,
Anio INT NOT NULL,
Total DECIMAL(12,2) NOT NULL,

CONSTRAINT Pk_Expensa  PRIMARY KEY(IdExpensa), 
CONSTRAINT Ck_Mes CHECK (Mes between 1 and 12 ),
CONSTRAINT Ck_Anio CHECK (Anio BETWEEN 2000 AND 2026), 
CONSTRAINT Ck_Total CHECK(Total>=0),
CONSTRAINT Fk_Consorcioo FOREIGN KEY(IdConsorcio) REFERENCES Consorcio(IdConsorcio)

);
go

CREATE TABLE UnidadFuncional (

IdUf INT NOT NULL IDENTITY(1,1),
IdConsorcio INT NOT NULL,
NroUf INT NOT NULL,
Cuenta VARCHAR(50) NOT NULL,
Piso VARCHAR(2) NOT NULL,
Depto VARCHAR(3) NOT NULL,
Coeficiente DECIMAL(5,4) NOT NULL,
M2 DECIMAL(10,2) NOT NULL,


CONSTRAINT Pk_IdUf PRIMARY KEY(IdUf),
CONSTRAINT Ck_NroUf CHECK(NroUf>0),
CONSTRAINT Ck_M2 CHECK(M2>0)

);
go

CREATE TABLE Cochera (

IdCochera INT NOT NULL IDENTITY(1,1),
IdUf INT NOT NULL,
M2Cochera DECIMAL(10,2),

CONSTRAINT FkCochera_Uf FOREIGN KEY(IdUf) REFERENCES UnidadFuncional(IdUf)

);
go

CREATE TABLE Baulera (

IdBaulera INT NOT NULL IDENTITY(1,1),
IdUf INT NOT NULL,
M2Cochera DECIMAL(10,2) NOT NULL,

CONSTRAINT FkBaulaera_Uf FOREIGN KEY(IdUf) REFERENCES UnidadFuncional(IdUf)

);
go

CREATE TABLE Proveedor (

IdProveedor INT NOT NULL IDENTITY(1,1),
Nombre VARCHAR (20) NOT NULL,
Cuit INT NOT NULL,
Tipo VARCHAR(20) NOT NULL,

CONSTRAINT PkProveedor PRIMARY KEY(IdProveedor)

);
go


CREATE TABLE GastoOrdinario (

IdGastoOrd INT NOT NULL IDENTITY(1,1),
IdConsorcio INT NOT NULL,
Mes INT NOT NULL,
Categoria VARCHAR(50),
IdProveedor INT  NULL, --Puede no aplicar
NroFactura INT  NULL,
Detalle VARCHAR(50),
Importe DECIMAL(10,2),

CONSTRAINT PkGastoOrd PRIMARY KEY(IdGastoOrd),
CONSTRAINT FkProveedor FOREIGN KEY(IdProveedor) REFERENCES Proveedor(IdProveedor),
CONSTRAINT FK_Consorcio FOREIGN KEY(IdConsorcio) REFERENCES Consorcio(IdConsorcio),
CONSTRAINT Mes CHECK(Mes between 1 and 12),
CONSTRAINT Importe CHECK(Importe>0)

);
go

CREATE TABLE GastoExtraordinario (

IdGastoExt INT NOT NULL IDENTITY(1,1),
IdConsorcio INT NOT NULL,
Mess INT NOT NULL,
Descripcion VARCHAR(50),
EnCuotas BIT NOT NULL, --1 si 0 no
CuotaActual INT NULL, --Puede no aplicar en cuotas
ImporteCuota DECIMAL(10,2) NULL,
ImporteTotal DECIMAL(10,2) NOT NULL,


CONSTRAINT PkGastoExt PRIMARY KEY(IdGastoExt),
CONSTRAINT FKConsorcio FOREIGN KEY(IdConsorcio) REFERENCES Consorcio(IdConsorcio),
CONSTRAINT CkCuotaActual CHECK(CuotaActual>=1),
CONSTRAINT Mess CHECK(Mess between 1 and 12),
CONSTRAINT ImporteTotal CHECK(ImporteTotal>0)

);
go

CREATE TABLE DetalleExpensa (

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
CONSTRAINT FK_DetalleExpensa_Expensa FOREIGN KEY (IdExpensa) REFERENCES Expensa(IdExpensa),
CONSTRAINT Ck_TipoGasto CHECK(TipoGasto IN('O','E')),
CONSTRAINT Porcentaje CHECK(Porcentaje>0),
CONSTRAINT Total CHECK(Total>0)

);
go


