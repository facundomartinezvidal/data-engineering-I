USE DF_Eval_Junior;
GO

IF OBJECT_ID('dbo.AlertaEjecucion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AlertaEjecucion (
        idAlerta      INT IDENTITY(1,1) PRIMARY KEY,
        idEjecucion   INT NOT NULL,
        mensaje       VARCHAR(200),
        fechaHora     DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (idEjecucion) REFERENCES dbo.EjecucionPipeline(idEjecucion)
             ON DELETE CASCADE -- Opcional: si borran la ejecución, se borra la alerta
    );
    PRINT 'Tabla AlertaEjecucion creada.';
END
GO


CREATE OR ALTER PROCEDURE dbo.sp_AltaEjecucionPipeline
    @idPipeline     INT,
    @fechaInicio    DATETIME,
    @fechaFin       DATETIME,
    @filasLeidas    INT,
    @filasCargadas  INT,
    @estado         VARCHAR(10),
    @newIdEjecucion INT OUTPUT -- Parámetro de salida
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- a. Verificar que el idPipeline exista
        IF NOT EXISTS (SELECT 1 FROM dbo.Pipeline WHERE idPipeline = @idPipeline)
        BEGIN
            -- Usamos THROW con un código personalizado (mayor a 50000)
            THROW 51000, 'El idPipeline especificado no existe.', 1;
        END

        -- b. Insertar la ejecución
        INSERT INTO dbo.EjecucionPipeline (
            idPipeline,
            fechaInicio,
            fechaFin,
            filasLeidas,
            filasCargadas,
            estado
        )
        VALUES (
            @idPipeline,
            @fechaInicio,
            @fechaFin,
            @filasLeidas,
            @filasCargadas,
            @estado
        );

        -- c. Devolver el ID generado
        SET @newIdEjecucion = SCOPE_IDENTITY();

    END TRY
    BEGIN CATCH
        -- d. Manejo de errores: Si algo falla, relanzamos el error original
        THROW;
    END CATCH
END
GO


CREATE OR ALTER TRIGGER trg_ControlarEjecucionPipeline
ON dbo.EjecucionPipeline
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Declaramos una variable tipo tabla para guardar los cálculos temporalmente
    DECLARE @MetricasCalculadas TABLE (
        idEjecucion INT,
        PorcentajeExito DECIMAL(5,2)
    );

    -- 2. Hacemos el cálculo una sola vez y lo guardamos en la variable
    INSERT INTO @MetricasCalculadas (idEjecucion, PorcentajeExito)
    SELECT
        idEjecucion,
        CASE
            WHEN filasLeidas = 0 THEN 0
            ELSE (filasCargadas * 100.0) / filasLeidas
        END
    FROM inserted;

    -- 3. REGLA 1: Si < 80%, insertamos la alerta
    --    Leemos desde nuestra variable @MetricasCalculadas
    INSERT INTO dbo.AlertaEjecucion (idEjecucion, mensaje, fechaHora)
    SELECT
        idEjecucion,
        'Ejecución con porcentaje de éxito bajo (' + CAST(PorcentajeExito AS VARCHAR) + '%)',
        GETDATE()
    FROM @MetricasCalculadas
    WHERE PorcentajeExito < 80;

    -- 4. REGLA 2: Si < 50%, lanzamos Error y Rollback
    IF EXISTS (SELECT 1 FROM @MetricasCalculadas WHERE PorcentajeExito < 50)
    BEGIN
        -- Nota: El ROLLBACK deshará la inserción original Y la alerta creada arriba.
        RAISERROR ('Se detectaron ejecuciones con calidad crítica (< 50%%). Operación cancelada.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO



