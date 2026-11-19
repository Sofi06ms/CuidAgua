--
-- PostgreSQL database dump
--

\restrict 3feK3cHsHmKLgiofc9ZHELvgxXOOyUCkomyVNMv0aDasbjh9fad74xhNDSFYR1z

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: asignaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.asignaciones (
    id integer NOT NULL,
    reporte_id integer NOT NULL,
    responsable_id integer NOT NULL,
    fecha_asignacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.asignaciones OWNER TO postgres;

--
-- Name: asignaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.asignaciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.asignaciones_id_seq OWNER TO postgres;

--
-- Name: asignaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.asignaciones_id_seq OWNED BY public.asignaciones.id;


--
-- Name: avisos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.avisos (
    id integer NOT NULL,
    zona_id integer,
    titulo character varying(150) NOT NULL,
    mensaje text NOT NULL,
    fecha_publicacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.avisos OWNER TO postgres;

--
-- Name: avisos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.avisos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.avisos_id_seq OWNER TO postgres;

--
-- Name: avisos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.avisos_id_seq OWNED BY public.avisos.id;


--
-- Name: evidencias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evidencias (
    id integer NOT NULL,
    reporte_id integer NOT NULL,
    url_archivo character varying(255) NOT NULL,
    fecha_carga timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.evidencias OWNER TO postgres;

--
-- Name: evidencias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.evidencias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.evidencias_id_seq OWNER TO postgres;

--
-- Name: evidencias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.evidencias_id_seq OWNED BY public.evidencias.id;


--
-- Name: historial_estados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.historial_estados (
    id integer NOT NULL,
    reporte_id integer NOT NULL,
    estado_anterior character varying(30),
    estado_nuevo character varying(30) NOT NULL,
    observacion text,
    responsable_id integer,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.historial_estados OWNER TO postgres;

--
-- Name: historial_estados_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.historial_estados_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.historial_estados_id_seq OWNER TO postgres;

--
-- Name: historial_estados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.historial_estados_id_seq OWNED BY public.historial_estados.id;


--
-- Name: reportes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reportes (
    id integer NOT NULL,
    folio character varying(20) NOT NULL,
    usuario_id integer NOT NULL,
    zona_id integer,
    categoria character varying(50) NOT NULL,
    descripcion text NOT NULL,
    latitud numeric(10,8),
    longitud numeric(11,8),
    estado character varying(30) DEFAULT 'pendiente'::character varying,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.reportes OWNER TO postgres;

--
-- Name: reportes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reportes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reportes_id_seq OWNER TO postgres;

--
-- Name: reportes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reportes_id_seq OWNED BY public.reportes.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    correo character varying(150) NOT NULL,
    credencial_hash character varying(255) NOT NULL,
    rol character varying(20) NOT NULL,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT usuarios_rol_check CHECK (((rol)::text = ANY ((ARRAY['ciudadano'::character varying, 'personal'::character varying, 'administrador'::character varying])::text[])))
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_seq OWNER TO postgres;

--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: zonas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zonas (
    id integer NOT NULL,
    nombre_zona character varying(100) NOT NULL
);


ALTER TABLE public.zonas OWNER TO postgres;

--
-- Name: zonas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zonas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.zonas_id_seq OWNER TO postgres;

--
-- Name: zonas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zonas_id_seq OWNED BY public.zonas.id;


--
-- Name: asignaciones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignaciones ALTER COLUMN id SET DEFAULT nextval('public.asignaciones_id_seq'::regclass);


--
-- Name: avisos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avisos ALTER COLUMN id SET DEFAULT nextval('public.avisos_id_seq'::regclass);


--
-- Name: evidencias id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evidencias ALTER COLUMN id SET DEFAULT nextval('public.evidencias_id_seq'::regclass);


--
-- Name: historial_estados id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_estados ALTER COLUMN id SET DEFAULT nextval('public.historial_estados_id_seq'::regclass);


--
-- Name: reportes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes ALTER COLUMN id SET DEFAULT nextval('public.reportes_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: zonas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zonas ALTER COLUMN id SET DEFAULT nextval('public.zonas_id_seq'::regclass);


--
-- Data for Name: asignaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.asignaciones (id, reporte_id, responsable_id, fecha_asignacion) FROM stdin;
1	2	2	2026-11-07 05:18:23.838916
\.


--
-- Data for Name: avisos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.avisos (id, zona_id, titulo, mensaje, fecha_publicacion) FROM stdin;
1	1	Corte por mantenimiento en Zona Norte	Mensaje de aviso de prueba sobre el suministro de aguaafectando la zona norte por 24 horas.	2026-11-07 05:18:23.838916
\.


--
-- Data for Name: evidencias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.evidencias (id, reporte_id, url_archivo, fecha_carga) FROM stdin;
1	1	url_de_prueba_foto1.jpg	2026-11-07 05:18:23.838916
2	2	url_de_prueba_foto2.jpg	2026-11-07 05:18:23.838916
\.


--
-- Data for Name: historial_estados; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.historial_estados (id, reporte_id, estado_anterior, estado_nuevo, observacion, responsable_id, fecha) FROM stdin;
1	1	pendiente	en_revision	Observación de prueba	2	2026-11-07 05:18:23.838916
2	3	pendiente	resuelto	Observación de prueba	2	2026-11-07 05:18:23.838916
\.


--
-- Data for Name: reportes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reportes (id, folio, usuario_id, zona_id, categoria, descripcion, latitud, longitud, estado, fecha_creacion, fecha_actualizacion) FROM stdin;
1	FOLIO-001	1	1	fuga	Fuga de agua en la calle principal.	20.17650000	-98.05350000	pendiente	2026-11-07 05:18:23.838916	2026-11-07 05:18:23.838916
2	FOLIO-002	1	2	tuberia_danada	Tubería rota en la colonia.	20.18000000	-98.05000000	en_revision	2026-11-07 05:18:23.838916	2026-11-07 05:18:23.838916
3	FOLIO-003	1	3	falta_suministro	No hay agua en la zona.	20.17000000	-98.06000000	resuelto	2026-11-07 05:18:23.838916	2026-11-07 05:18:23.838916
4	FOLIO-API-01	1	1	fuga	Reporte de prueba desde la app	20.12340000	-98.12340000	en_revision	2026-11-19 12:17:53.373774	2026-11-19 12:23:01.101257
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id, nombre, correo, credencial_hash, rol, fecha_registro) FROM stdin;
1	Usuario Ciudadano	ciudadano@gmail.com	hash_prueba	ciudadano	2026-11-07 05:18:23.838916
2	Personal Atención	personal@gmail.com	hash_prueba	personal	2026-11-07 05:18:23.838916
3	Administrador	admin@gmail.com	hash_prueba	administrador	2026-11-07 05:18:23.838916
\.


--
-- Data for Name: zonas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zonas (id, nombre_zona) FROM stdin;
1	Zona Norte
2	Zona Centro
3	Zona Sur
\.


--
-- Name: asignaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.asignaciones_id_seq', 1, true);


--
-- Name: avisos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.avisos_id_seq', 1, true);


--
-- Name: evidencias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.evidencias_id_seq', 2, true);


--
-- Name: historial_estados_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.historial_estados_id_seq', 2, true);


--
-- Name: reportes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reportes_id_seq', 4, true);


--
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 3, true);


--
-- Name: zonas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zonas_id_seq', 3, true);


--
-- Name: asignaciones asignaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignaciones
    ADD CONSTRAINT asignaciones_pkey PRIMARY KEY (id);


--
-- Name: avisos avisos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avisos
    ADD CONSTRAINT avisos_pkey PRIMARY KEY (id);


--
-- Name: evidencias evidencias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evidencias
    ADD CONSTRAINT evidencias_pkey PRIMARY KEY (id);


--
-- Name: historial_estados historial_estados_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_estados
    ADD CONSTRAINT historial_estados_pkey PRIMARY KEY (id);


--
-- Name: reportes reportes_folio_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_folio_key UNIQUE (folio);


--
-- Name: reportes reportes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: zonas zonas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zonas
    ADD CONSTRAINT zonas_pkey PRIMARY KEY (id);


--
-- Name: idx_asignaciones_reporte; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_asignaciones_reporte ON public.asignaciones USING btree (reporte_id);


--
-- Name: idx_avisos_zona; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_avisos_zona ON public.avisos USING btree (zona_id);


--
-- Name: idx_evidencias_reporte; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evidencias_reporte ON public.evidencias USING btree (reporte_id);


--
-- Name: idx_historial_reporte; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_historial_reporte ON public.historial_estados USING btree (reporte_id);


--
-- Name: idx_reportes_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reportes_usuario ON public.reportes USING btree (usuario_id);


--
-- Name: idx_reportes_zona; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reportes_zona ON public.reportes USING btree (zona_id);


--
-- Name: asignaciones asignaciones_reporte_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignaciones
    ADD CONSTRAINT asignaciones_reporte_id_fkey FOREIGN KEY (reporte_id) REFERENCES public.reportes(id);


--
-- Name: asignaciones asignaciones_responsable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignaciones
    ADD CONSTRAINT asignaciones_responsable_id_fkey FOREIGN KEY (responsable_id) REFERENCES public.usuarios(id);


--
-- Name: avisos avisos_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avisos
    ADD CONSTRAINT avisos_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id) ON DELETE CASCADE;


--
-- Name: evidencias evidencias_reporte_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evidencias
    ADD CONSTRAINT evidencias_reporte_id_fkey FOREIGN KEY (reporte_id) REFERENCES public.reportes(id);


--
-- Name: historial_estados historial_estados_reporte_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_estados
    ADD CONSTRAINT historial_estados_reporte_id_fkey FOREIGN KEY (reporte_id) REFERENCES public.reportes(id);


--
-- Name: historial_estados historial_estados_responsable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_estados
    ADD CONSTRAINT historial_estados_responsable_id_fkey FOREIGN KEY (responsable_id) REFERENCES public.usuarios(id);


--
-- Name: reportes reportes_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: reportes reportes_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 3feK3cHsHmKLgiofc9ZHELvgxXOOyUCkomyVNMv0aDasbjh9fad74xhNDSFYR1z

