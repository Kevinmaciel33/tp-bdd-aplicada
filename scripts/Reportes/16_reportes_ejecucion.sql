--INVOCACIÓN A LOS SP DE REPORTES

-- Reporte 1
EXEC tpo.sp_reporte_flujo_caja 
    @FechaInicio = '2025-01-01', 
    @FechaFin = '2025-12-31', 
    @IdConsorcio = 1;
GO

-- Reporte 2
EXEC tpo.sp_reporte_recaudacion_mensual 
    @Anio = 2025, 
    @IdConsorcio = 1;
GO

-- Reporte 3
EXEC tpo.sp_reporte_recaudacion_desA 
    @FechaInicio = '2025-01-01', 
    @FechaFin = '2025-12-31', 
    @IdConsorcio = 1;
GO

-- Reporte 4
EXEC tpo.sp_reporte_top5_gastos_ingresos 
    @IdConsorcio = 1;
GO

-- Reporte 5
EXEC tpo.sp_reporte_top3_morosidad;
GO

-- Reporte 6
EXEC tpo.sp_reporte_dias_entre_pagos 
    @IdConsorcio = 1,
    @IdUf = 1,
    @FechaDesde = '2025-01-01';
GO


