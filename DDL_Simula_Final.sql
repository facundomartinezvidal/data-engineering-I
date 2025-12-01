------------------------------------------------------------
-- SIMULA FINAL - BASE DE DATOS I
-- 
-- Contexto: VAR Analytics - Liga Profesional de Fútbol (LPF)
--
-- Contiene:
-- 1) Creación de la base de datos
-- 2) Creación de tablas base (Partido, Jugador, EventoPartido)
-- 3) Inserción de datos de ejemplo (volcado inicial)
------------------------------------------------------------

------------------------------------------------------------
-- 1) CREACIÓN DE LA BASE DE DATOS
------------------------------------------------------------
CREATE DATABASE VAR_Analytics_LPF;
GO

USE VAR_Analytics_LPF;
GO

------------------------------------------------------------
-- 2) CREACIÓN DE TABLAS BASE
------------------------------------------------------------

-- Tabla Partido: registra los partidos de la Liga Profesional
CREATE TABLE Partido (
    idPartido INT PRIMARY KEY,
    fecha DATE NOT NULL,
    estadio VARCHAR(50) NOT NULL,
    equipoLocal VARCHAR(50) NOT NULL,
    equipoVisitante VARCHAR(50) NOT NULL
);
GO

-- Tabla Jugador: registra los jugadores y su club actual
CREATE TABLE Jugador (
    idJugador INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    posicion VARCHAR(20) NOT NULL,
    equipo VARCHAR(50) NOT NULL
);
GO

-- Tabla EventoPartido: registra los eventos ocurridos en cada partido
CREATE TABLE EventoPartido (
    idEvento INT PRIMARY KEY,
    idPartido INT NOT NULL,
    idJugador INT NOT NULL,
    minuto TINYINT NOT NULL,
    tipoEvento VARCHAR(10) NOT NULL,
    descripcion VARCHAR(100),

    FOREIGN KEY (idPartido) REFERENCES Partido(idPartido),
    FOREIGN KEY (idJugador) REFERENCES Jugador(idJugador),

    CHECK (minuto BETWEEN 1 AND 90),
    CHECK (tipoEvento IN ('GOL','AMARILLA','ROJA','CAMBIO'))
);
GO

------------------------------------------------------------
-- 3) VOLCADO INICIAL DE DATOS (DML)
------------------------------------------------------------

-- Partidos de ejemplo (clubes argentinos reales)
INSERT INTO Partido (idPartido, fecha, estadio, equipoLocal, equipoVisitante)
VALUES
(1, '2025-01-15', 'La Bombonera',          'Boca Juniors',  'River Plate'),
(2, '2025-01-22', 'Estadio Monumental',    'River Plate',   'Racing Club'),
(3, '2025-01-29', 'Cilindro de Avellaneda','Racing Club',   'San Lorenzo');
GO

-- Jugadores de ejemplo
INSERT INTO Jugador (idJugador, nombre, apellido, posicion, equipo)
VALUES
-- Boca Juniors
(10, 'Edinson', 'Cavani',    'Delantero', 'Boca Juniors'),
(11, 'Sergio',  'Romero',    'Arquero',   'Boca Juniors'),

-- River Plate
(20, 'Miguel',  'Borja',     'Delantero', 'River Plate'),
(21, 'Enzo',    'Fernández', 'Volante',   'River Plate'),

-- Racing Club
(30, 'Roger',   'Martínez',  'Delantero', 'Racing Club'),
(31, 'Juanfer', 'Quintero',  'Volante',   'Racing Club'),

-- San Lorenzo
(40, 'Adam',    'Bareiro',   'Delantero', 'San Lorenzo');
GO

-- Eventos de los partidos de ejemplo
INSERT INTO EventoPartido (idEvento, idPartido, idJugador, minuto, tipoEvento, descripcion)
VALUES
-- Partido 1: Boca Juniors vs River Plate
(100, 1, 10, 23, 'GOL',      'Gol de Cavani'),
(101, 1, 20, 55, 'GOL',      'Gol de Borja'),
(102, 1, 11, 70, 'AMARILLA', 'Falta de Romero'),

-- Partido 2: River Plate vs Racing Club
(200, 2, 20, 15, 'GOL',      'Gol de Borja'),
(201, 2, 30, 30, 'GOL',      'Gol de Martínez'),
(202, 2, 21, 75, 'ROJA',     'Expulsión de Enzo'),

-- Partido 3: Racing Club vs San Lorenzo
(300, 3, 40, 50, 'GOL',      'Gol de Bareiro'),
(301, 3, 31, 10, 'AMARILLA', 'Amarilla a Quintero'),
(302, 3, 31, 85, 'CAMBIO',   'Cambio táctico');
GO