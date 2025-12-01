USE DF_Eval_Junior;
GO

PRINT '=== INICIO DE PRUEBAS DE VALIDACION ===';
PRINT 'Objeto: Validar SP sp_AltaEjecucionPipeline y Trigger trg_ControlarEjecucionPipeline';

-- Configuración inicial
DECLARE @newId INT;
-- Usamos un ID de Pipeline que sabemos que existe (del script de setup original, id=10)
DECLARE @idPipelineValido INT = 10; 

-----------------------------------------------------------------------------------
-- PRUEBA 1: Validación del Procedure (Pipeline Inexistente)
-- Resultado esperado: Error 51000 capturado.
-----------------------------------------------------------------------------------
PRINT '';
PRINT '-----------------------------------------------------------------';
PRINT '--- PRUEBA 1: Intentar insertar con un Pipeline Inexistente (99999) ---';
PRINT '-----------------------------------------------------------------';

BEGIN TRY
    EXEC dbo.sp_AltaEjecucionPipeline
        @idPipeline     = 99999, -- Este ID no debería existir
        @fechaInicio    = '2025-11-30 10:00',
        @fechaFin       = '2025-11-30 10:05',
        @filasLeidas    = 1000,
        @filasCargadas  = 1000,
        @estado         = 'OK',
        @newIdEjecucion = @newId OUTPUT;
    
    PRINT '[FALLO] El procedimiento debió lanzar un error y continuó.';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000
    BEGIN
        PRINT '[EXITO] Se capturó el error personalizado esperado.';
        PRINT '        Mensaje: ' + ERROR_MESSAGE();
    END
    ELSE
    BEGIN
        PRINT '[ATENCION] Se capturó un error, pero no el 51000.';
        PRINT '           Error: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    END
END CATCH;

-----------------------------------------------------------------------------------
-- PRUEBA 2: Trigger Caso Normal (>= 80%)
-- Resultado esperado: Inserción exitosa, SIN alerta.
-----------------------------------------------------------------------------------
PRINT '';
PRINT '-----------------------------------------------------------------';
PRINT '--- PRUEBA 2: Ejecución Correcta (100 filas leídas, 100 cargadas -> 100%) ---';
PRINT '-----------------------------------------------------------------';

BEGIN TRY
    SET @newId = NULL;
    EXEC dbo.sp_AltaEjecucionPipeline
        @idPipeline     = @idPipelineValido,
        @fechaInicio    = '2025-11-30 10:00',
        @fechaFin       = '2025-11-30 10:05',
        @filasLeidas    = 100,
        @filasCargadas  = 100, -- 100%
        @estado         = 'OK',
        @newIdEjecucion = @newId OUTPUT;

    PRINT '   > Ejecución completada. ID Generado: ' + ISNULL(CAST(@newId AS VARCHAR), 'NULL');
    
    -- Validaciones en tablas
    IF EXISTS (SELECT 1 FROM dbo.EjecucionPipeline WHERE idEjecucion = @newId)
        PRINT '[OK] Registro encontrado en EjecucionPipeline.';
    ELSE
        PRINT '[FALLO] No se encontró el registro en EjecucionPipeline.';

    IF NOT EXISTS (SELECT 1 FROM dbo.AlertaEjecucion WHERE idEjecucion = @newId)
        PRINT '[OK] No se generó alerta (Correcto).';
    ELSE
        PRINT '[FALLO] Se generó una alerta indebida en AlertaEjecucion.';
END TRY
BEGIN CATCH
    PRINT '[FALLO] Ocurrió un error inesperado: ' + ERROR_MESSAGE();
END CATCH;

-----------------------------------------------------------------------------------
-- PRUEBA 3: Trigger Caso Alerta (< 80% pero >= 50%)
-- Resultado esperado: Inserción exitosa, CON alerta.
-----------------------------------------------------------------------------------
PRINT '';
PRINT '-----------------------------------------------------------------';
PRINT '--- PRUEBA 3: Alerta de Calidad (100 filas leídas, 70 cargadas -> 70%) ---';
PRINT '-----------------------------------------------------------------';

BEGIN TRY
    SET @newId = NULL;
    EXEC dbo.sp_AltaEjecucionPipeline
        @idPipeline     = @idPipelineValido,
        @fechaInicio    = '2025-11-30 11:00',
        @fechaFin       = '2025-11-30 11:05',
        @filasLeidas    = 100,
        @filasCargadas  = 70, -- 70%
        @estado         = 'OK',
        @newIdEjecucion = @newId OUTPUT;

    PRINT '   > Ejecución completada. ID Generado: ' + ISNULL(CAST(@newId AS VARCHAR), 'NULL');

    -- Validaciones en tablas
    IF EXISTS (SELECT 1 FROM dbo.EjecucionPipeline WHERE idEjecucion = @newId)
        PRINT '[OK] Registro persistido en EjecucionPipeline.';
    ELSE 
        PRINT '[FALLO] No se guardó la ejecución.';

    IF EXISTS (SELECT 1 FROM dbo.AlertaEjecucion WHERE idEjecucion = @newId)
    BEGIN
        DECLARE @msg VARCHAR(MAX) = (SELECT TOP 1 mensaje FROM dbo.AlertaEjecucion WHERE idEjecucion = @newId);
        PRINT '[OK] Alerta generada correctamente: "' + @msg + '"';
    END
    ELSE
        PRINT '[FALLO] No se generó la alerta esperada.';
END TRY
BEGIN CATCH
    PRINT '[FALLO] Ocurrió un error inesperado: ' + ERROR_MESSAGE();
END CATCH;

-----------------------------------------------------------------------------------
-- PRUEBA 4: Trigger Caso Crítico (< 50% -> Rollback)
-- Resultado esperado: Error lanzado, ROLLBACK total (sin registros).
-----------------------------------------------------------------------------------
PRINT '';
PRINT '-----------------------------------------------------------------';
PRINT '--- PRUEBA 4: Fallo Crítico (100 filas leídas, 40 cargadas -> 40%) ---';
PRINT '-----------------------------------------------------------------';

BEGIN TRY
    SET @newId = NULL;
    EXEC dbo.sp_AltaEjecucionPipeline
        @idPipeline     = @idPipelineValido,
        @fechaInicio    = '2025-11-30 12:00',
        @fechaFin       = '2025-11-30 12:05',
        @filasLeidas    = 100,
        @filasCargadas  = 40, -- 40%
        @estado         = 'OK',
        @newIdEjecucion = @newId OUTPUT;
    
    PRINT '[FALLO] La operación debió ser cancelada por el Trigger y no lo fue.';
END TRY
BEGIN CATCH
    PRINT '[EXITO] Se capturó el error esperado del Trigger.';
    PRINT '        Mensaje recibido: ' + ERROR_MESSAGE();

    -- Verificación post-rollback
    -- Buscamos si existe ALGUN registro con esas características creado recientemente
    IF NOT EXISTS (
        SELECT 1 FROM dbo.EjecucionPipeline 
        WHERE idPipeline = @idPipelineValido 
          AND filasLeidas = 100 
          AND filasCargadas = 40
    )
    BEGIN
        PRINT '[OK] El registro NO existe en EjecucionPipeline (Rollback exitoso).';
        PRINT '[OK] Tampoco debería existir alerta para esta ejecución fallida.';
    END
    ELSE
    BEGIN
        PRINT '[FALLO] El registro crítico SE ENCUENTRA en la tabla (El Rollback falló).';
    END
END CATCH;

-----------------------------------------------------------------------------------
-- PRUEBA 5: Inserción Masiva (Bulk Insert)
-- Resultado esperado: El trigger procesa múltiples filas correctamente.
-- Algunas generan alerta, otras error crítico (rollback total), otras OK.
-- NOTA: Como una de las filas causará Rollback, TODO el lote debería fallar.
-----------------------------------------------------------------------------------
PRINT '';
PRINT '-----------------------------------------------------------------';
PRINT '--- PRUEBA 5: Validar Inserción Masiva (Manejo de Lotes) ---';
PRINT '-----------------------------------------------------------------';
-- Para probar que NO usa cursores y maneja lotes, insertaremos 3 filas de golpe:
-- 1. OK (100%)
-- 2. Alerta (70%)
-- 3. Crítico (40%) -> Esto debería tumbar TODO el lote si la lógica es transaccional
-- Si el trigger estuviera mal hecho (cursor), podría procesar la 1 y 2 y fallar en la 3 parcialmente.
-- Al ser un trigger AFTER INSERT con ROLLBACK, esperamos que NADA se guarde.

BEGIN TRY
    INSERT INTO dbo.EjecucionPipeline (idPipeline, fechaInicio, fechaFin, filasLeidas, filasCargadas, estado)
    VALUES 
        (@idPipelineValido, GETDATE(), GETDATE(), 100, 100, 'OK'),  -- Caso OK
        (@idPipelineValido, GETDATE(), GETDATE(), 100, 70,  'OK'),  -- Caso Alerta
        (@idPipelineValido, GETDATE(), GETDATE(), 100, 40,  'OK');  -- Caso Crítico (Rollback)
    
    PRINT '[FALLO] La inserción masiva debió fallar por el caso crítico y no lo hizo.';
END TRY
BEGIN CATCH
    PRINT '[EXITO] Se capturó el error esperado en la carga masiva.';
    PRINT '        Mensaje: ' + ERROR_MESSAGE();

    -- Verificación: Ninguna de las 3 filas debería existir
    -- Especialmente la primera que era válida. Si existe, el rollback no fue total o el trigger falló en lógica de conjuntos.
    DECLARE @count INT = (
        SELECT COUNT(*) FROM dbo.EjecucionPipeline 
        WHERE idPipeline = @idPipelineValido 
          AND filasLeidas = 100 
          AND filasCargadas IN (100, 70, 40)
          AND fechaInicio > DATEADD(MINUTE, -1, GETDATE()) -- Creadas recién
    );

    IF @count = 0
        PRINT '[OK] Rollback total exitoso. Ninguna fila del lote se persistió.';
    ELSE
        PRINT '[FALLO] Se encontraron ' + CAST(@count AS VARCHAR) + ' filas insertadas. El manejo de conjuntos/transacción falló.';
END CATCH;

-----------------------------------------------------------------------------------
-- PRUEBA 6: Inserción Masiva Exitosa (Sin Errores Críticos)
-- Resultado esperado: Se insertan múltiples filas, algunas generan alerta, otras no.
-- NINGUNA genera error crítico, por lo que TODO el lote debe persistir.
-----------------------------------------------------------------------------------
PRINT '';
PRINT '-----------------------------------------------------------------';
PRINT '--- PRUEBA 6: Validar Inserción Masiva Exitosa (Mix OK + Alertas) ---';
PRINT '-----------------------------------------------------------------';
-- Insertamos 3 filas:
-- 1. OK (100%)
-- 2. Alerta (75%)
-- 3. OK (90%)
-- Resultado: Deben quedar 3 ejecuciones y 1 alerta.

BEGIN TRY
    -- Guardamos IDs iniciales para contar después
    DECLARE @conteoInicialEjec INT = (SELECT COUNT(*) FROM dbo.EjecucionPipeline);
    DECLARE @conteoInicialAlertas INT = (SELECT COUNT(*) FROM dbo.AlertaEjecucion);

    INSERT INTO dbo.EjecucionPipeline (idPipeline, fechaInicio, fechaFin, filasLeidas, filasCargadas, estado)
    VALUES 
        (@idPipelineValido, GETDATE(), GETDATE(), 100, 100, 'OK'),  -- Caso OK
        (@idPipelineValido, GETDATE(), GETDATE(), 100, 75,  'OK'),  -- Caso Alerta
        (@idPipelineValido, GETDATE(), GETDATE(), 100, 90,  'OK');  -- Caso OK
    
    PRINT '[OK] Inserción masiva completada sin errores bloqueantes.';

    -- Validaciones
    DECLARE @nuevasEjecuciones INT = (SELECT COUNT(*) FROM dbo.EjecucionPipeline) - @conteoInicialEjec;
    DECLARE @nuevasAlertas INT = (SELECT COUNT(*) FROM dbo.AlertaEjecucion) - @conteoInicialAlertas;

    IF @nuevasEjecuciones = 3
        PRINT '[OK] Se insertaron correctamente las 3 ejecuciones.';
    ELSE
        PRINT '[FALLO] Se esperaban 3 nuevas ejecuciones, se encontraron: ' + CAST(@nuevasEjecuciones AS VARCHAR);

    IF @nuevasAlertas = 1
        PRINT '[OK] Se generó exactamente 1 alerta (correspondiente al caso de 75%).';
    ELSE
        PRINT '[FALLO] Se esperaban 1 nueva alerta, se encontraron: ' + CAST(@nuevasAlertas AS VARCHAR);

END TRY
BEGIN CATCH
    PRINT '[FALLO] La inserción masiva válida falló inesperadamente.';
    PRINT '        Error: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT '=== FIN DE PRUEBAS ===';

