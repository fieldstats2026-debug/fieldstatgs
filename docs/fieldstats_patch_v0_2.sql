-- FIELDSTATS | PARCHE v0.2 sobre la instalación v0.1 (Supabase.sql)
-- Se ejecuta UNA vez, como postgres, desde el SQL Editor, sobre la base donde ya corrió v0.1.
-- No borra tablas ni datos. Solo agrega columnas/funciones y reemplaza funciones existentes.
--
-- 1. FIX  obtener_podios(): fallaba siempre ("column por_colegio.puesto does not exist").
-- 2. NUEVO podio por estación (pantalla "Podio Gimnastas Estaciones" del mockup).
-- 3. FIX  orden de la lista del juez: por categorías.orden (Menores, Cadetes, Juveniles),
--         no por nombre alfabético de la categoría.
-- 4. NUEVO orden inicial del circuito = orden en que se agregaron los colegios al torneo
--         (antes: orden de UUID, arbitrario).
-- 5. NUEVO el organizador puede corregir la categoría de una inscripción.
-- 6. NUEVO altas de catálogo (deporte, categoría, disciplina, colegio): no había forma
--         de crearlos desde la app.
BEGIN;

-- ========= 3. Orden de categorías =========
ALTER TABLE public.categorias ADD COLUMN IF NOT EXISTS orden int CHECK (orden > 0);

-- ========= 4. Orden de alta de colegios en el torneo =========
ALTER TABLE public.torneo_colegios
  ADD COLUMN IF NOT EXISTS agregado_en timestamptz NOT NULL DEFAULT clock_timestamp();

-- ========= 1 y 2. Podios =========
-- Tipos: 'individual_general', 'individual_categoria' (grupo_id = categoria_id),
--        'mejor_por_colegio', 'colegios', 'estacion' (grupo_id = estacion_id).
-- Sumatoria, nunca promedio. Ausente = NULL. Empates comparten puesto (DENSE_RANK).
CREATE OR REPLACE FUNCTION private.obtener_podios(p_torneo uuid)
 RETURNS TABLE(tipo text,grupo_id uuid,inscripcion_id uuid,participante text,
  colegio_id uuid,colegio text,total numeric,puesto bigint)
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT private.puede_organizar(p_torneo) THEN RAISE EXCEPTION 'Podio reservado al organizador'; END IF;
 RETURN QUERY
 WITH ind AS (
  SELECT i.id AS iid, i.categoria_id AS cat, i.colegio_id AS col,
         (u.nombre || COALESCE(' '||u.apellido,'')) AS nom,
         c.nombre AS cole, SUM(e.puntaje) AS pts
  FROM public.inscripciones i
  JOIN public.usuarios u ON u.id=i.usuario_id
  JOIN public.colegios c ON c.id=i.colegio_id
  LEFT JOIN public.evaluaciones e ON e.inscripcion_id=i.id
  WHERE i.torneo_id=p_torneo
  GROUP BY i.id,i.categoria_id,i.colegio_id,u.nombre,u.apellido,c.nombre
 ),
 general AS (
  SELECT 'individual_general'::text AS t, NULL::uuid AS g, ind.iid, ind.nom, ind.col, ind.cole, ind.pts,
         dense_rank() OVER (ORDER BY ind.pts DESC NULLS LAST) AS pos FROM ind
 ),
 por_categoria AS (
  SELECT 'individual_categoria'::text AS t, ind.cat AS g, ind.iid, ind.nom, ind.col, ind.cole, ind.pts,
         dense_rank() OVER (PARTITION BY ind.cat ORDER BY ind.pts DESC NULLS LAST) AS pos FROM ind
 ),
 por_colegio AS (
  SELECT 'mejor_por_colegio'::text AS t, NULL::uuid AS g, ind.iid, ind.nom, ind.col, ind.cole, ind.pts,
         dense_rank() OVER (PARTITION BY ind.col ORDER BY ind.pts DESC NULLS LAST) AS pos FROM ind
 ),
 institucional AS (
  SELECT 'colegios'::text AS t, NULL::uuid AS g, NULL::uuid AS iid, c.nombre AS nom, c.id AS col,
         c.nombre AS cole, SUM(ind.pts) AS pts,
         dense_rank() OVER (ORDER BY SUM(ind.pts) DESC NULLS LAST) AS pos
  FROM public.torneo_colegios tc JOIN public.colegios c ON c.id=tc.colegio_id
  LEFT JOIN ind ON ind.col=tc.colegio_id
  WHERE tc.torneo_id=p_torneo
  GROUP BY c.id,c.nombre
 ),
 por_estacion AS (
  SELECT 'estacion'::text AS t, s.id AS g, ind.iid, ind.nom, ind.col, ind.cole, e.puntaje AS pts,
         dense_rank() OVER (PARTITION BY s.id ORDER BY e.puntaje DESC NULLS LAST) AS pos
  FROM ind
  CROSS JOIN public.estaciones s
  LEFT JOIN public.evaluaciones e ON e.inscripcion_id=ind.iid AND e.estacion_id=s.id
  WHERE s.torneo_id=p_torneo
 )
 SELECT * FROM general
 UNION ALL SELECT * FROM por_categoria
 UNION ALL SELECT * FROM por_colegio WHERE por_colegio.pos=1
 UNION ALL SELECT * FROM institucional
 UNION ALL SELECT * FROM por_estacion;
END; $$;

-- ========= 3. Lista del juez: categoría por "orden", luego alfabético =========
CREATE OR REPLACE FUNCTION private.listar_gimnastas_estacion(p_asignacion uuid)
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
 ORDER BY c.orden NULLS LAST, c.nombre, u.apellido NULLS LAST, u.nombre;
END; $$;

-- ========= 4. Inicio de circuito: colegios en el orden en que se agregaron =========
CREATE OR REPLACE FUNCTION private.iniciar_torneo(p_torneo uuid)
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
 WITH numeradas AS (
  SELECT id, row_number() OVER (ORDER BY numero)::int AS orden
  FROM public.estaciones WHERE torneo_id=p_torneo
 )
 INSERT INTO public.circuito_posiciones(torneo_id,orden,estacion_id)
 SELECT p_torneo,g.n,numeradas.id FROM generate_series(1,v_n) AS g(n)
 LEFT JOIN numeradas ON numeradas.orden=g.n;
 WITH numerados AS (
  SELECT colegio_id,row_number() OVER(ORDER BY agregado_en, colegio_id)::int AS pos
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

-- ========= 5. Corrección de categoría =========
-- La categoría no afecta puntajes ni sumatorias; solo el podio por categoría y el orden del juez.
CREATE OR REPLACE FUNCTION private.validar_inscripcion() RETURNS trigger
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
  IF (NEW.torneo_id,NEW.colegio_id,NEW.usuario_id)
     IS DISTINCT FROM (OLD.torneo_id,OLD.colegio_id,OLD.usuario_id) THEN
   RAISE EXCEPTION 'La inscripcion historica no permite cambiar torneo, colegio ni usuario';
  END IF;
  IF OLD.estado='retirado' AND NEW.estado='activo' THEN
   RAISE EXCEPTION 'No se reactiva una baja historica en esta version';
  END IF;
 END IF;
 RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION private.cambiar_categoria(p_inscripcion uuid,p_categoria uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_torneo uuid;
BEGIN
 SELECT torneo_id INTO v_torneo FROM public.inscripciones WHERE id=p_inscripcion;
 IF v_torneo IS NULL OR NOT private.puede_organizar(v_torneo) THEN RAISE EXCEPTION 'No autorizado'; END IF;
 IF (SELECT estado FROM public.torneos WHERE id=v_torneo FOR UPDATE)='finalizado' THEN
  RAISE EXCEPTION 'Torneo cerrado'; END IF;
 -- La FK (torneo_id, categoria_id) -> torneo_categorias garantiza que la categoría esté habilitada.
 UPDATE public.inscripciones SET categoria_id=p_categoria WHERE id=p_inscripcion;
END; $$;

-- ========= 6. Altas de catálogo =========
CREATE OR REPLACE FUNCTION private.crear_deporte(p_nombre text)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_id uuid;
BEGIN
 IF NOT private.es_admin() THEN RAISE EXCEPTION 'Solo administrador'; END IF;
 INSERT INTO public.deportes(nombre) VALUES(trim(p_nombre)) RETURNING id INTO v_id;
 RETURN v_id;
END; $$;

CREATE OR REPLACE FUNCTION private.crear_categoria(p_deporte uuid,p_nombre text,p_orden int)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_id uuid;
BEGIN
 IF NOT private.es_admin() THEN RAISE EXCEPTION 'Solo administrador'; END IF;
 INSERT INTO public.categorias(deporte_id,nombre,orden) VALUES(p_deporte,trim(p_nombre),p_orden)
 RETURNING id INTO v_id;
 RETURN v_id;
END; $$;

CREATE OR REPLACE FUNCTION private.crear_disciplina(p_deporte uuid,p_nombre text)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_id uuid;
BEGIN
 IF NOT private.es_admin() THEN RAISE EXCEPTION 'Solo administrador'; END IF;
 INSERT INTO public.disciplinas(deporte_id,nombre) VALUES(p_deporte,trim(p_nombre)) RETURNING id INTO v_id;
 RETURN v_id;
END; $$;

-- Sin torneo: solo admin. Con torneo: el organizador de ese torneo, y queda agregado al torneo.
-- Si ya existe un colegio con ese nombre, se reutiliza.
CREATE OR REPLACE FUNCTION private.crear_colegio(p_nombre text,p_torneo uuid DEFAULT NULL)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_id uuid;
BEGIN
 IF p_nombre IS NULL OR length(trim(p_nombre))=0 THEN RAISE EXCEPTION 'Nombre obligatorio'; END IF;
 IF (p_torneo IS NULL AND NOT private.es_admin())
    OR (p_torneo IS NOT NULL AND NOT private.puede_organizar(p_torneo)) THEN
  RAISE EXCEPTION 'No autorizado'; END IF;
 INSERT INTO public.colegios(nombre) VALUES(trim(p_nombre))
 ON CONFLICT(nombre) DO UPDATE SET nombre=excluded.nombre RETURNING id INTO v_id;
 IF p_torneo IS NOT NULL THEN PERFORM private.agregar_colegio_torneo(p_torneo,v_id); END IF;
 RETURN v_id;
END; $$;

-- ========= Wrappers públicos (mismo patrón que v0.1) =========
CREATE OR REPLACE FUNCTION public.cambiar_categoria(p_inscripcion uuid,p_categoria uuid) RETURNS void
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.cambiar_categoria(p_inscripcion,p_categoria); $$;
CREATE OR REPLACE FUNCTION public.crear_deporte(p_nombre text) RETURNS uuid
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.crear_deporte(p_nombre); $$;
CREATE OR REPLACE FUNCTION public.crear_categoria(p_deporte uuid,p_nombre text,p_orden int) RETURNS uuid
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.crear_categoria(p_deporte,p_nombre,p_orden); $$;
CREATE OR REPLACE FUNCTION public.crear_disciplina(p_deporte uuid,p_nombre text) RETURNS uuid
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.crear_disciplina(p_deporte,p_nombre); $$;
CREATE OR REPLACE FUNCTION public.crear_colegio(p_nombre text,p_torneo uuid DEFAULT NULL) RETURNS uuid
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.crear_colegio(p_nombre,p_torneo); $$;

-- ========= Permisos =========
REVOKE ALL ON FUNCTION private.cambiar_categoria(uuid,uuid), private.crear_deporte(text),
 private.crear_categoria(uuid,text,int), private.crear_disciplina(uuid,text),
 private.crear_colegio(text,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.cambiar_categoria(uuid,uuid), private.crear_deporte(text),
 private.crear_categoria(uuid,text,int), private.crear_disciplina(uuid,text),
 private.crear_colegio(text,uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.cambiar_categoria(uuid,uuid), public.crear_deporte(text),
 public.crear_categoria(uuid,text,int), public.crear_disciplina(uuid,text),
 public.crear_colegio(text,uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cambiar_categoria(uuid,uuid), public.crear_deporte(text),
 public.crear_categoria(uuid,text,int), public.crear_disciplina(uuid,text),
 public.crear_colegio(text,uuid) TO authenticated;

COMMIT;
-- Después del parche, cargar el orden de las categorías existentes, por ejemplo:
-- UPDATE public.categorias SET orden = 1 WHERE nombre = 'Menores';
-- UPDATE public.categorias SET orden = 2 WHERE nombre = 'Cadetes';
-- UPDATE public.categorias SET orden = 3 WHERE nombre = 'Juveniles';
