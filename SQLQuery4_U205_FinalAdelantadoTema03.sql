/*
===============================================================
 EXAMEN FINAL ADELANTADO � PARTE PR�CTICA (TEMA 3)
 Ingeniero de Datos Jr. � Soluciones Informáticas SRL
 Base de Datos: DF_Eval_Junior
===============================================================
*/

---------------------------------------------------------------
-- 1. VERIFICAR SI LA BASE DE DATOS EXISTE
---------------------------------------------------------------
IF DB_ID('DF_Eval_Junior') IS NOT NULL
BEGIN
    PRINT 'La base de datos DF_Eval_Junior ya existe.';
    -- Si desea recrear la base, descomente la siguiente l�nea:
    -- DROP DATABASE DF_Eval_Junior;
END
ELSE
BEGIN
    PRINT 'Creando base de datos DF_Eval_Junior...';
    CREATE DATABASE DF_Eval_Junior;
END
GO

USE DF_Eval_Junior;
GO

/*
===============================================================
 2. CREACI�N DE TABLAS SOLO SI NO EXISTEN
===============================================================
*/

---------------------------------------------------------------
-- CLIENTE
---------------------------------------------------------------
IF OBJECT_ID('Cliente', 'U') IS NULL
BEGIN
    CREATE TABLE Cliente (
        idCliente INT PRIMARY KEY,
        razonSocial VARCHAR(100) NOT NULL,
        rubro VARCHAR(50) NOT NULL,
        pais VARCHAR(50) NOT NULL
    );
    PRINT 'Tabla Cliente creada correctamente.';
END
ELSE
BEGIN
    PRINT 'Tabla Cliente ya existe. No se recrear�.';
END
GO

---------------------------------------------------------------
-- PIPELINE
---------------------------------------------------------------
IF OBJECT_ID('Pipeline', 'U') IS NULL
BEGIN
    CREATE TABLE Pipeline (
        idPipeline INT PRIMARY KEY,
        nombrePipeline VARCHAR(100) NOT NULL,
        idCliente INT NOT NULL,
        tipoFuente VARCHAR(20) NOT NULL,
        frecuencia VARCHAR(20) NOT NULL,
        FOREIGN KEY (idCliente) REFERENCES Cliente(idCliente)
    );
    PRINT 'Tabla Pipeline creada correctamente.';
END
ELSE
BEGIN
    PRINT 'Tabla Pipeline ya existe. No se recrear�.';
END
GO

---------------------------------------------------------------
-- EJECUCIONPIPELINE
---------------------------------------------------------------
IF OBJECT_ID('EjecucionPipeline', 'U') IS NULL
BEGIN
    CREATE TABLE EjecucionPipeline (
        idEjecucion INT IDENTITY(1,1) PRIMARY KEY,
        idPipeline INT NOT NULL,
        fechaInicio DATETIME NOT NULL,
        fechaFin DATETIME NOT NULL,
        filasLeidas INT NOT NULL,
        filasCargadas INT NOT NULL,
        estado VARCHAR(10) NOT NULL,
        FOREIGN KEY (idPipeline) REFERENCES Pipeline(idPipeline),
        CHECK (filasLeidas >= 0),
        CHECK (filasCargadas >= 0),
        CHECK (estado IN ('OK','ERROR'))
    );
    PRINT 'Tabla EjecucionPipeline creada correctamente.';
END
ELSE
BEGIN
    PRINT 'Tabla EjecucionPipeline ya existe. No se recrear�.';
END
GO

/*
===============================================================
 3. VOLCADO INICIAL DE DATOS (solo si no existen)
===============================================================
*/

---------------------------------------------------------------
-- CLIENTES
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Cliente)
BEGIN
    INSERT INTO Cliente (idCliente, razonSocial, rubro, pais) VALUES
        (1, 'RetailPlus Argentina SA', 'Retail',   'Argentina'),
        (2, 'FarmaciaVida SRL',        'Farmacia', 'Argentina'),
        (3, 'ElectroHome Latam SA',    'Electro',  'Chile');
    PRINT 'Datos insertados en Cliente.';
END
ELSE
BEGIN
    PRINT 'Datos de Cliente ya existen. No se volver�n a insertar.';
END
GO

---------------------------------------------------------------
-- PIPELINES
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Pipeline)
BEGIN
    INSERT INTO Pipeline (idPipeline, nombrePipeline, idCliente, tipoFuente, frecuencia) VALUES
        (10, 'IngestionVentasDiarias', 1, 'CSV', 'DIARIA'),
        (11, 'IngestionStockNocturno', 1, 'DB',  'DIARIA'),
        (20, 'IngestionRecetas',       2, 'API', 'HORARIA'),
        (30, 'IngestionPrecioLista',   3, 'CSV', 'SEMANAL');
    PRINT 'Datos insertados en Pipeline.';
END
ELSE
BEGIN
    PRINT 'Datos de Pipeline ya existen. No se volver�n a insertar.';
END
GO

---------------------------------------------------------------
-- EJECUCIONES DE EJEMPLO
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM EjecucionPipeline)
BEGIN
    PRINT 'Habilitando IDENTITY_INSERT para EjecucionPipeline...';
    SET IDENTITY_INSERT EjecucionPipeline ON;

    INSERT INTO EjecucionPipeline (
        idEjecucion, idPipeline, fechaInicio, fechaFin, 
        filasLeidas, filasCargadas, estado
    ) VALUES
        (100, 10, '2025-01-10 01:00', '2025-01-10 01:05', 10000,  9950, 'OK'),
        (101, 10, '2025-01-11 01:00', '2025-01-11 01:07', 12000, 12000, 'OK'),
        (102, 11, '2025-01-11 02:00', '2025-01-11 02:10',  8000,  7900, 'OK'),
        (200, 20, '2025-01-10 00:00', '2025-01-10 00:15',  5000,  4500, 'ERROR'),
        (201, 20, '2025-01-10 01:00', '2025-01-10 01:20',  6000,  5900, 'OK'),
        (300, 30, '2025-01-09 03:00', '2025-01-09 03:25',  2000,  1800, 'ERROR');

    SET IDENTITY_INSERT EjecucionPipeline OFF;
    PRINT 'Datos insertados en EjecucionPipeline.';
END
ELSE
BEGIN
    PRINT 'Datos de EjecucionPipeline ya existen. No se volver�n a insertar.';
END
GO

/*
===============================================================
 FIN DEL SCRIPT INICIAL � A PARTIR DE AQU� COMIENZAN LOS EJERCICIOS
===============================================================
*/

/*
================================================================
CREATE TABLE AlertaEjecucion (
    idAlerta      INT IDENTITY PRIMARY KEY,
    idEjecucion   INT,
    mensaje       VARCHAR(200),
    fechaHora     DATETIME
);
===============================================================
*/