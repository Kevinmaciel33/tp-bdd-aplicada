--INDICES PARA OPTIMIZAR REPORTES

--Reporte 1 y 2: Búsqueda y agrupamiento por fecha de pago y consorcio
CREATE INDEX IX_Pago_FechaPago ON dbo.Pago(FechaPago);
GO
CREATE INDEX IX_Expensa_IdConsorcio ON dbo.Expensa(IdConsorcio);
GO

--Reporte 2 y 3: Filtrado por tipo de gasto
CREATE INDEX IX_DetalleExpensa_TipoGasto ON dbo.DetalleExpensa(TipoGasto);
GO

--Reporte 4: Agrupación por mes en gastos ordinarios
CREATE INDEX IX_GastoOrdinario_Mes ON dbo.GastoOrdinario(Mes);
GO

--Reporte 5: Relación Persona - UnidadFuncional - Pagos
CREATE INDEX IX_Persona_Cuenta ON dbo.Persona(Cuenta);
GO
CREATE INDEX IX_Pago_IdUf ON dbo.Pago(IdUf);
GO
CREATE INDEX IX_DetalleExpensa_IdExpensa ON dbo.DetalleExpensa(IdExpensa);
GO

--Reporte 6: Días entre pagos (IdUf + FechaPago)
CREATE INDEX IX_Pago_IdUf_FechaPago ON dbo.Pago(IdUf, FechaPago);
GO

--Reporte 1: va a los pagos y expensas relevantes
--Reporte 2: indice compuesto
--Reportes 2 y 3: encuentra rapidamente solo los ordinarios o extraordinarios
--Reporte 4: agrupa por mes, al estar indexado por mes agrupa mas rapido
--Reporte 5: como hay multiples joins entre estas tablas: aceleran las busquedas por cada join
--Busca persona x cuenta
--Busca pagos x uf
--Busca detalles x expensa
--Reporte 6:indice compuesto, el reporte filtra por iduf y ordena por fechapago
--esto hace que sea nas rapido en un solo indice