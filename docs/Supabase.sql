-- FIELDSTATS V0.1 | INSTALACION EXCLUSIVAMENTE EN SUPABASE POSTGRESQL VACIO
-- NO ejecutar sobre una base con datos/tablas previas. No migracion incremental.
-- El modulo anterior queda aislado y sin acceso de roles web bajo schema legacy.
-- public.usuarios es la UNICA identidad operativa. auth.users es la cuenta opcional.
-- IMPORTANTE: ejecutar como rol administrador postgres desde SQL editor en proyecto de PRUEBAS.
BEGIN;
CREATE SCHEMA IF NOT EXISTS legacy;
CREATE SCHEMA IF NOT EXISTS private;

-- ========= ARCHIVO V4 LEGADO, CONSERVADO EN SU PROPIO ESQUEMA =========
-- =====================================================================
-- FieldStats DB — Schema completo
-- Motor: PostgreSQL (Supabase)
-- Nota: los ID son INT asignados por la aplicación (no autoincrementales).
--       Si hace falta, se puede migrar a GENERATED ALWAYS AS IDENTITY.
-- Organización: 1) Tablas Generales (compartidas)
--               2) Deportes Grupales (Fútbol, Handball, etc.)
--               3) Deportes Individuales (Atletismo, etc.)
-- =====================================================================


-- =====================================================================
-- 1) TABLAS GENERALES (compartidas por Deportes Grupales e Individuales)
-- =====================================================================

CREATE TABLE legacy."ROLES"(
    "ID_ROL" INT NOT NULL,
    "NOMBRE" VARCHAR(50) NOT NULL,
    "AMBITO" VARCHAR(255) CHECK
        ("AMBITO" IN('Global', 'Deporte')) NOT NULL DEFAULT 'Global'
);
ALTER TABLE legacy."ROLES" ADD CONSTRAINT "roles_id_rol_primary" PRIMARY KEY("ID_ROL");
CREATE UNIQUE INDEX "roles_nombre_unique" ON
    legacy."ROLES"("NOMBRE");

CREATE TABLE legacy."DEPORTES"(
    "ID_DEPORTE" INT NOT NULL,
    "NOMBRE" VARCHAR(50) NOT NULL,
    "DESCRIPCION" VARCHAR(200) NULL,
    "ACTIVO" BOOLEAN NOT NULL DEFAULT TRUE
);
ALTER TABLE legacy."DEPORTES" ADD CONSTRAINT "deportes_id_deporte_primary" PRIMARY KEY("ID_DEPORTE");
CREATE UNIQUE INDEX "deportes_nombre_unique" ON
    legacy."DEPORTES"("NOMBRE");

CREATE TABLE legacy."CATEGORIAS"(
    "ID_CATEGORIA" INT NOT NULL,
    "NOMBRE" VARCHAR(50) NOT NULL
);
ALTER TABLE legacy."CATEGORIAS" ADD CONSTRAINT "categorias_id_categoria_primary" PRIMARY KEY("ID_CATEGORIA");
CREATE UNIQUE INDEX "categorias_nombre_unique" ON
    legacy."CATEGORIAS"("NOMBRE");

CREATE TABLE legacy."EQUIPOS"(
    "ID_EQUIPO" INT NOT NULL,
    "NOMBRE" VARCHAR(100) NOT NULL,
    "CONTACTO" VARCHAR(100) NULL,
    "TELEFONO" VARCHAR(50) NULL,
    "EMAIL" VARCHAR(150) NULL,
    "ES_PROPIO" BOOLEAN NOT NULL
);
ALTER TABLE legacy."EQUIPOS" ADD CONSTRAINT "equipos_id_equipo_primary" PRIMARY KEY("ID_EQUIPO");

CREATE TABLE legacy."SEDES"(
    "ID_SEDE" INT NOT NULL,
    "NOMBRE" VARCHAR(100) NOT NULL,
    "DIRECCION" VARCHAR(200) NULL
);
ALTER TABLE legacy."SEDES" ADD CONSTRAINT "sedes_id_sede_primary" PRIMARY KEY("ID_SEDE");

CREATE TABLE legacy."USUARIOS"(
    "ID_USUARIO" INT NOT NULL,
    "NOMBRE" VARCHAR(100) NOT NULL,
    "APELLIDO" VARCHAR(100) NOT NULL,
    "EMAIL" VARCHAR(150) NOT NULL,
    "PASSWORD_HASH" VARCHAR(255) NOT NULL,
    "SALT" VARCHAR(255) NOT NULL,
    "DNI" VARCHAR(20) NOT NULL,
    "FECHA_NACIMIENTO" DATE NOT NULL,
    "TELEFONO" VARCHAR(50) NULL,
    "EMAIL_PADRE" VARCHAR(150) NULL,
    "NOMBRE_PADRE" VARCHAR(150) NULL,
    "TOKEN_ACTIVACION" VARCHAR(20) NULL,
    "TOKEN_EXPIRA" TIMESTAMP NULL,
    "ID_ROL_GLOBAL" INT NOT NULL,
    "ACTIVADO" BOOLEAN NOT NULL,
    "CONFIRMADO" BOOLEAN NOT NULL,
    "FECHA_REGISTRO" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE legacy."USUARIOS" ADD CONSTRAINT "usuarios_id_usuario_primary" PRIMARY KEY("ID_USUARIO");
CREATE UNIQUE INDEX "usuarios_email_unique" ON
    legacy."USUARIOS"("EMAIL");
CREATE UNIQUE INDEX "usuarios_dni_unique" ON
    legacy."USUARIOS"("DNI");

CREATE TABLE legacy."USUARIO_DEPORTE"(
    "ID_USUDEP" INT NOT NULL,
    "ID_USUARIO" INT NOT NULL,
    "ID_DEPORTE" INT NOT NULL,
    "ID_CATEGORIA" INT NULL,
    "ID_ROL" INT NOT NULL,
    "ID_SEDE" INT NULL,
    "NUMERO_CAMISETA" INT NULL,
    "F_INICIO" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP, "ACTIVO" BOOLEAN NOT NULL DEFAULT TRUE);
CREATE INDEX "usuario_deporte_id_deporte_id_categoria_index" ON
    legacy."USUARIO_DEPORTE"("ID_DEPORTE", "ID_CATEGORIA");
CREATE UNIQUE INDEX "ID_USUARIO_ID_DEPORTE_ID_CATEGORIA_ID_ROL_unique" ON
    legacy."USUARIO_DEPORTE"(
        "ID_USUARIO",
        "ID_DEPORTE",
        "ID_CATEGORIA",
        "ID_ROL"
    );
ALTER TABLE legacy."USUARIO_DEPORTE" ADD CONSTRAINT "usuario_deporte_id_usudep_primary" PRIMARY KEY("ID_USUDEP");
CREATE INDEX "usuario_deporte_id_usuario_index" ON
    legacy."USUARIO_DEPORTE"("ID_USUARIO");

CREATE TABLE legacy."TORNEOS"(
    "ID_TORNEO" INT NOT NULL,
    "NOMBRE" VARCHAR(100) NOT NULL,
    "ID_DEPORTE" INT NOT NULL,
    "ID_CATEGORIA" INT NOT NULL,
    "ANIO" INT NOT NULL,
    "ACTIVO" BOOLEAN NOT NULL DEFAULT TRUE
);
ALTER TABLE legacy."TORNEOS" ADD CONSTRAINT "torneos_id_torneo_primary" PRIMARY KEY("ID_TORNEO");

CREATE TABLE legacy."FECHAS"(
    "ID_FECHA" INT NOT NULL,
    "ID_TORNEO" INT NOT NULL,
    "NRO_FECHA" INT NOT NULL,
    "FECHA" DATE NOT NULL
);
CREATE UNIQUE INDEX "fechas_id_torneo_nro_fecha_unique" ON
    legacy."FECHAS"("ID_TORNEO", "NRO_FECHA");
ALTER TABLE legacy."FECHAS" ADD CONSTRAINT "fechas_id_fecha_primary" PRIMARY KEY("ID_FECHA");


-- Asistencia a clases de deportes individuales y grupales.
-- FECHA guarda la fecha y hora de la clase, no de la carga.
-- PRESENTE: 1 = presente; 0 = ausente. Sin fila = asistencia no registrada.
-- Los IDs se asignan desde la aplicacion, como en el resto del esquema.
CREATE TABLE legacy."PRESENCIALIDAD"(
    "ID_PRESENCIALIDAD" INT NOT NULL,
    "FECHA" TIMESTAMP NOT NULL,
    "ID_USUARIO" INT NOT NULL,
    "PRESENTE" INT NOT NULL,
    "IDDEP" INT NOT NULL
);
ALTER TABLE legacy."PRESENCIALIDAD" ADD CONSTRAINT "presencialidad_id_presencialidad_primary"
    PRIMARY KEY("ID_PRESENCIALIDAD");
ALTER TABLE legacy."PRESENCIALIDAD" ADD CONSTRAINT "presencialidad_presente_check"
    CHECK ("PRESENTE" IN (0, 1));
ALTER TABLE legacy."PRESENCIALIDAD" ADD CONSTRAINT "presencialidad_id_usuario_foreign"
    FOREIGN KEY("ID_USUARIO") REFERENCES legacy."USUARIOS"("ID_USUARIO");
ALTER TABLE legacy."PRESENCIALIDAD" ADD CONSTRAINT "presencialidad_iddep_foreign"
    FOREIGN KEY("IDDEP") REFERENCES legacy."DEPORTES"("ID_DEPORTE");

-- Una asistencia por usuario, deporte y fecha/hora exacta de clase.
CREATE UNIQUE INDEX "presencialidad_usuario_deporte_fecha_unique" ON
    legacy."PRESENCIALIDAD"("ID_USUARIO", "IDDEP", "FECHA");
-- Facilita filtrar por deporte y por rango de fechas.
CREATE INDEX "presencialidad_deporte_fecha_index" ON
    legacy."PRESENCIALIDAD"("IDDEP", "FECHA");


-- =====================================================================
-- 2) DEPORTES GRUPALES (Fútbol, Handball, etc.)
-- =====================================================================

CREATE TABLE legacy."PARTIDOS"(
    "ID_PARTIDO" INT NOT NULL,
    "ID_FECHA" INT NOT NULL,
    "ID_EQUIPO_LOCAL" INT NOT NULL,
    "ID_EQUIPO_VISITANTE" INT NOT NULL,
    "ID_SEDE" INT NULL,
    "FECHA_HORA" TIMESTAMP NOT NULL,
    "ESTADO" VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    "JUGADOR_DESTACADO_ID" INT NULL,
    "OBSERVACIONES" TEXT NULL
);
CREATE INDEX "partidos_estado_fecha_hora_index" ON
    legacy."PARTIDOS"("ESTADO", "FECHA_HORA");
ALTER TABLE legacy."PARTIDOS" ADD CONSTRAINT "partidos_id_partido_primary" PRIMARY KEY("ID_PARTIDO");
CREATE INDEX "partidos_id_fecha_index" ON
    legacy."PARTIDOS"("ID_FECHA");

CREATE TABLE legacy."RESULTADOS"(
    "ID_RESULTADO" INT NOT NULL,
    "ID_PARTIDO" INT NOT NULL,
    "GOLES_LOCAL" INT NOT NULL,
    "GOLES_VISITANTE" INT NOT NULL
);
ALTER TABLE legacy."RESULTADOS" ADD CONSTRAINT "resultados_id_resultado_primary" PRIMARY KEY("ID_RESULTADO");
CREATE UNIQUE INDEX "resultados_id_partido_unique" ON
    legacy."RESULTADOS"("ID_PARTIDO");

CREATE TABLE legacy."CONVOCATORIAS"(
    "ID_CONVOCATORIA" INT NOT NULL,
    "ID_PARTIDO" INT NOT NULL,
    "ID_USUARIO" INT NOT NULL,
    "ESTADO" VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    "ASISTIO" BOOLEAN NOT NULL,
    "METODO_TRANSPORTE" VARCHAR(50) NULL,
    "AUTORIZACION_FIRMADA" BOOLEAN NOT NULL,
    "FECHA_RESPUESTA" TIMESTAMP NULL
);
CREATE UNIQUE INDEX "convocatorias_id_partido_id_usuario_unique" ON
    legacy."CONVOCATORIAS"("ID_PARTIDO", "ID_USUARIO");
ALTER TABLE legacy."CONVOCATORIAS" ADD CONSTRAINT "convocatorias_id_convocatoria_primary" PRIMARY KEY("ID_CONVOCATORIA");
CREATE INDEX "convocatorias_id_partido_index" ON
    legacy."CONVOCATORIAS"("ID_PARTIDO");
CREATE INDEX "convocatorias_id_usuario_index" ON
    legacy."CONVOCATORIAS"("ID_USUARIO");

CREATE TABLE legacy."AUTORIZACIONES"(
    "ID_AUTORIZACION" INT NOT NULL,
    "ID_CONVOCATORIA" INT NOT NULL,
    "FIRMA_DIGITAL" VARCHAR(255) NULL,
    "IP_FIRMA" VARCHAR(50) NULL,
    "FECHA_FIRMA" TIMESTAMP NULL,
    "DOCUMENTO_URL" VARCHAR(500) NULL
);
ALTER TABLE legacy."AUTORIZACIONES" ADD CONSTRAINT "autorizaciones_id_autorizacion_primary" PRIMARY KEY("ID_AUTORIZACION");
CREATE UNIQUE INDEX "autorizaciones_id_convocatoria_unique" ON
    legacy."AUTORIZACIONES"("ID_CONVOCATORIA");

CREATE TABLE legacy."TITULARES"(
    "ID_TITULAR" INT NOT NULL,
    "ID_PARTIDO" INT NOT NULL,
    "ID_USUARIO" INT NOT NULL,
    "NUMERO_CAMISETA" INT NOT NULL,
    "ES_CAPITAN" BOOLEAN NOT NULL
);
CREATE UNIQUE INDEX "titulares_id_partido_id_usuario_unique" ON
    legacy."TITULARES"("ID_PARTIDO", "ID_USUARIO");
ALTER TABLE legacy."TITULARES" ADD CONSTRAINT "titulares_id_titular_primary" PRIMARY KEY("ID_TITULAR");

CREATE TABLE legacy."CAMBIOS"(
    "ID_CAMBIO" INT NOT NULL,
    "ID_PARTIDO" INT NOT NULL,
    "ID_USUARIO_SALE" INT NOT NULL,
    "ID_USUARIO_ENTRA" INT NOT NULL,
    "MINUTO" INT NOT NULL,
    "MOTIVO" VARCHAR(100) NULL
);
ALTER TABLE legacy."CAMBIOS" ADD CONSTRAINT "cambios_id_cambio_primary" PRIMARY KEY("ID_CAMBIO");

CREATE TABLE legacy."TIPOS_ESTADISTICA"(
    "ID_TIPO_EST" INT NOT NULL,
    "NOMBRE" VARCHAR(50) NOT NULL
);
ALTER TABLE legacy."TIPOS_ESTADISTICA" ADD CONSTRAINT "tipos_estadistica_id_tipo_est_primary" PRIMARY KEY("ID_TIPO_EST");
CREATE UNIQUE INDEX "tipos_estadistica_nombre_unique" ON
    legacy."TIPOS_ESTADISTICA"("NOMBRE");

CREATE TABLE legacy."ESTADISTICAS"(
    "ID_ESTADISTICA" INT NOT NULL,
    "ID_PARTIDO" INT NOT NULL,
    "ID_USUARIO" INT NOT NULL,
    "ID_TIPO_EST" INT NOT NULL,
    "MINUTO" INT NOT NULL,
    "ID_USUARIO_ASISTENCIA" INT NULL
);
ALTER TABLE legacy."ESTADISTICAS" ADD CONSTRAINT "estadisticas_id_estadistica_primary" PRIMARY KEY("ID_ESTADISTICA");
CREATE INDEX "estadisticas_id_partido_index" ON
    legacy."ESTADISTICAS"("ID_PARTIDO");
CREATE INDEX "estadisticas_id_usuario_index" ON
    legacy."ESTADISTICAS"("ID_USUARIO");

CREATE TABLE legacy."TIPOS_SANCION"(
    "ID_TIPO_SANC" INT NOT NULL,
    "NOMBRE" VARCHAR(50) NOT NULL,
    "PARTIDOS_SUSPENSION" INT NOT NULL
);
ALTER TABLE legacy."TIPOS_SANCION" ADD CONSTRAINT "tipos_sancion_id_tipo_sanc_primary" PRIMARY KEY("ID_TIPO_SANC");
CREATE UNIQUE INDEX "tipos_sancion_nombre_unique" ON
    legacy."TIPOS_SANCION"("NOMBRE");

CREATE TABLE legacy."SANCIONES"(
    "ID_SANCION" INT NOT NULL,
    "ID_PARTIDO" INT NOT NULL,
    "ID_USUARIO" INT NOT NULL,
    "ID_TIPO_SANC" INT NOT NULL,
    "MINUTO" INT NOT NULL,
    "MOTIVO" VARCHAR(255) NULL
);
ALTER TABLE legacy."SANCIONES" ADD CONSTRAINT "sanciones_id_sancion_primary" PRIMARY KEY("ID_SANCION");
CREATE INDEX "sanciones_id_partido_index" ON
    legacy."SANCIONES"("ID_PARTIDO");


-- =====================================================================
-- 3) DEPORTES INDIVIDUALES (Atletismo, etc.) — NUEVO
-- =====================================================================

-- Disciplinas: las pruebas individuales dentro de un deporte
-- (ej. Deporte "Atletismo" -> Disciplinas "100m llanos", "Salto en largo").
CREATE TABLE legacy."DISCIPLINAS"(
    "IDDIS" INT NOT NULL,
    "ID_DEPORTE" INT NOT NULL,
    "NOMBRE" VARCHAR(100) NOT NULL
);
ALTER TABLE legacy."DISCIPLINAS" ADD CONSTRAINT "disciplinas_iddis_primary" PRIMARY KEY("IDDIS");

-- OPCIONAL: evita nombres de disciplina duplicados dentro del mismo deporte.
-- Es una red de seguridad extra (no reemplaza el control del frontend).
-- Si trae problemas, se puede eliminar sin afectar el resto del esquema:
--   DROP INDEX "disciplinas_id_deporte_nombre_unique";
CREATE UNIQUE INDEX "disciplinas_id_deporte_nombre_unique" ON
    legacy."DISCIPLINAS"("ID_DEPORTE", "NOMBRE");

-- Estaciones: instancia de una disciplina dentro de un torneo puntual
-- (ej. Torneo "Interescolar 2026" -> Estación "100m llanos", puesto N° 3).
-- IDDIS es NULLABLE porque una estación puede no estar ligada a una
-- disciplina individual específica (ej. estaciones genéricas / de uso
-- compartido dentro del mismo torneo).
CREATE TABLE legacy."ESTACIONES"(
    "IDESTACION" INT NOT NULL,
    "ID_TORNEO" INT NOT NULL,
    "IDDIS" INT NULL,
    "NOMBRE" VARCHAR(100) NOT NULL,
    "NUMERO" INT NOT NULL
);
ALTER TABLE legacy."ESTACIONES" ADD CONSTRAINT "estaciones_idestacion_primary" PRIMARY KEY("IDESTACION");

-- Puntos: un registro por cada carga de puntaje de un jugador en una
-- estación. La categoría (ID_CATEGORIA) queda guardada como "foto" del
-- momento de la carga, para no tener que recalcularla después.
CREATE TABLE legacy."PUNTOS"(
    "IDPUNTOS" INT NOT NULL,
    "ID_USUDEP" INT NOT NULL,
    "IDESTACION" INT NOT NULL,
    "PUNTOS" DECIMAL(4,1) NOT NULL,
    "ID_CATEGORIA" INT NOT NULL
);
ALTER TABLE legacy."PUNTOS" ADD CONSTRAINT "puntos_idpuntos_primary" PRIMARY KEY("IDPUNTOS");
CREATE INDEX "puntos_id_usudep_index" ON
    legacy."PUNTOS"("ID_USUDEP");
CREATE INDEX "puntos_idestacion_index" ON
    legacy."PUNTOS"("IDESTACION");


-- =====================================================================
-- FOREIGN KEYS — Tablas Generales / Deportes Grupales (existentes)
-- =====================================================================

ALTER TABLE legacy."SANCIONES" ADD CONSTRAINT "sanciones_id_partido_foreign" FOREIGN KEY("ID_PARTIDO") REFERENCES legacy."PARTIDOS"("ID_PARTIDO");
ALTER TABLE legacy."USUARIO_DEPORTE" ADD CONSTRAINT "usuario_deporte_id_usuario_foreign" FOREIGN KEY("ID_USUARIO") REFERENCES legacy."USUARIOS"("ID_USUARIO");
ALTER TABLE legacy."ESTADISTICAS" ADD CONSTRAINT "estadisticas_id_usuario_asistencia_foreign" FOREIGN KEY("ID_USUARIO_ASISTENCIA") REFERENCES legacy."USUARIOS"("ID_USUARIO");
ALTER TABLE legacy."ESTADISTICAS" ADD CONSTRAINT "estadisticas_id_partido_foreign" FOREIGN KEY("ID_PARTIDO") REFERENCES legacy."PARTIDOS"("ID_PARTIDO");
ALTER TABLE legacy."PARTIDOS" ADD CONSTRAINT "partidos_id_sede_foreign" FOREIGN KEY("ID_SEDE") REFERENCES legacy."SEDES"("ID_SEDE");
ALTER TABLE legacy."CAMBIOS" ADD CONSTRAINT "cambios_id_partido_foreign" FOREIGN KEY("ID_PARTIDO") REFERENCES legacy."PARTIDOS"("ID_PARTIDO");
ALTER TABLE legacy."TITULARES" ADD CONSTRAINT "titulares_id_usuario_foreign" FOREIGN KEY("ID_USUARIO") REFERENCES legacy."USUARIOS"("ID_USUARIO");
ALTER TABLE legacy."SANCIONES" ADD CONSTRAINT "sanciones_id_usuario_foreign" FOREIGN KEY("ID_USUARIO") REFERENCES legacy."USUARIOS"("ID_USUARIO");
ALTER TABLE legacy."USUARIOS" ADD CONSTRAINT "usuarios_id_rol_global_foreign" FOREIGN KEY("ID_ROL_GLOBAL") REFERENCES legacy."ROLES"("ID_ROL");
ALTER TABLE legacy."PARTIDOS" ADD CONSTRAINT "partidos_id_equipo_local_foreign" FOREIGN KEY("ID_EQUIPO_LOCAL") REFERENCES legacy."EQUIPOS"("ID_EQUIPO");
ALTER TABLE legacy."PARTIDOS" ADD CONSTRAINT "partidos_id_equipo_visitante_foreign" FOREIGN KEY("ID_EQUIPO_VISITANTE") REFERENCES legacy."EQUIPOS"("ID_EQUIPO");
ALTER TABLE legacy."TORNEOS" ADD CONSTRAINT "torneos_id_deporte_foreign" FOREIGN KEY("ID_DEPORTE") REFERENCES legacy."DEPORTES"("ID_DEPORTE");
ALTER TABLE legacy."TITULARES" ADD CONSTRAINT "titulares_id_partido_foreign" FOREIGN KEY("ID_PARTIDO") REFERENCES legacy."PARTIDOS"("ID_PARTIDO");
ALTER TABLE legacy."USUARIO_DEPORTE" ADD CONSTRAINT "usuario_deporte_id_sede_foreign" FOREIGN KEY("ID_SEDE") REFERENCES legacy."SEDES"("ID_SEDE");

ALTER TABLE legacy."ESTADISTICAS" ADD CONSTRAINT "estadisticas_id_usuario_foreign" FOREIGN KEY("ID_USUARIO") REFERENCES legacy."USUARIOS"("ID_USUARIO");
ALTER TABLE legacy."CAMBIOS" ADD CONSTRAINT "cambios_id_usuario_entra_foreign" FOREIGN KEY("ID_USUARIO_ENTRA") REFERENCES legacy."USUARIOS"("ID_USUARIO");
ALTER TABLE legacy."PARTIDOS" ADD CONSTRAINT "partidos_id_fecha_foreign" FOREIGN KEY("ID_FECHA") REFERENCES legacy."FECHAS"("ID_FECHA");
ALTER TABLE legacy."CONVOCATORIAS" ADD CONSTRAINT "convocatorias_id_usuario_foreign" FOREIGN KEY("ID_USUARIO") REFERENCES legacy."USUARIOS"("ID_USUARIO");
ALTER TABLE legacy."PARTIDOS" ADD CONSTRAINT "partidos_jugador_destacado_id_foreign" FOREIGN KEY("JUGADOR_DESTACADO_ID") REFERENCES legacy."USUARIOS"("ID_USUARIO");

ALTER TABLE legacy."FECHAS" ADD CONSTRAINT "fechas_id_torneo_foreign" FOREIGN KEY("ID_TORNEO") REFERENCES legacy."TORNEOS"("ID_TORNEO");
ALTER TABLE legacy."USUARIO_DEPORTE" ADD CONSTRAINT "usuario_deporte_id_deporte_foreign" FOREIGN KEY("ID_DEPORTE") REFERENCES legacy."DEPORTES"("ID_DEPORTE");
ALTER TABLE legacy."CONVOCATORIAS" ADD CONSTRAINT "convocatorias_id_partido_foreign" FOREIGN KEY("ID_PARTIDO") REFERENCES legacy."PARTIDOS"("ID_PARTIDO");
ALTER TABLE legacy."ESTADISTICAS" ADD CONSTRAINT "estadisticas_id_tipo_est_foreign" FOREIGN KEY("ID_TIPO_EST") REFERENCES legacy."TIPOS_ESTADISTICA"("ID_TIPO_EST");
ALTER TABLE legacy."SANCIONES" ADD CONSTRAINT "sanciones_id_tipo_sanc_foreign" FOREIGN KEY("ID_TIPO_SANC") REFERENCES legacy."TIPOS_SANCION"("ID_TIPO_SANC");
ALTER TABLE legacy."USUARIO_DEPORTE" ADD CONSTRAINT "usuario_deporte_id_rol_foreign" FOREIGN KEY("ID_ROL") REFERENCES legacy."ROLES"("ID_ROL");
ALTER TABLE legacy."TORNEOS" ADD CONSTRAINT "torneos_id_categoria_foreign" FOREIGN KEY("ID_CATEGORIA") REFERENCES legacy."CATEGORIAS"("ID_CATEGORIA");
ALTER TABLE legacy."CAMBIOS" ADD CONSTRAINT "cambios_id_usuario_sale_foreign" FOREIGN KEY("ID_USUARIO_SALE") REFERENCES legacy."USUARIOS"("ID_USUARIO");
ALTER TABLE legacy."USUARIO_DEPORTE" ADD CONSTRAINT "usuario_deporte_id_categoria_foreign" FOREIGN KEY("ID_CATEGORIA") REFERENCES legacy."CATEGORIAS"("ID_CATEGORIA");


-- =====================================================================
-- FOREIGN KEYS — Deportes Individuales (NUEVO)
-- =====================================================================

ALTER TABLE legacy."DISCIPLINAS" ADD CONSTRAINT "disciplinas_id_deporte_foreign" FOREIGN KEY("ID_DEPORTE") REFERENCES legacy."DEPORTES"("ID_DEPORTE");

ALTER TABLE legacy."ESTACIONES" ADD CONSTRAINT "estaciones_id_torneo_foreign" FOREIGN KEY("ID_TORNEO") REFERENCES legacy."TORNEOS"("ID_TORNEO");
ALTER TABLE legacy."ESTACIONES" ADD CONSTRAINT "estaciones_iddis_foreign" FOREIGN KEY("IDDIS") REFERENCES legacy."DISCIPLINAS"("IDDIS");

ALTER TABLE legacy."PUNTOS" ADD CONSTRAINT "puntos_id_usudep_foreign" FOREIGN KEY("ID_USUDEP") REFERENCES legacy."USUARIO_DEPORTE"("ID_USUDEP");
ALTER TABLE legacy."PUNTOS" ADD CONSTRAINT "puntos_idestacion_foreign" FOREIGN KEY("IDESTACION") REFERENCES legacy."ESTACIONES"("IDESTACION");
ALTER TABLE legacy."PUNTOS" ADD CONSTRAINT "puntos_id_categoria_foreign" FOREIGN KEY("ID_CATEGORIA") REFERENCES legacy."CATEGORIAS"("ID_CATEGORIA");

-- Relaciones padre-hijo corregidas respecto al archivo v4.
ALTER TABLE legacy."RESULTADOS" ADD CONSTRAINT resultados_partido_fk
 FOREIGN KEY("ID_PARTIDO") REFERENCES legacy."PARTIDOS"("ID_PARTIDO");
ALTER TABLE legacy."AUTORIZACIONES" ADD CONSTRAINT autorizaciones_convocatoria_fk
 FOREIGN KEY("ID_CONVOCATORIA") REFERENCES legacy."CONVOCATORIAS"("ID_CONVOCATORIA");


-- ========= NUEVO DOMINIO INDIVIDUAL =========

-- PUBLIC: tablas operativas. UUID generados por PostgreSQL (Supabase PG >= 15).
CREATE TABLE public.deportes (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), nombre text NOT NULL UNIQUE,
 descripcion text, activo boolean NOT NULL DEFAULT true
);
CREATE TABLE public.categorias (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), deporte_id uuid NOT NULL REFERENCES public.deportes(id),
 nombre text NOT NULL, UNIQUE(deporte_id, nombre), UNIQUE(id, deporte_id)
);
CREATE TABLE public.disciplinas (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), deporte_id uuid NOT NULL REFERENCES public.deportes(id),
 nombre text NOT NULL, UNIQUE(deporte_id, nombre), UNIQUE(id, deporte_id)
);
CREATE TABLE public.colegios (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), nombre text NOT NULL UNIQUE,
 contacto text, telefono text, email text
);
-- Identidad personal global, TAMBIEN para deportistas; la cuenta de Auth es optativa.
-- DNI/FNAC optativos para staff; obligatorios al inscribirse en una competencia.
-- Un perfil sin cuenta puede adquirirla a futuro, sin alterar las puntuaciones.
CREATE TABLE public.usuarios (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 nombre text NOT NULL CHECK (length(trim(nombre))>0), apellido text,
 dni text UNIQUE, fecha_nacimiento date,
 auth_user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
 creado_en timestamptz NOT NULL DEFAULT now(),
 CHECK (dni IS NULL OR length(trim(dni))>0)
);
CREATE INDEX usuarios_auth_idx ON public.usuarios(auth_user_id) WHERE auth_user_id IS NOT NULL;
CREATE TABLE public.roles_globales (
 usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE RESTRICT,
 rol text NOT NULL CHECK (rol IN ('admin')),
 PRIMARY KEY(usuario_id, rol)
);
CREATE TABLE public.torneos (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), nombre text NOT NULL,
 deporte_id uuid NOT NULL REFERENCES public.deportes(id),
 colegio_anfitrion_id uuid NOT NULL REFERENCES public.colegios(id),
 fecha date NOT NULL,
 estado text NOT NULL DEFAULT 'preparacion' CHECK(estado IN ('preparacion','en_curso','finalizado')),
 creado_en timestamptz NOT NULL DEFAULT now(),
 UNIQUE(id, deporte_id)
);
CREATE TABLE public.torneo_roles (
 torneo_id uuid NOT NULL REFERENCES public.torneos(id) ON DELETE RESTRICT,
 usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE RESTRICT,
 rol text NOT NULL CHECK (rol IN ('organizador','juez')),
 PRIMARY KEY(torneo_id, usuario_id, rol)
);
CREATE INDEX torneo_roles_usuario_idx ON public.torneo_roles(usuario_id, torneo_id);
CREATE TABLE public.torneo_categorias (
 torneo_id uuid NOT NULL, categoria_id uuid NOT NULL, deporte_id uuid NOT NULL,
 PRIMARY KEY(torneo_id, categoria_id),
 FOREIGN KEY(torneo_id, deporte_id) REFERENCES public.torneos(id, deporte_id),
 FOREIGN KEY(categoria_id, deporte_id) REFERENCES public.categorias(id, deporte_id)
);
CREATE TABLE public.torneo_colegios (
 torneo_id uuid NOT NULL REFERENCES public.torneos(id),
 colegio_id uuid NOT NULL REFERENCES public.colegios(id),
 posicion_inicial int CHECK (posicion_inicial > 0),
 PRIMARY KEY(torneo_id, colegio_id)
);
CREATE UNIQUE INDEX torneo_colegios_posicion_unica
 ON public.torneo_colegios(torneo_id, posicion_inicial) WHERE posicion_inicial IS NOT NULL;
CREATE TABLE public.inscripciones (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 torneo_id uuid NOT NULL, colegio_id uuid NOT NULL,
 usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE RESTRICT,
 categoria_id uuid NOT NULL,
 estado text NOT NULL DEFAULT 'activo' CHECK(estado IN ('activo','retirado')),
 creado_en timestamptz NOT NULL DEFAULT now(), retirado_en timestamptz,
 UNIQUE(torneo_id, usuario_id), UNIQUE(id, torneo_id, colegio_id),
 FOREIGN KEY(torneo_id, colegio_id) REFERENCES public.torneo_colegios(torneo_id, colegio_id),
 FOREIGN KEY(torneo_id, categoria_id) REFERENCES public.torneo_categorias(torneo_id, categoria_id),
 CHECK ((estado='activo' AND retirado_en IS NULL) OR (estado='retirado' AND retirado_en IS NOT NULL))
);
CREATE INDEX inscripciones_torneo_colegio_idx ON public.inscripciones(torneo_id, colegio_id);
CREATE INDEX inscripciones_usuario_idx ON public.inscripciones(usuario_id);
CREATE TABLE public.estaciones (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 torneo_id uuid NOT NULL, deporte_id uuid NOT NULL, disciplina_id uuid,
 numero int NOT NULL CHECK(numero>0), nombre text NOT NULL,
 FOREIGN KEY(torneo_id, deporte_id) REFERENCES public.torneos(id, deporte_id),
 FOREIGN KEY(disciplina_id, deporte_id) REFERENCES public.disciplinas(id, deporte_id),
 UNIQUE(torneo_id, numero), UNIQUE(id, torneo_id)
);
CREATE TABLE public.circuito_posiciones (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), torneo_id uuid NOT NULL REFERENCES public.torneos(id),
 orden int NOT NULL CHECK(orden>0), estacion_id uuid,
 UNIQUE(torneo_id, orden), UNIQUE(id, torneo_id), UNIQUE(estacion_id),
 FOREIGN KEY(estacion_id, torneo_id) REFERENCES public.estaciones(id, torneo_id)
);
CREATE TABLE public.rondas (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), torneo_id uuid NOT NULL REFERENCES public.torneos(id),
 numero int NOT NULL CHECK(numero>0),
 estado text NOT NULL DEFAULT 'en_curso' CHECK (estado IN ('en_curso','finalizada')),
 iniciada_en timestamptz NOT NULL DEFAULT now(), finalizada_en timestamptz,
 UNIQUE(torneo_id, numero), UNIQUE(id, torneo_id),
 CHECK ((estado='en_curso' AND finalizada_en IS NULL) OR (estado='finalizada' AND finalizada_en IS NOT NULL))
);
CREATE UNIQUE INDEX una_ronda_activa_por_torneo ON public.rondas(torneo_id) WHERE estado='en_curso';
CREATE TABLE public.ronda_asignaciones (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 torneo_id uuid NOT NULL, ronda_id uuid NOT NULL, colegio_id uuid NOT NULL,
 posicion_id uuid NOT NULL, confirmada_en timestamptz,
 confirmada_por uuid REFERENCES public.usuarios(id) ON DELETE RESTRICT,
 FOREIGN KEY(ronda_id, torneo_id) REFERENCES public.rondas(id, torneo_id),
 FOREIGN KEY(torneo_id, colegio_id) REFERENCES public.torneo_colegios(torneo_id, colegio_id),
 FOREIGN KEY(posicion_id, torneo_id) REFERENCES public.circuito_posiciones(id, torneo_id),
 UNIQUE(ronda_id, colegio_id), UNIQUE(ronda_id, posicion_id),
 CHECK ((confirmada_en IS NULL AND confirmada_por IS NULL) OR
        (confirmada_en IS NOT NULL AND confirmada_por IS NOT NULL))
);
CREATE INDEX ronda_asignaciones_ronda_idx ON public.ronda_asignaciones(ronda_id);
CREATE TABLE public.evaluaciones (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 inscripcion_id uuid NOT NULL REFERENCES public.inscripciones(id) ON DELETE RESTRICT,
 asignacion_id uuid NOT NULL REFERENCES public.ronda_asignaciones(id) ON DELETE RESTRICT,
 estacion_id uuid NOT NULL REFERENCES public.estaciones(id) ON DELETE RESTRICT,
 estado text NOT NULL CHECK (estado IN ('evaluado','ausente')),
 puntaje numeric, -- no numeric(2,1): evitar que PG redondee silenciosamente entradas invalidas
 actualizado_por uuid REFERENCES public.usuarios(id) ON DELETE RESTRICT,
 actualizado_en timestamptz NOT NULL DEFAULT now(),
 UNIQUE(inscripcion_id, estacion_id),
 CHECK (puntaje IS NULL OR (puntaje BETWEEN 0 AND 3 AND puntaje*10=trunc(puntaje*10))),
 CHECK ((estado='evaluado' AND puntaje IS NOT NULL AND actualizado_por IS NOT NULL)
    OR (estado='ausente' AND puntaje IS NULL))
);
CREATE INDEX evaluaciones_asignacion_idx ON public.evaluaciones(asignacion_id);

-- ========= PRIVADO: IDENTIDAD Y AUTORIZACION =========
-- SECURITY DEFINER con search_path inmovilizado: ninguna funcion confia en IDs del cliente.
CREATE FUNCTION private.usuario_actual() RETURNS uuid
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT u.id FROM public.usuarios u WHERE u.auth_user_id = (SELECT auth.uid()) LIMIT 1
$$;
CREATE FUNCTION private.es_admin() RETURNS boolean
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT EXISTS(SELECT 1 FROM public.roles_globales rg
               WHERE rg.usuario_id = private.usuario_actual() AND rg.rol='admin')
$$;
CREATE FUNCTION private.puede_organizar(p_torneo uuid) RETURNS boolean
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT private.es_admin() OR EXISTS (
  SELECT 1 FROM public.torneo_roles tr
  WHERE tr.torneo_id=p_torneo AND tr.usuario_id=private.usuario_actual() AND tr.rol='organizador')
$$;
CREATE FUNCTION private.puede_juzgar(p_torneo uuid) RETURNS boolean
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT private.puede_organizar(p_torneo) OR EXISTS (
  SELECT 1 FROM public.torneo_roles tr
  WHERE tr.torneo_id=p_torneo AND tr.usuario_id=private.usuario_actual() AND tr.rol='juez')
$$;
CREATE FUNCTION private.puede_ver_torneo(p_torneo uuid) RETURNS boolean
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT private.puede_juzgar(p_torneo) OR EXISTS (
  SELECT 1 FROM public.inscripciones i
  WHERE i.torneo_id=p_torneo AND i.usuario_id=private.usuario_actual())
$$;
CREATE FUNCTION private.puede_ver_usuario(p_usuario uuid) RETURNS boolean
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT private.es_admin() OR private.usuario_actual()=p_usuario OR EXISTS (
  SELECT 1 FROM public.inscripciones i
  WHERE i.usuario_id=p_usuario AND private.puede_organizar(i.torneo_id)) OR EXISTS (
  SELECT 1 FROM public.torneo_roles tr
  WHERE tr.usuario_id=p_usuario AND private.puede_organizar(tr.torneo_id))
$$;
CREATE FUNCTION private.puede_ver_evaluacion(p_inscripcion uuid) RETURNS boolean
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT EXISTS(SELECT 1 FROM public.inscripciones i
   WHERE i.id=p_inscripcion AND
    (private.puede_juzgar(i.torneo_id) OR i.usuario_id=private.usuario_actual()))
$$;

-- ========= VALIDACIONES EN BD, INCLUSO FRENTE A UN CLIENTE PRIVILEGIADO =========
CREATE FUNCTION private.validar_inscripcion() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_dni text; v_fecha date; v_estado text;
BEGIN
 SELECT dni, fecha_nacimiento INTO v_dni,v_fecha FROM public.usuarios WHERE id=NEW.usuario_id;
 IF v_dni IS NULL OR v_fecha IS NULL THEN
  RAISE EXCEPTION 'Para inscribir un gimnasta se necesitan DNI y fecha de nacimiento';
 END IF;
 SELECT estado INTO v_estado FROM public.torneos WHERE id=NEW.torneo_id;
 IF TG_OP='INSERT' AND v_estado='finalizado' THEN
  RAISE EXCEPTION 'No se inscriben participantes en un torneo cerrado';
 END IF;
 IF TG_OP='UPDATE' THEN
  IF (NEW.torneo_id,NEW.colegio_id,NEW.usuario_id,NEW.categoria_id)
     IS DISTINCT FROM (OLD.torneo_id,OLD.colegio_id,OLD.usuario_id,OLD.categoria_id) THEN
   RAISE EXCEPTION 'La inscripcion historica no permite cambiar torneo, colegio, usuario ni categoria';
  END IF;
  IF OLD.estado='retirado' AND NEW.estado='activo' THEN
   RAISE EXCEPTION 'No se reactiva una baja historica en esta version';
  END IF;
 END IF;
 RETURN NEW;
END; $$;
CREATE TRIGGER validar_inscripcion BEFORE INSERT OR UPDATE ON public.inscripciones
 FOR EACH ROW EXECUTE FUNCTION private.validar_inscripcion();

CREATE FUNCTION private.validar_evaluacion() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_torneo uuid; v_colegio uuid; v_estacion uuid; v_activo text; v_cierre timestamptz;
BEGIN
 SELECT i.torneo_id,i.colegio_id,i.estado INTO v_torneo,v_colegio,v_activo
 FROM public.inscripciones i WHERE i.id=NEW.inscripcion_id;
 IF v_activo <> 'activo' AND TG_OP='INSERT' THEN
   RAISE EXCEPTION 'Un participante retirado no acepta puntuaciones nuevas';
 END IF;
 IF TG_OP='UPDATE' AND (NEW.inscripcion_id,NEW.estacion_id,NEW.asignacion_id)
     IS DISTINCT FROM (OLD.inscripcion_id,OLD.estacion_id,OLD.asignacion_id) THEN
   RAISE EXCEPTION 'No se puede trasladar una evaluacion de participante/estacion/ronda';
 END IF;
 SELECT cp.estacion_id,ra.confirmada_en INTO v_estacion,v_cierre
 FROM public.ronda_asignaciones ra JOIN public.circuito_posiciones cp ON cp.id=ra.posicion_id
 WHERE ra.id=NEW.asignacion_id AND ra.torneo_id=v_torneo AND ra.colegio_id=v_colegio;
 IF NOT FOUND OR v_estacion IS DISTINCT FROM NEW.estacion_id THEN
  RAISE EXCEPTION 'Evaluacion no pertenece al colegio, estacion y ronda indicados';
 END IF;
 RETURN NEW;
END; $$;
CREATE TRIGGER validar_evaluacion BEFORE INSERT OR UPDATE ON public.evaluaciones
 FOR EACH ROW EXECUTE FUNCTION private.validar_evaluacion();

-- ========= API SEGURA: CONFIGURACION =========
CREATE FUNCTION private.crear_torneo(p_nombre text,p_deporte uuid,p_anfitrion uuid,p_fecha date)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_id uuid;
BEGIN
 IF NOT private.es_admin() THEN RAISE EXCEPTION 'Solo administrador puede crear torneos'; END IF;
 INSERT INTO public.torneos(nombre,deporte_id,colegio_anfitrion_id,fecha)
 VALUES (p_nombre,p_deporte,p_anfitrion,p_fecha) RETURNING id INTO v_id;
 RETURN v_id;
END; $$;

CREATE FUNCTION private.editar_torneo_basico(p_torneo uuid,p_nombre text,p_fecha date)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT private.puede_organizar(p_torneo) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 UPDATE public.torneos SET nombre=p_nombre,fecha=p_fecha
 WHERE id=p_torneo AND estado='preparacion';
 IF NOT FOUND THEN RAISE EXCEPTION 'Torneo inexistente o ya iniciado'; END IF;
END; $$;

CREATE FUNCTION private.agregar_colegio_torneo(p_torneo uuid,p_colegio uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT private.puede_organizar(p_torneo) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 IF (SELECT estado FROM public.torneos WHERE id=p_torneo FOR UPDATE)<>'preparacion' THEN
  RAISE EXCEPTION 'No se cambia el circuito iniciado'; END IF;
 INSERT INTO public.torneo_colegios(torneo_id,colegio_id) VALUES(p_torneo,p_colegio)
 ON CONFLICT DO NOTHING;
END; $$;

CREATE FUNCTION private.habilitar_categoria_torneo(p_torneo uuid,p_categoria uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_dep uuid;
BEGIN
 IF NOT private.puede_organizar(p_torneo) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 SELECT deporte_id INTO v_dep FROM public.torneos WHERE id=p_torneo AND estado='preparacion' FOR UPDATE;
 IF v_dep IS NULL THEN RAISE EXCEPTION 'Torneo no configurable'; END IF;
 INSERT INTO public.torneo_categorias(torneo_id,categoria_id,deporte_id)
 VALUES(p_torneo,p_categoria,v_dep) ON CONFLICT DO NOTHING;
END; $$;

CREATE FUNCTION private.crear_estacion(p_torneo uuid,p_numero integer,p_nombre text,p_disciplina uuid DEFAULT NULL)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_dep uuid; v_id uuid;
BEGIN
 IF NOT private.puede_organizar(p_torneo) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 SELECT deporte_id INTO v_dep FROM public.torneos WHERE id=p_torneo AND estado='preparacion' FOR UPDATE;
 IF v_dep IS NULL THEN RAISE EXCEPTION 'Torneo no configurable'; END IF;
 INSERT INTO public.estaciones(torneo_id,deporte_id,numero,nombre,disciplina_id)
 VALUES (p_torneo,v_dep,p_numero,p_nombre,p_disciplina) RETURNING id INTO v_id;
 RETURN v_id;
END; $$;

-- Solo administrador puede vincular un perfil con la cuenta creada por Supabase Auth.
-- Comprobar identidad real antes de llamar: nunca permitir autoclaim por DNI.
CREATE FUNCTION private.vincular_usuario_auth(p_usuario uuid,p_auth uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT private.es_admin() THEN RAISE EXCEPTION 'Solo administrador'; END IF;
 UPDATE public.usuarios SET auth_user_id=p_auth WHERE id=p_usuario AND auth_user_id IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Perfil inexistente o ya vinculado'; END IF;
END; $$;

-- Asignacion de juez disponible al organizador; organizador solo por un admin.
CREATE FUNCTION private.habilitar_personal_torneo(p_torneo uuid,p_usuario uuid,p_rol text)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF p_rol NOT IN ('organizador','juez') OR p_rol IS NULL THEN RAISE EXCEPTION 'Rol invalido'; END IF;
 IF NOT private.puede_organizar(p_torneo) OR (p_rol='organizador' AND NOT private.es_admin()) THEN
  RAISE EXCEPTION 'No autorizado a asignar ese rol'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.usuarios WHERE id=p_usuario AND auth_user_id IS NOT NULL) THEN
  RAISE EXCEPTION 'El personal requiere cuenta Supabase Auth vinculada'; END IF;
 INSERT INTO public.torneo_roles(torneo_id,usuario_id,rol) VALUES(p_torneo,p_usuario,p_rol)
 ON CONFLICT DO NOTHING;
END; $$;

-- ========= API SEGURA: INSCRIPCIONES Y BAJAS =========
CREATE FUNCTION private.inscribir_participante(
 p_torneo uuid,p_colegio uuid,p_categoria uuid,p_nombre text,p_dni text,p_fnac date,
 p_apellido text DEFAULT NULL)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_usuario uuid; v_id uuid; v_fnac date; v_estado text;
BEGIN
 IF NOT private.puede_organizar(p_torneo) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 SELECT estado INTO v_estado FROM public.torneos WHERE id=p_torneo FOR UPDATE;
 IF v_estado IS NULL OR v_estado='finalizado' THEN RAISE EXCEPTION 'Torneo no acepta inscripciones'; END IF;
 IF p_nombre IS NULL OR length(trim(p_nombre))=0 OR p_dni IS NULL OR
    length(trim(p_dni))=0 OR p_fnac IS NULL THEN
  RAISE EXCEPTION 'Nombre, DNI y fecha de nacimiento obligatorios'; END IF;
 INSERT INTO public.usuarios(nombre,apellido,dni,fecha_nacimiento)
 VALUES(trim(p_nombre),nullif(trim(p_apellido),''),trim(p_dni),p_fnac)
 ON CONFLICT(dni) DO NOTHING RETURNING id INTO v_usuario;
 IF v_usuario IS NULL THEN
  SELECT id,fecha_nacimiento INTO v_usuario,v_fnac FROM public.usuarios WHERE dni=trim(p_dni);
  IF v_fnac IS DISTINCT FROM p_fnac THEN
    RAISE EXCEPTION 'DNI ya registrado con fecha de nacimiento diferente'; END IF;
 END IF;
 INSERT INTO public.inscripciones(torneo_id,colegio_id,categoria_id,usuario_id)
 VALUES(p_torneo,p_colegio,p_categoria,v_usuario) RETURNING id INTO v_id;
 RETURN v_id;
END; $$;

CREATE FUNCTION private.retirar_participante(p_inscripcion uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_torneo uuid;
BEGIN
 SELECT torneo_id INTO v_torneo FROM public.inscripciones WHERE id=p_inscripcion;
 IF NOT private.puede_organizar(v_torneo) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 PERFORM 1 FROM public.torneos WHERE id=v_torneo FOR UPDATE;
 UPDATE public.inscripciones SET estado='retirado', retirado_en=now()
 WHERE id=p_inscripcion AND estado='activo';
 -- Los puntos institucionales ya registrados permanecen intactos.
END; $$;

-- ========= API SEGURA: INICIO DE CIRCUITO Y ROTACIONES =========
CREATE FUNCTION private.iniciar_torneo(p_torneo uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_est int; v_col int; v_n int; v_ronda uuid;
BEGIN
 IF NOT private.puede_organizar(p_torneo) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 PERFORM 1 FROM public.torneos WHERE id=p_torneo AND estado='preparacion' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Torneo no esta en preparacion'; END IF;
 SELECT count(*) INTO v_est FROM public.estaciones WHERE torneo_id=p_torneo;
 SELECT count(*) INTO v_col FROM public.torneo_colegios WHERE torneo_id=p_torneo;
 IF v_est=0 OR v_col=0 THEN RAISE EXCEPTION 'El circuito requiere estaciones y colegios'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.inscripciones WHERE torneo_id=p_torneo AND estado='activo') THEN
  RAISE EXCEPTION 'El torneo requiere participantes activos'; END IF;
 v_n:=greatest(v_est,v_col);
 -- Posiciones 1..N: estaciones en orden ascendente y esperas al final.
 WITH numeradas AS (
  SELECT id, row_number() OVER (ORDER BY numero)::int AS orden
  FROM public.estaciones WHERE torneo_id=p_torneo
 )
 INSERT INTO public.circuito_posiciones(torneo_id,orden,estacion_id)
 SELECT p_torneo,g.n,numeradas.id FROM generate_series(1,v_n) AS g(n)
 LEFT JOIN numeradas ON numeradas.orden=g.n;
 -- Orden inicial deterministico entre los colegios inscritos.
 WITH numerados AS (
  SELECT colegio_id,row_number() OVER(ORDER BY colegio_id)::int AS pos
  FROM public.torneo_colegios WHERE torneo_id=p_torneo
 )
 UPDATE public.torneo_colegios tc SET posicion_inicial=n.pos
 FROM numerados n WHERE tc.torneo_id=p_torneo AND tc.colegio_id=n.colegio_id;
 INSERT INTO public.rondas(torneo_id,numero) VALUES(p_torneo,1) RETURNING id INTO v_ronda;
 INSERT INTO public.ronda_asignaciones(torneo_id,ronda_id,colegio_id,posicion_id)
 SELECT p_torneo,v_ronda,tc.colegio_id,cp.id
 FROM public.torneo_colegios tc JOIN public.circuito_posiciones cp
 ON cp.torneo_id=tc.torneo_id AND cp.orden=tc.posicion_inicial WHERE tc.torneo_id=p_torneo;
 UPDATE public.torneos SET estado='en_curso' WHERE id=p_torneo;
END; $$;

-- Una llamada de juez activa en la ronda actual. Actualizar requiere mismo contexto.
CREATE FUNCTION private.registrar_puntaje(p_inscripcion uuid,p_estacion uuid,p_puntaje numeric)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_torneo uuid; v_colegio uuid; v_estado text; v_actor uuid;
        v_asignacion uuid; v_confirmada timestamptz; v_id uuid;
BEGIN
 SELECT torneo_id,colegio_id,estado INTO v_torneo,v_colegio,v_estado
 FROM public.inscripciones WHERE id=p_inscripcion;
 v_actor:=private.usuario_actual();
 IF v_actor IS NULL OR NOT private.puede_juzgar(v_torneo) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 PERFORM 1 FROM public.torneos WHERE id=v_torneo FOR UPDATE;
 -- Releer tras obtener el bloqueo: una baja concurrente no puede quedar invisibilizada.
 SELECT estado INTO v_estado FROM public.inscripciones WHERE id=p_inscripcion;
 IF p_puntaje IS NULL OR p_puntaje < 0 OR p_puntaje > 3 OR p_puntaje*10<>trunc(p_puntaje*10)
 THEN RAISE EXCEPTION 'El puntaje debe ser 0.0 a 3.0 en pasos de 0.1'; END IF;
 IF v_estado<>'activo' THEN RAISE EXCEPTION 'Gimnasta retirado'; END IF;
 SELECT ra.id,ra.confirmada_en INTO v_asignacion,v_confirmada
 FROM public.ronda_asignaciones ra
 JOIN public.rondas r ON r.id=ra.ronda_id
 JOIN public.circuito_posiciones cp ON cp.id=ra.posicion_id
 WHERE ra.torneo_id=v_torneo AND ra.colegio_id=v_colegio
 AND r.estado='en_curso' AND cp.estacion_id=p_estacion;
 IF v_asignacion IS NULL THEN
  -- Una correccion posterior puede encontrar la evaluacion historica si el actor gestiona el torneo.
  IF NOT private.puede_organizar(v_torneo) THEN RAISE EXCEPTION 'La estacion no corresponde a la ronda activa'; END IF;
  SELECT asignacion_id INTO v_asignacion FROM public.evaluaciones
    WHERE inscripcion_id=p_inscripcion AND estacion_id=p_estacion;
  IF v_asignacion IS NULL THEN RAISE EXCEPTION 'No existe evaluacion historica para corregir'; END IF;
 ELSIF v_confirmada IS NOT NULL AND NOT private.puede_organizar(v_torneo) THEN
  RAISE EXCEPTION 'Estacion ya confirmada';
 END IF;
 INSERT INTO public.evaluaciones(inscripcion_id,asignacion_id,estacion_id,estado,puntaje,actualizado_por)
 VALUES(p_inscripcion,v_asignacion,p_estacion,'evaluado',p_puntaje,v_actor)
 ON CONFLICT(inscripcion_id,estacion_id) DO UPDATE
 SET puntaje=excluded.puntaje,estado='evaluado',actualizado_por=excluded.actualizado_por,
     actualizado_en=now()
 RETURNING id INTO v_id;
 RETURN v_id;
END; $$;

CREATE FUNCTION private.confirmar_estacion(p_asignacion uuid)
 RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_ra public.ronda_asignaciones%ROWTYPE; v_torneo public.torneos%ROWTYPE;
 v_estacion uuid; v_ronda public.rondas%ROWTYPE;
 v_posiciones int; v_nueva_ronda uuid;
BEGIN
 SELECT * INTO v_ra FROM public.ronda_asignaciones WHERE id=p_asignacion;
 IF NOT FOUND THEN RAISE EXCEPTION 'Asignacion inexistente'; END IF;
 IF NOT private.puede_juzgar(v_ra.torneo_id) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 SELECT * INTO v_torneo FROM public.torneos WHERE id=v_ra.torneo_id FOR UPDATE;
 -- Bloqueo del torneo serializa la llegada de las confirmaciones.
 SELECT * INTO v_ra FROM public.ronda_asignaciones WHERE id=p_asignacion;
 IF v_ra.confirmada_en IS NOT NULL THEN RETURN 'ya_confirmada'; END IF;
 IF v_torneo.estado<>'en_curso' THEN RAISE EXCEPTION 'Torneo no esta en curso'; END IF;
 SELECT * INTO v_ronda FROM public.rondas WHERE id=v_ra.ronda_id;
 IF v_ronda.estado<>'en_curso' THEN RAISE EXCEPTION 'Ronda no activa'; END IF;
 SELECT estacion_id INTO v_estacion FROM public.circuito_posiciones WHERE id=v_ra.posicion_id;
 IF v_estacion IS NULL THEN RAISE EXCEPTION 'Las posiciones de espera no se confirman'; END IF;
 -- Todas las evaluaciones que faltan se registran como ausencia (puntaje NULL).
 INSERT INTO public.evaluaciones(inscripcion_id,asignacion_id,estacion_id,estado,puntaje)
 SELECT i.id,v_ra.id,v_estacion,'ausente',NULL
 FROM public.inscripciones i
 WHERE i.torneo_id=v_ra.torneo_id AND i.colegio_id=v_ra.colegio_id AND i.estado='activo'
 ON CONFLICT(inscripcion_id,estacion_id) DO NOTHING;
 UPDATE public.ronda_asignaciones SET confirmada_en=now(),confirmada_por=private.usuario_actual()
 WHERE id=v_ra.id;
 -- Las estaciones desocupadas y las posiciones de espera NO bloquean el avance.
 IF EXISTS(
   SELECT 1 FROM public.ronda_asignaciones ra
   JOIN public.circuito_posiciones cp ON cp.id=ra.posicion_id
   WHERE ra.ronda_id=v_ra.ronda_id AND cp.estacion_id IS NOT NULL AND ra.confirmada_en IS NULL
 ) THEN RETURN 'estacion_confirmada'; END IF;
 UPDATE public.rondas SET estado='finalizada',finalizada_en=now() WHERE id=v_ra.ronda_id;
 SELECT count(*) INTO v_posiciones FROM public.circuito_posiciones WHERE torneo_id=v_ra.torneo_id;
 IF v_ronda.numero>=v_posiciones THEN
  UPDATE public.torneos SET estado='finalizado' WHERE id=v_ra.torneo_id;
  RETURN 'torneo_finalizado';
 END IF;
 INSERT INTO public.rondas(torneo_id,numero) VALUES(v_ra.torneo_id,v_ronda.numero+1)
 RETURNING id INTO v_nueva_ronda;
 INSERT INTO public.ronda_asignaciones(torneo_id,ronda_id,colegio_id,posicion_id)
 SELECT v_ra.torneo_id,v_nueva_ronda,tc.colegio_id,cp.id
 FROM public.torneo_colegios tc
 JOIN public.circuito_posiciones cp ON cp.torneo_id=tc.torneo_id
 AND cp.orden=((tc.posicion_inicial-1+v_ronda.numero)%v_posiciones)+1
 WHERE tc.torneo_id=v_ra.torneo_id;
 RETURN 'ronda_rotada';
END; $$;

-- ========= API LECTURA: LISTADO JUEZ SIN DNI/FNAC =========
CREATE FUNCTION private.listar_gimnastas_estacion(p_asignacion uuid)
 RETURNS TABLE(inscripcion_id uuid,nombre text,apellido text,categoria text,
                puntaje numeric,estado_evaluacion text)
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE v_torneo uuid;
BEGIN
 SELECT torneo_id INTO v_torneo FROM public.ronda_asignaciones WHERE id=p_asignacion;
 IF v_torneo IS NULL OR NOT private.puede_juzgar(v_torneo) THEN
  RAISE EXCEPTION 'No autorizado'; END IF;
 RETURN QUERY
 SELECT i.id,u.nombre,u.apellido,c.nombre,e.puntaje,e.estado
 FROM public.ronda_asignaciones ra
 JOIN public.circuito_posiciones cp ON cp.id=ra.posicion_id AND cp.estacion_id IS NOT NULL
 JOIN public.inscripciones i ON i.torneo_id=ra.torneo_id AND i.colegio_id=ra.colegio_id
 JOIN public.usuarios u ON u.id=i.usuario_id
 JOIN public.categorias c ON c.id=i.categoria_id
 LEFT JOIN public.evaluaciones e ON e.inscripcion_id=i.id AND e.estacion_id=cp.estacion_id
 WHERE ra.id=p_asignacion AND i.estado='activo'
 ORDER BY c.nombre, u.apellido NULLS LAST, u.nombre;
END; $$;

-- Funcion preparada para el portal propio del gimnasta: autoriza por auth.uid(), no por ID ingresado.
CREATE FUNCTION private.mis_puntajes()
 RETURNS TABLE(torneo_id uuid,torneo text,estacion text,puntaje numeric,estado text)
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE v_actor uuid;
BEGIN
 v_actor:=private.usuario_actual();
 IF v_actor IS NULL THEN RAISE EXCEPTION 'Usuario sin cuenta vinculada'; END IF;
 RETURN QUERY
 SELECT i.torneo_id,t.nombre,s.nombre,e.puntaje,
   COALESCE(e.estado,'pendiente')::text
 FROM public.inscripciones i JOIN public.torneos t ON t.id=i.torneo_id
 JOIN public.estaciones s ON s.torneo_id=i.torneo_id
 LEFT JOIN public.evaluaciones e ON e.inscripcion_id=i.id AND e.estacion_id=s.id
 WHERE i.usuario_id=v_actor ORDER BY t.fecha DESC,s.numero;
END; $$;

-- ========= API DE PODIOS (NO PUBLICOS; SOLO ADMIN/ORGANIZADOR) =========
-- 'individual_general', 'individual_categoria', 'mejor_por_colegio', 'colegios'
-- DENSE_RANK: 1,2,2,3. NULL se muestra y se ordena ultimo, detras del 0.
CREATE FUNCTION private.obtener_podios(p_torneo uuid)
 RETURNS TABLE(tipo text,grupo_id uuid,inscripcion_id uuid,participante text,
  colegio_id uuid,colegio text,total numeric,puesto bigint)
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT private.puede_organizar(p_torneo) THEN RAISE EXCEPTION 'Podio reservado al organizador'; END IF;
 RETURN QUERY
 WITH ind AS (
  SELECT i.id AS iid,i.categoria_id,i.colegio_id,
         (u.nombre || COALESCE(' '||u.apellido,'')) AS nom,
         c.nombre AS cole, SUM(e.puntaje) AS puntos
  FROM public.inscripciones i
  JOIN public.usuarios u ON u.id=i.usuario_id
  JOIN public.colegios c ON c.id=i.colegio_id
  LEFT JOIN public.evaluaciones e ON e.inscripcion_id=i.id
  WHERE i.torneo_id=p_torneo
  GROUP BY i.id,i.categoria_id,i.colegio_id,u.nombre,u.apellido,c.nombre
 ),
 general AS (
  SELECT 'individual_general'::text AS t,NULL::uuid AS g,ind.iid,ind.nom,ind.colegio_id,ind.cole,ind.puntos,
    dense_rank() OVER (ORDER BY ind.puntos DESC NULLS LAST) AS puesto FROM ind
 ),
 por_categoria AS (
  SELECT 'individual_categoria'::text, ind.categoria_id,ind.iid,ind.nom,ind.colegio_id,ind.cole,ind.puntos,
    dense_rank() OVER (PARTITION BY ind.categoria_id ORDER BY ind.puntos DESC NULLS LAST) FROM ind
 ),
 por_colegio AS (
  SELECT 'mejor_por_colegio'::text,NULL::uuid,ind.iid,ind.nom,ind.colegio_id,ind.cole,ind.puntos,
    dense_rank() OVER (PARTITION BY ind.colegio_id ORDER BY ind.puntos DESC NULLS LAST) FROM ind
 ),
 institucional AS (
  SELECT 'colegios'::text,NULL::uuid,NULL::uuid,c.nombre,c.id,c.nombre,
         SUM(ind.puntos) AS puntos,
         dense_rank() OVER (ORDER BY SUM(ind.puntos) DESC NULLS LAST) AS puesto
  FROM public.torneo_colegios tc JOIN public.colegios c ON c.id=tc.colegio_id
  LEFT JOIN ind ON ind.colegio_id=tc.colegio_id
  WHERE tc.torneo_id=p_torneo
  GROUP BY c.id,c.nombre
 )
 SELECT * FROM general
 UNION ALL SELECT * FROM por_categoria
 UNION ALL SELECT * FROM por_colegio WHERE por_colegio.puesto=1
 UNION ALL SELECT * FROM institucional;
END; $$;


-- ========= EXPOSED API: SECURITY INVOKER WRAPPERS ONLY =========
-- Todas las operaciones privilegiadas viven en private (schema NO expuesto en Supabase).
CREATE FUNCTION public.crear_torneo(p_nombre text,p_deporte uuid,p_anfitrion uuid,p_fecha date) RETURNS uuid
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.crear_torneo(p_nombre,p_deporte,p_anfitrion,p_fecha);
$$;
CREATE FUNCTION public.editar_torneo_basico(p_torneo uuid,p_nombre text,p_fecha date) RETURNS void
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.editar_torneo_basico(p_torneo,p_nombre,p_fecha);
$$;
CREATE FUNCTION public.agregar_colegio_torneo(p_torneo uuid,p_colegio uuid) RETURNS void
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.agregar_colegio_torneo(p_torneo,p_colegio);
$$;
CREATE FUNCTION public.habilitar_categoria_torneo(p_torneo uuid,p_categoria uuid) RETURNS void
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.habilitar_categoria_torneo(p_torneo,p_categoria);
$$;
CREATE FUNCTION public.crear_estacion(p_torneo uuid,p_numero integer,p_nombre text,p_disciplina uuid DEFAULT NULL) RETURNS uuid
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.crear_estacion(p_torneo,p_numero,p_nombre,p_disciplina);
$$;
CREATE FUNCTION public.vincular_usuario_auth(p_usuario uuid,p_auth uuid) RETURNS void
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.vincular_usuario_auth(p_usuario,p_auth);
$$;
CREATE FUNCTION public.habilitar_personal_torneo(p_torneo uuid,p_usuario uuid,p_rol text) RETURNS void
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.habilitar_personal_torneo(p_torneo,p_usuario,p_rol);
$$;
CREATE FUNCTION public.inscribir_participante(p_torneo uuid,p_colegio uuid,p_categoria uuid,p_nombre text,p_dni text,p_fnac date,p_apellido text DEFAULT NULL) RETURNS uuid
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.inscribir_participante(p_torneo,p_colegio,p_categoria,p_nombre,p_dni,p_fnac,p_apellido);
$$;
CREATE FUNCTION public.retirar_participante(p_inscripcion uuid) RETURNS void
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.retirar_participante(p_inscripcion);
$$;
CREATE FUNCTION public.iniciar_torneo(p_torneo uuid) RETURNS void
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.iniciar_torneo(p_torneo);
$$;
CREATE FUNCTION public.registrar_puntaje(p_inscripcion uuid,p_estacion uuid,p_puntaje numeric) RETURNS uuid
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.registrar_puntaje(p_inscripcion,p_estacion,p_puntaje);
$$;
CREATE FUNCTION public.confirmar_estacion(p_asignacion uuid) RETURNS text
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.confirmar_estacion(p_asignacion);
$$;
CREATE FUNCTION public.listar_gimnastas_estacion(p_asignacion uuid) RETURNS TABLE(inscripcion_id uuid,nombre text,apellido text,categoria text,puntaje numeric,estado_evaluacion text)
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT * FROM private.listar_gimnastas_estacion(p_asignacion);
$$;
CREATE FUNCTION public.mis_puntajes() RETURNS TABLE(torneo_id uuid,torneo text,estacion text,puntaje numeric,estado text)
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT * FROM private.mis_puntajes();
$$;
CREATE FUNCTION public.obtener_podios(p_torneo uuid) RETURNS TABLE(tipo text,grupo_id uuid,inscripcion_id uuid,participante text,colegio_id uuid,colegio text,total numeric,puesto bigint)
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT * FROM private.obtener_podios(p_torneo);
$$;

-- ========= PROTECCION: RLS EN TODAS LAS TABLAS OPERATIVAS =========
ALTER TABLE public.deportes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disciplinas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.colegios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles_globales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.torneos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.torneo_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.torneo_categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.torneo_colegios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inscripciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.circuito_posiciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rondas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ronda_asignaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evaluaciones ENABLE ROW LEVEL SECURITY;
-- Todas las tablas heredadas tienen RLS sin politicas: acceso desde cliente web = DENEGADO.
DO $$ DECLARE v record; BEGIN
 FOR v IN SELECT tablename FROM pg_tables WHERE schemaname='legacy' LOOP
  EXECUTE format('ALTER TABLE legacy.%I ENABLE ROW LEVEL SECURITY',v.tablename);
 END LOOP;
END $$;

-- Catálogos visibles solo a usuarios autenticados, nunca al rol anon.
CREATE POLICY catalogo_deportes ON public.deportes FOR SELECT TO authenticated USING (true);
CREATE POLICY catalogo_categorias ON public.categorias FOR SELECT TO authenticated USING (true);
CREATE POLICY catalogo_disciplinas ON public.disciplinas FOR SELECT TO authenticated USING (true);
CREATE POLICY catalogo_colegios ON public.colegios FOR SELECT TO authenticated USING (true);
CREATE POLICY usuarios_visibles ON public.usuarios FOR SELECT TO authenticated
 USING (private.puede_ver_usuario(id));
CREATE POLICY rol_global_propio ON public.roles_globales FOR SELECT TO authenticated
 USING (usuario_id=private.usuario_actual() OR private.es_admin());
CREATE POLICY torneos_visibles ON public.torneos FOR SELECT TO authenticated
 USING (private.puede_ver_torneo(id));
CREATE POLICY torneo_roles_visibles ON public.torneo_roles FOR SELECT TO authenticated
 USING (private.puede_organizar(torneo_id) OR usuario_id=private.usuario_actual());
CREATE POLICY torneo_categorias_visibles ON public.torneo_categorias FOR SELECT TO authenticated
 USING (private.puede_ver_torneo(torneo_id));
CREATE POLICY torneo_colegios_visibles ON public.torneo_colegios FOR SELECT TO authenticated
 USING (private.puede_ver_torneo(torneo_id));
CREATE POLICY inscripciones_visibles ON public.inscripciones FOR SELECT TO authenticated
 USING (private.puede_juzgar(torneo_id) OR usuario_id=private.usuario_actual());
CREATE POLICY estaciones_visibles ON public.estaciones FOR SELECT TO authenticated
 USING (private.puede_ver_torneo(torneo_id));
CREATE POLICY posiciones_visibles ON public.circuito_posiciones FOR SELECT TO authenticated
 USING (private.puede_ver_torneo(torneo_id));
CREATE POLICY rondas_visibles ON public.rondas FOR SELECT TO authenticated
 USING (private.puede_ver_torneo(torneo_id));
CREATE POLICY asignaciones_visibles ON public.ronda_asignaciones FOR SELECT TO authenticated
 USING (private.puede_juzgar(torneo_id));
CREATE POLICY evaluaciones_visibles ON public.evaluaciones FOR SELECT TO authenticated
 USING (private.puede_ver_evaluacion(inscripcion_id));

-- No otorgar GRANT INSERT/UPDATE/DELETE a los clientes web: solo RPCs verificadas.
-- REVOKE se limita a objetos de FieldStats; NO se cambian permisos ajenos al proyecto.
REVOKE ALL ON ALL TABLES IN SCHEMA legacy FROM PUBLIC, anon, authenticated;
REVOKE ALL ON SCHEMA legacy FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.deportes,public.categorias,public.disciplinas,public.colegios,
 public.usuarios,public.roles_globales,public.torneos,public.torneo_roles,
 public.torneo_categorias,public.torneo_colegios,public.inscripciones,
 public.estaciones,public.circuito_posiciones,public.rondas,
 public.ronda_asignaciones,public.evaluaciones FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT SELECT ON public.deportes,public.categorias,public.disciplinas,public.colegios,
 public.usuarios,public.roles_globales,public.torneos,public.torneo_roles,
 public.torneo_categorias,public.torneo_colegios,public.inscripciones,
 public.estaciones,public.circuito_posiciones,public.rondas,
 public.ronda_asignaciones,public.evaluaciones TO authenticated;
-- Sin grants INSERT/UPDATE/DELETE: aun con una policy accidental, no hay DML web directo.

-- Funciones privadas: ejecutables para RLS/funciones, NO publicadas en API Exposed Schemas.
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA private TO authenticated;
-- Funciones publicas: acceso SOLO a personas autenticadas.
REVOKE EXECUTE ON FUNCTION public.crear_torneo(text,uuid,uuid,date) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.editar_torneo_basico(uuid,text,date) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.agregar_colegio_torneo(uuid,uuid) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.habilitar_categoria_torneo(uuid,uuid) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.crear_estacion(uuid,integer,text,uuid) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.vincular_usuario_auth(uuid,uuid) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.habilitar_personal_torneo(uuid,uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.inscribir_participante(uuid,uuid,uuid,text,text,date,text) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.retirar_participante(uuid) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.iniciar_torneo(uuid) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.registrar_puntaje(uuid,uuid,numeric) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.confirmar_estacion(uuid) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.listar_gimnastas_estacion(uuid) FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.mis_puntajes() FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.obtener_podios(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.crear_torneo(text,uuid,uuid,date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.editar_torneo_basico(uuid,text,date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.agregar_colegio_torneo(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.habilitar_categoria_torneo(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.crear_estacion(uuid,integer,text,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.vincular_usuario_auth(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.habilitar_personal_torneo(uuid,uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.inscribir_participante(uuid,uuid,uuid,text,text,date,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.retirar_participante(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iniciar_torneo(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.registrar_puntaje(uuid,uuid,numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirmar_estacion(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.listar_gimnastas_estacion(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mis_puntajes() TO authenticated;
GRANT EXECUTE ON FUNCTION public.obtener_podios(uuid) TO authenticated;

COMMIT;
-- FIN. BOOTSTRAP: crear cuentas de Auth; vincular usuarios y conceder el primer admin
-- desde SQL Editor con postgres (instrucciones en la guia adjunta).
