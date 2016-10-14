--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: active_user(text); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION active_user(in_user_id text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id TEXT;
BEGIN
  SELECT user_id INTO _id FROM public.users WHERE user_id = in_user_id AND deleted_at IS NOT NULL;
  IF FOUND THEN
    UPDATE public.users SET deleted_at = NULL WHERE user_id = _id;
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END;
$$;


ALTER FUNCTION public.active_user(in_user_id text) OWNER TO genopipe;

--
-- Name: add_user_role(text, bigint); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION add_user_role(in_user_id text, in_role_id bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id TEXT;
BEGIN
  SELECT user_id INTO _id FROM public.user_role WHERE user_id = in_user_id AND role_id = in_role_id;
  IF NOT FOUND THEN
    INSERT INTO public.user_role (user_id, role_id) VALUES (in_user_id, in_role_id);
  END IF;
  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_user_role(in_user_id text, in_role_id bigint) OWNER TO genopipe;

--
-- Name: change_roles(text, json); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION change_roles(in_user_id text, in_roles json) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id TEXT;
  _j JSON;
  _rid BIGINT;
  _rname TEXT;
  _rids BIGINT[];
BEGIN
  --check user
  SELECT user_id INTO _id FROM public.users WHERE user_id = in_user_id;
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  --get role id
  FOR _j IN SELECT json_array_elements(in_roles) LOOP
    _rid := _j->>'role_id';
    IF _rid IS NULL THEN
      _rname := _j->>'role_name';
      IF _rname IS NULL THEN
        CONTINUE;
      ELSE
        SELECT role_id INTO _rid FROM public.roles WHERE name = _rname;
      END IF;
    END IF;
    IF _rid IS NOT NULL THEN
      _rids := array_append(_rids, _rid);
    END IF;
  END LOOP;
  --delete roles
  DELETE FROM public.user_role WHERE user_id = in_user_id;
  --add roles
  FOREACH _rid IN ARRAY _rids LOOP
    INSERT INTO public.user_role (user_id, role_id) VALUES (_id, _rid);
  END LOOP;
  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.change_roles(in_user_id text, in_roles json) OWNER TO genopipe;

--
-- Name: delete_user_role(text, bigint); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION delete_user_role(in_user_id text, in_role_id bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id TEXT;
BEGIN
  SELECT user_id INTO _id FROM public.user_role WHERE user_id = in_user_id AND role_id = in_role_id;
  IF FOUND THEN
    DELETE FROM public.user_role WHERE user_id = in_user_id AND role_id = in_role_id;
  END IF;
  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.delete_user_role(in_user_id text, in_role_id bigint) OWNER TO genopipe;

--
-- Name: get_department_id(text); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION get_department_id(in_department text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  _id TEXT;
BEGIN
  SELECT department_id INTO _id FROM public.departments WHERE name = in_department;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'There is no department % found!', in_department;
  ELSE
    RETURN _id;
  END IF;
END;
$$;


ALTER FUNCTION public.get_department_id(in_department text) OWNER TO genopipe;

--
-- Name: get_role_id(text); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION get_role_id(in_role text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  _id BIGINT;
BEGIN
  SELECT role_id INTO _id FROM public.roles WHERE name = in_role;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'There is no role % found!', in_role;
  ELSE
    RETURN _id;
  END IF;
END;
$$;


ALTER FUNCTION public.get_role_id(in_role text) OWNER TO genopipe;

--
-- Name: get_user_id(text); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION get_user_id(in_user text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  _id TEXT;
BEGIN
  SELECT user_id INTO _id FROM public.users WHERE name = in_user AND deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'There is no user % found!', in_user;
  ELSE
    RETURN _id;
  END IF;
END;
$$;


ALTER FUNCTION public.get_user_id(in_user text) OWNER TO genopipe;

--
-- Name: tp_change_department(); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION tp_change_department() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
BEGIN
  CASE TG_OP
    WHEN 'INSERT' THEN
      NEW.created_at = now();
      NEW.updated_at = now();
      RETURN NEW;
    WHEN 'UPDATE' THEN
      NEW.updated_at = now();
      RETURN NEW;
    ELSE
      RETURN NULL;
  END CASE;
END;
$$;


ALTER FUNCTION public.tp_change_department() OWNER TO genopipe;

--
-- Name: tp_change_role(); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION tp_change_role() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
BEGIN
  CASE TG_OP
    WHEN 'INSERT' THEN
      NEW.created_at = now();
      NEW.updated_at = now();
      RETURN NEW;
    WHEN 'UPDATE' THEN
      NEW.updated_at = now();
      RETURN NEW;
    ELSE
      RETURN NULL;
  END CASE;
END;
$$;


ALTER FUNCTION public.tp_change_role() OWNER TO genopipe;

--
-- Name: tp_change_user(); Type: FUNCTION; Schema: public; Owner: genopipe
--

CREATE FUNCTION tp_change_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  _id TEXT;
  _s BIGINT;
BEGIN
  CASE TG_OP
    WHEN 'INSERT' THEN
      _s := nextval('user_id_seq');
      _id := 'U' || lpad(_s::TEXT, 6, '0');
      NEW.user_id = _id;
      NEW.created_at = now();
      NEW.updated_at = now();
      RETURN NEW;
    WHEN 'UPDATE' THEN
      NEW.user_id = OLD.user_id;
      NEW.updated_at = now();
      INSERT INTO public.user_log (user_id, log_event, descr) VALUES (NEW.user_id, 'update', row_to_json(NEW)::TEXT);
      RETURN NEW;
    WHEN 'DELETE' THEN
      UPDATE public.users SET deleted_at = now() WHERE user_id = OLD.user_id;
      INSERT INTO public.user_log (user_id, log_event) VALUES (OLD.user_id, 'delete');
      RETURN NULL;
  END CASE;
END;
$$;


ALTER FUNCTION public.tp_change_user() OWNER TO genopipe;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: departments; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE departments (
    department_id text NOT NULL,
    name text NOT NULL,
    descr text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE departments OWNER TO genopipe;

--
-- Name: gene_results; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE gene_results (
    id integer NOT NULL,
    accession text,
    barcode text NOT NULL,
    test_product text NOT NULL,
    category text,
    test_item text NOT NULL,
    result text NOT NULL,
    algorithm text,
    risk real,
    gw_id text,
    gene text,
    genotype text,
    ref_alt text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE gene_results OWNER TO genopipe;

--
-- Name: gene_results_id_seq; Type: SEQUENCE; Schema: public; Owner: genopipe
--

CREATE SEQUENCE gene_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE gene_results_id_seq OWNER TO genopipe;

--
-- Name: gene_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: genopipe
--

ALTER SEQUENCE gene_results_id_seq OWNED BY gene_results.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE reports (
    id integer NOT NULL,
    accession text,
    barcode text NOT NULL,
    pdf_path text,
    test_product text,
    plate_id text,
    state text,
    params jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE reports OWNER TO genopipe;

--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: genopipe
--

CREATE SEQUENCE reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE reports_id_seq OWNER TO genopipe;

--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: genopipe
--

ALTER SEQUENCE reports_id_seq OWNED BY reports.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE roles (
    role_id integer NOT NULL,
    name text NOT NULL,
    descr text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE roles OWNER TO genopipe;

--
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: genopipe
--

CREATE SEQUENCE roles_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE roles_role_id_seq OWNER TO genopipe;

--
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: genopipe
--

ALTER SEQUENCE roles_role_id_seq OWNED BY roles.role_id;


--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: genopipe
--

CREATE SEQUENCE user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_id_seq OWNER TO genopipe;

--
-- Name: user_log; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE user_log (
    id integer NOT NULL,
    user_id text NOT NULL,
    from_ip cidr,
    log_level text DEFAULT 'INFO'::text NOT NULL,
    log_event text,
    descr text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE user_log OWNER TO genopipe;

--
-- Name: user_log_id_seq; Type: SEQUENCE; Schema: public; Owner: genopipe
--

CREATE SEQUENCE user_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_log_id_seq OWNER TO genopipe;

--
-- Name: user_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: genopipe
--

ALTER SEQUENCE user_log_id_seq OWNED BY user_log.id;


--
-- Name: user_role; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE user_role (
    user_id text NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE user_role OWNER TO genopipe;

--
-- Name: users; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE users (
    user_id text NOT NULL,
    name text NOT NULL,
    password text,
    label text,
    email text,
    descr text,
    department_id text,
    superuser boolean DEFAULT false NOT NULL,
    remember_token text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE users OWNER TO genopipe;

--
-- Name: xy_conclusions; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE xy_conclusions (
    report_id bigint NOT NULL,
    genetic text,
    environment text,
    conclusion text,
    recommendation text,
    signature text
);


ALTER TABLE xy_conclusions OWNER TO genopipe;

--
-- Name: xy_specimen; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE xy_specimen (
    barcode text,
    doc_id text,
    name text,
    gender text,
    idc text,
    dob date,
    phone_no text,
    company text,
    collect_date date,
    test_code text,
    test_product text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE xy_specimen OWNER TO genopipe;

--
-- Name: view_conclusions; Type: VIEW; Schema: public; Owner: genopipe
--

CREATE VIEW view_conclusions AS
 SELECT r.barcode,
    c.report_id,
    c.genetic,
    c.environment,
    c.conclusion,
    c.recommendation,
    r.test_product,
    s.test_code,
    c.signature
   FROM ((xy_conclusions c
     JOIN reports r ON ((c.report_id = r.id)))
     JOIN xy_specimen s ON (((r.barcode = s.barcode) AND (s.test_product = r.test_product))));


ALTER TABLE view_conclusions OWNER TO genopipe;

--
-- Name: view_user_log; Type: VIEW; Schema: public; Owner: genopipe
--

CREATE VIEW view_user_log AS
 SELECT user_log.user_id,
    users.name,
    users.label,
    users.email,
    departments.department_id,
    departments.name AS department,
    user_log.from_ip,
    user_log.log_level,
    user_log.log_event,
    user_log.descr,
    user_log.created_at
   FROM ((user_log
     JOIN users ON ((user_log.user_id = users.user_id)))
     JOIN departments ON ((departments.department_id = users.department_id)))
  ORDER BY user_log.created_at DESC;


ALTER TABLE view_user_log OWNER TO genopipe;

--
-- Name: view_user_role; Type: VIEW; Schema: public; Owner: genopipe
--

CREATE VIEW view_user_role AS
 SELECT user_role.user_id,
    string_agg(roles.name, ','::text) AS roles
   FROM (user_role
     JOIN roles ON ((user_role.role_id = roles.role_id)))
  GROUP BY user_role.user_id;


ALTER TABLE view_user_role OWNER TO genopipe;

--
-- Name: view_users; Type: VIEW; Schema: public; Owner: genopipe
--

CREATE VIEW view_users AS
 SELECT users.user_id,
    users.name,
    users.label,
    users.password,
    users.email,
    users.descr,
    departments.department_id,
    departments.name AS department,
    departments.descr AS department_descr,
    users.superuser,
    view_user_role.roles,
    users.remember_token,
    users.created_at,
    users.updated_at,
    users.deleted_at
   FROM ((users
     LEFT JOIN departments ON ((users.department_id = departments.department_id)))
     LEFT JOIN view_user_role ON ((users.user_id = view_user_role.user_id)));


ALTER TABLE view_users OWNER TO genopipe;

--
-- Name: xy_tijian; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE xy_tijian (
    barcode text,
    class0 text,
    ksbm text,
    orderitem text,
    itemcode text,
    itemname text,
    result text,
    unit text,
    defvalue text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE xy_tijian OWNER TO genopipe;

--
-- Name: xy_wenjuan; Type: TABLE; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE TABLE xy_wenjuan (
    barcode text,
    lbcode text,
    lbname text,
    qcode text,
    question text,
    answer text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE xy_wenjuan OWNER TO genopipe;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: genopipe
--

ALTER TABLE ONLY gene_results ALTER COLUMN id SET DEFAULT nextval('gene_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: genopipe
--

ALTER TABLE ONLY reports ALTER COLUMN id SET DEFAULT nextval('reports_id_seq'::regclass);


--
-- Name: role_id; Type: DEFAULT; Schema: public; Owner: genopipe
--

ALTER TABLE ONLY roles ALTER COLUMN role_id SET DEFAULT nextval('roles_role_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: genopipe
--

ALTER TABLE ONLY user_log ALTER COLUMN id SET DEFAULT nextval('user_log_id_seq'::regclass);


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY departments (department_id, name, descr, created_at, updated_at) FROM stdin;
XY	XiangYa3	湘雅附三院	2016-08-11 13:43:03.953221+08	2016-08-11 13:43:03.953221+08
\.


--
-- Data for Name: gene_results; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY gene_results (id, accession, barcode, test_product, category, test_item, result, algorithm, risk, gw_id, gene, genotype, ref_alt, created_at) FROM stdin;
15	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:T	C/T	2016-08-26 15:03:11.51828+08
2	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:T	G/T	2016-08-26 15:03:11.453739+08
3	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	G:G	C/G	2016-08-26 15:03:11.460762+08
4	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-08-26 15:03:11.46545+08
5	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:A	A/T	2016-08-26 15:03:11.470396+08
6	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-08-26 15:03:11.474856+08
7	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	A:G	A/G	2016-08-26 15:03:11.479392+08
8	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-08-26 15:03:11.48392+08
9	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-08-26 15:03:11.488523+08
10	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:T	C/T	2016-08-26 15:03:11.493048+08
12	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	A:C	A/C	2016-08-26 15:03:11.502409+08
14	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-08-26 15:03:11.513558+08
18	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-08-26 15:03:11.532661+08
19	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-08-26 15:03:11.537477+08
21	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-08-26 15:03:11.547678+08
22	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-08-26 15:03:11.552363+08
23	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-08-26 15:03:11.556987+08
24	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-08-26 15:03:11.561773+08
25	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-08-26 15:03:11.566433+08
26	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-08-26 15:03:11.571073+08
27	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-08-26 15:03:11.575918+08
28	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-08-26 15:03:11.580766+08
29	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-08-26 15:03:11.585739+08
30	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-08-26 15:03:11.59061+08
31	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	T:T	C/T	2016-08-26 15:03:11.595438+08
32	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:C	A/C	2016-08-26 15:03:11.600754+08
11	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-08-26 15:03:11.497799+08
13	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-08-26 15:03:11.508667+08
33	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-08-26 15:03:11.616695+08
20	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	T:T	C/T	2016-08-26 15:03:11.542815+08
17	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-08-26 15:03:11.527765+08
16	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:11.52301+08
34	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-08-26 15:03:11.637154+08
35	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-08-26 15:03:11.641906+08
38	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-08-26 15:03:11.65693+08
39	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-08-26 15:03:11.661791+08
40	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-08-26 15:03:11.672449+08
41	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-08-26 15:03:11.677165+08
37	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-08-26 15:03:11.652043+08
36	XYC6400204	P167130172	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-08-26 15:03:11.646704+08
42	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-08-26 15:03:11.692659+08
43	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:G	C/G	2016-08-26 15:03:11.697366+08
44	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-08-26 15:03:11.702008+08
45	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-08-26 15:03:11.706672+08
46	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-08-26 15:03:11.711262+08
47	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-08-26 15:03:11.71792+08
48	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-08-26 15:03:11.722612+08
49	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000211	LDLR	G:G	A/G	2016-08-26 15:03:11.72725+08
50	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-08-26 15:03:11.731913+08
52	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-08-26 15:03:11.741232+08
54	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-08-26 15:03:11.75075+08
58	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-08-26 15:03:11.770795+08
59	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000157	GCK	A:G	A/G	2016-08-26 15:03:11.775593+08
61	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:C	C/G	2016-08-26 15:03:11.785049+08
62	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-08-26 15:03:11.789825+08
63	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-08-26 15:03:11.794632+08
64	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-08-26 15:03:11.799455+08
65	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-08-26 15:03:11.804121+08
66	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000162	FADS1	T:T	C/T	2016-08-26 15:03:11.809459+08
67	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-08-26 15:03:11.814261+08
68	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-08-26 15:03:11.819089+08
69	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000165	PROX1	T:T	C/T	2016-08-26 15:03:11.824002+08
70	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-08-26 15:03:11.828879+08
71	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000149	GCKR	C:C	C/T	2016-08-26 15:03:11.833891+08
72	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-08-26 15:03:11.838784+08
51	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-08-26 15:03:11.73658+08
53	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000148	FADS1	T:T	C/T	2016-08-26 15:03:11.745936+08
73	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-08-26 15:03:11.854007+08
60	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000158	GCKR	C:C	C/T	2016-08-26 15:03:11.780389+08
57	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-08-26 15:03:11.765965+08
56	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000205	LPL	C:G	C/G	2016-08-26 15:03:11.761154+08
74	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-08-26 15:03:11.874949+08
75	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-08-26 15:03:11.879761+08
78	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-08-26 15:03:11.894796+08
79	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-08-26 15:03:11.899672+08
55	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000179	LIPC	T:T	C/T	2016-08-26 15:03:11.755897+08
80	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-08-26 15:03:11.910031+08
81	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-08-26 15:03:11.914887+08
77	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-08-26 15:03:11.889491+08
76	XYC6560281	P167230072	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-08-26 15:03:11.88465+08
82	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-08-26 15:03:11.930461+08
83	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-08-26 15:03:11.934856+08
84	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	T:T	C/T	2016-08-26 15:03:11.939399+08
85	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-08-26 15:03:11.943955+08
86	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:G	A/G	2016-08-26 15:03:11.948633+08
87	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-08-26 15:03:11.953254+08
88	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-08-26 15:03:11.957833+08
89	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-08-26 15:03:11.962335+08
90	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-08-26 15:03:11.966864+08
92	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	A:A	A/C	2016-08-26 15:03:11.976079+08
94	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	A:G	A/G	2016-08-26 15:03:11.985613+08
98	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-08-26 15:03:12.004905+08
99	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	A:G	A/G	2016-08-26 15:03:12.009895+08
101	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-08-26 15:03:12.019791+08
102	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-08-26 15:03:12.024463+08
103	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-08-26 15:03:12.029086+08
104	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-08-26 15:03:12.033991+08
105	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	C:C	A/C	2016-08-26 15:03:12.038788+08
106	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-08-26 15:03:12.043587+08
107	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-08-26 15:03:12.048249+08
108	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-08-26 15:03:12.053026+08
109	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	T:T	C/T	2016-08-26 15:03:12.057808+08
110	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-08-26 15:03:12.062618+08
111	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-08-26 15:03:12.06745+08
112	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:C	A/C	2016-08-26 15:03:12.072156+08
91	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-08-26 15:03:11.971487+08
93	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-08-26 15:03:11.980861+08
113	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:A	A/T	2016-08-26 15:03:12.087652+08
100	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-08-26 15:03:12.014973+08
97	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-08-26 15:03:11.999882+08
96	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:11.995043+08
114	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	C:C	C/T	2016-08-26 15:03:12.107851+08
115	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-08-26 15:03:12.112446+08
118	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-08-26 15:03:12.126933+08
119	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-08-26 15:03:12.131753+08
95	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-08-26 15:03:11.990341+08
120	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-08-26 15:03:12.141751+08
121	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	A:T	A/T	2016-08-26 15:03:12.14645+08
117	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.122149+08
116	XYC6400201	P167150159	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-08-26 15:03:12.117043+08
122	XYC6400204	P167130172	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-08-26 15:03:12.161369+08
123	XYC6560281	P167230072	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	平均风险	genotype_lookup	\N	GWV0000148	FADS1	T:T	C/T	2016-08-26 15:03:12.165866+08
124	XYC6400201	P167150159	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-08-26 15:03:12.170233+08
125	XYC6400204	P167130172	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-08-26 15:03:12.175181+08
126	XYC6400204	P167130172	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.180003+08
127	XYC6560281	P167230072	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-08-26 15:03:12.184942+08
128	XYC6560281	P167230072	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.189566+08
129	XYC6400201	P167150159	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-08-26 15:03:12.19399+08
130	XYC6400201	P167150159	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.199072+08
131	XYC6400204	P167130172	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-08-26 15:03:12.203832+08
132	XYC6560281	P167230072	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-08-26 15:03:12.208302+08
133	XYC6400201	P167150159	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-08-26 15:03:12.212817+08
134	XYC6400204	P167130172	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000182	C3	G:G	A/G	2016-08-26 15:03:12.217903+08
135	XYC6400204	P167130172	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000183	ARMS2	G:T	G/T	2016-08-26 15:03:12.223089+08
136	XYC6400204	P167130172	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000184	CFH	A:G	A/G	2016-08-26 15:03:12.227792+08
137	XYC6400204	P167130172	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000185	C2	G:G	G/T	2016-08-26 15:03:12.232429+08
138	XYC6560281	P167230072	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000182	C3	G:G	A/G	2016-08-26 15:03:12.23712+08
139	XYC6560281	P167230072	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000183	ARMS2	G:G	G/T	2016-08-26 15:03:12.241884+08
140	XYC6560281	P167230072	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000184	CFH	A:G	A/G	2016-08-26 15:03:12.246738+08
141	XYC6560281	P167230072	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000185	C2	G:G	G/T	2016-08-26 15:03:12.251782+08
142	XYC6400201	P167150159	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000182	C3	G:G	A/G	2016-08-26 15:03:12.256981+08
143	XYC6400201	P167150159	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000183	ARMS2	G:G	G/T	2016-08-26 15:03:12.261792+08
144	XYC6400201	P167150159	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000184	CFH	G:G	A/G	2016-08-26 15:03:12.266481+08
145	XYC6400201	P167150159	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000185	C2	G:G	G/T	2016-08-26 15:03:12.27112+08
146	XYC6400204	P167130172	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.280000001	GWV0000186	BCAT1	C:C	A/C	2016-08-26 15:03:12.276123+08
147	XYC6400204	P167130172	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.280000001	GWV0000187	FGF5	A:A	A/T	2016-08-26 15:03:12.281862+08
148	XYC6400204	P167130172	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.280000001	GWV0000188	PLEKHA7	C:T	C/T	2016-08-26 15:03:12.286484+08
149	XYC6400204	P167130172	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.280000001	GWV0000189	ATP2B1	G:G	A/G	2016-08-26 15:03:12.29117+08
150	XYC6400204	P167130172	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.280000001	GWV0000190	CSK	A:C	A/C	2016-08-26 15:03:12.295835+08
151	XYC6400204	P167130172	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.280000001	GWV0000191	CAPZA1	A:A	A/C	2016-08-26 15:03:12.300704+08
152	XYC6400204	P167130172	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.280000001	GWV0000192	CYP17A1	C:T	C/T	2016-08-26 15:03:12.305447+08
153	XYC6560281	P167230072	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000186	BCAT1	A:C	A/C	2016-08-26 15:03:12.30998+08
154	XYC6560281	P167230072	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000187	FGF5	A:T	A/T	2016-08-26 15:03:12.31459+08
155	XYC6560281	P167230072	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000188	PLEKHA7	C:C	C/T	2016-08-26 15:03:12.319254+08
156	XYC6560281	P167230072	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000189	ATP2B1	G:G	A/G	2016-08-26 15:03:12.32402+08
157	XYC6560281	P167230072	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000190	CSK	C:C	A/C	2016-08-26 15:03:12.328796+08
158	XYC6560281	P167230072	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000191	CAPZA1	A:A	A/C	2016-08-26 15:03:12.333488+08
159	XYC6560281	P167230072	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000192	CYP17A1	T:T	C/T	2016-08-26 15:03:12.338724+08
160	XYC6400201	P167150159	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.25	GWV0000186	BCAT1	C:C	A/C	2016-08-26 15:03:12.343448+08
161	XYC6400201	P167150159	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.25	GWV0000187	FGF5	A:A	A/T	2016-08-26 15:03:12.347954+08
162	XYC6400201	P167150159	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.25	GWV0000188	PLEKHA7	C:C	C/T	2016-08-26 15:03:12.352496+08
163	XYC6400201	P167150159	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.25	GWV0000189	ATP2B1	A:A	A/G	2016-08-26 15:03:12.357109+08
164	XYC6400201	P167150159	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.25	GWV0000190	CSK	C:C	A/C	2016-08-26 15:03:12.361764+08
165	XYC6400201	P167150159	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.25	GWV0000191	CAPZA1	A:C	A/C	2016-08-26 15:03:12.366379+08
166	XYC6400201	P167150159	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.25	GWV0000192	CYP17A1	C:C	C/T	2016-08-26 15:03:12.370949+08
167	XYC6400204	P167130172	HealthWise	遗传特质	酒精代谢能力	弱	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-08-26 15:03:12.375754+08
168	XYC6560281	P167230072	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-08-26 15:03:12.380352+08
169	XYC6400201	P167150159	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-08-26 15:03:12.384962+08
170	XYC6400204	P167130172	HealthWise	遗传特质	苦味敏感度	正常	genotype_lookup	\N	GWV0000194	TAS2R38	C:C	C/G	2016-08-26 15:03:12.389724+08
171	XYC6400204	P167130172	HealthWise	遗传特质	苦味敏感度	正常	genotype_lookup	\N	GWV0000195	TAS2R38	A:A	A/G	2016-08-26 15:03:12.394387+08
172	XYC6560281	P167230072	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-08-26 15:03:12.399018+08
173	XYC6560281	P167230072	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-08-26 15:03:12.403754+08
174	XYC6400201	P167150159	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-08-26 15:03:12.40863+08
175	XYC6400201	P167150159	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-08-26 15:03:12.413374+08
176	XYC6400204	P167130172	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-08-26 15:03:12.41797+08
177	XYC6560281	P167230072	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-08-26 15:03:12.423248+08
178	XYC6400201	P167150159	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-08-26 15:03:12.427853+08
179	XYC6400204	P167130172	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-08-26 15:03:12.432432+08
180	XYC6560281	P167230072	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-08-26 15:03:12.437029+08
181	XYC6400201	P167150159	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-08-26 15:03:12.441778+08
182	XYC6400204	P167130172	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-08-26 15:03:12.446418+08
183	XYC6560281	P167230072	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-08-26 15:03:12.451084+08
184	XYC6400201	P167150159	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-08-26 15:03:12.455834+08
185	XYC6400204	P167130172	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-08-26 15:03:12.460336+08
186	XYC6560281	P167230072	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-08-26 15:03:12.46482+08
187	XYC6400201	P167150159	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-08-26 15:03:12.469437+08
188	XYC6400204	P167130172	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-08-26 15:03:12.474864+08
189	XYC6560281	P167230072	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-08-26 15:03:12.479721+08
190	XYC6400201	P167150159	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-08-26 15:03:12.484286+08
191	XYC6400204	P167130172	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-08-26 15:03:12.489176+08
192	XYC6400204	P167130172	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-08-26 15:03:12.493951+08
193	XYC6560281	P167230072	HealthWise	营养需求	维生素A水平	未知	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-08-26 15:03:12.498449+08
194	XYC6560281	P167230072	HealthWise	营养需求	维生素A水平	未知	genotype_lookup	\N	GWV0000123	BCMO1	A:T	A/T	2016-08-26 15:03:12.503044+08
195	XYC6400201	P167150159	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-08-26 15:03:12.507985+08
196	XYC6400201	P167150159	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-08-26 15:03:12.512747+08
197	XYC6400204	P167130172	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-08-26 15:03:12.517293+08
198	XYC6560281	P167230072	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-08-26 15:03:12.521886+08
199	XYC6400201	P167150159	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-08-26 15:03:12.526414+08
200	XYC6400204	P167130172	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-08-26 15:03:12.530941+08
201	XYC6560281	P167230072	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:C	C/T	2016-08-26 15:03:12.535569+08
202	XYC6400201	P167150159	HealthWise	营养需求	维生素B$_{6}$水平	正常	genotype_lookup	\N	GWV0000125	NBPF3	T:T	C/T	2016-08-26 15:03:12.540044+08
203	XYC6400204	P167130172	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-08-26 15:03:12.545047+08
204	XYC6400204	P167130172	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-08-26 15:03:12.549758+08
205	XYC6560281	P167230072	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-08-26 15:03:12.554404+08
206	XYC6560281	P167230072	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000126	FUT2	A:A	A/T	2016-08-26 15:03:12.558976+08
207	XYC6400201	P167150159	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-08-26 15:03:12.563661+08
208	XYC6400201	P167150159	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-08-26 15:03:12.568262+08
209	XYC6400204	P167130172	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-08-26 15:03:12.57276+08
210	XYC6560281	P167230072	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-08-26 15:03:12.577269+08
211	XYC6400201	P167150159	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-08-26 15:03:12.581896+08
212	XYC6400204	P167130172	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-08-26 15:03:12.58664+08
213	XYC6560281	P167230072	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-08-26 15:03:12.591162+08
214	XYC6400201	P167150159	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-08-26 15:03:12.59647+08
215	XYC6400204	P167130172	HealthWise	营养需求	叶酸水平	偏低	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-08-26 15:03:12.600999+08
216	XYC6560281	P167230072	HealthWise	营养需求	叶酸水平	偏低	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-08-26 15:03:12.605592+08
217	XYC6400201	P167150159	HealthWise	营养需求	叶酸水平	偏低	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-08-26 15:03:12.610063+08
218	XYC6400204	P167130172	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-08-26 15:03:12.614609+08
219	XYC6560281	P167230072	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-08-26 15:03:12.619161+08
220	XYC6400201	P167150159	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-08-26 15:03:12.623817+08
221	XYC6400204	P167130172	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000051	MC4R	C:T	C/T	2016-08-26 15:03:12.628422+08
222	XYC6400204	P167130172	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000050	FTO	T:T	A/T	2016-08-26 15:03:12.633069+08
223	XYC6560281	P167230072	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000051	MC4R	T:T	C/T	2016-08-26 15:03:12.637977+08
224	XYC6560281	P167230072	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000050	FTO	T:T	A/T	2016-08-26 15:03:12.642778+08
225	XYC6400201	P167150159	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.14999998	GWV0000051	MC4R	T:T	C/T	2016-08-26 15:03:12.647503+08
226	XYC6400201	P167150159	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.14999998	GWV0000050	FTO	A:T	A/T	2016-08-26 15:03:12.6521+08
227	XYC6400204	P167130172	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.656779+08
228	XYC6560281	P167230072	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.661329+08
229	XYC6400201	P167150159	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.665896+08
230	XYC6400204	P167130172	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-08-26 15:03:12.670466+08
231	XYC6560281	P167230072	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-08-26 15:03:12.675059+08
232	XYC6400201	P167150159	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-08-26 15:03:12.680434+08
233	XYC6400204	P167130172	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.685008+08
234	XYC6560281	P167230072	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.689839+08
235	XYC6400201	P167150159	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-08-26 15:03:12.694449+08
236	XYC6400204	P167130172	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:A	A/G	2016-08-26 15:03:12.698935+08
237	XYC6560281	P167230072	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-08-26 15:03:12.70363+08
238	XYC6400201	P167150159	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-08-26 15:03:12.708289+08
239	XYC6400204	P167130172	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-08-26 15:03:12.712847+08
240	XYC6560281	P167230072	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-08-26 15:03:12.717429+08
241	XYC6400201	P167150159	HealthWise	饮食习惯	饮食偏好	正常	genotype_lookup	\N	GWV0000121	ANKK1	G:G	A/G	2016-08-26 15:03:12.722041+08
242	XYC6400204	P167130172	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-08-26 15:03:12.726716+08
243	XYC6560281	P167230072	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-08-26 15:03:12.731375+08
244	XYC6400201	P167150159	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	A:T	A/T	2016-08-26 15:03:12.735927+08
245	XYC6400204	P167130172	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-08-26 15:03:12.740422+08
246	XYC6560281	P167230072	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-08-26 15:03:12.745028+08
247	XYC6400201	P167150159	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-08-26 15:03:12.749721+08
248	XYC6400204	P167130172	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-08-26 15:03:12.754354+08
249	XYC6560281	P167230072	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-08-26 15:03:12.759406+08
250	XYC6400201	P167150159	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-08-26 15:03:12.763948+08
251	XYC6400204	P167130172	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-08-26 15:03:12.769273+08
252	XYC6560281	P167230072	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-08-26 15:03:12.773992+08
253	XYC6400201	P167150159	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-08-26 15:03:12.778644+08
254	XYC6400204	P167130172	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000167	ABCA1	C:T	C/T	2016-08-26 15:03:12.783406+08
255	XYC6400204	P167130172	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000146	ZNF259	C:C	C/G	2016-08-26 15:03:12.788084+08
256	XYC6400204	P167130172	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000204	CETP	A:C	A/C	2016-08-26 15:03:12.792989+08
257	XYC6400204	P167130172	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000148	FADS1	C:T	C/T	2016-08-26 15:03:12.797873+08
258	XYC6400204	P167130172	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000170	GALNT2	G:G	A/G	2016-08-26 15:03:12.802718+08
259	XYC6400204	P167130172	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000179	LIPC	C:T	C/T	2016-08-26 15:03:12.807663+08
260	XYC6400204	P167130172	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:12.812557+08
261	XYC6400204	P167130172	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000206	MLXIPL	C:C	C/T	2016-08-26 15:03:12.81826+08
262	XYC6560281	P167230072	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000167	ABCA1	C:C	C/T	2016-08-26 15:03:12.823021+08
263	XYC6560281	P167230072	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000146	ZNF259	C:C	C/G	2016-08-26 15:03:12.827736+08
264	XYC6560281	P167230072	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000204	CETP	C:C	A/C	2016-08-26 15:03:12.832553+08
265	XYC6560281	P167230072	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000148	FADS1	T:T	C/T	2016-08-26 15:03:12.837705+08
266	XYC6560281	P167230072	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000170	GALNT2	G:G	A/G	2016-08-26 15:03:12.842643+08
267	XYC6560281	P167230072	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000179	LIPC	T:T	C/T	2016-08-26 15:03:12.847715+08
268	XYC6560281	P167230072	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000205	LPL	C:G	C/G	2016-08-26 15:03:12.85256+08
269	XYC6560281	P167230072	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000206	MLXIPL	C:C	C/T	2016-08-26 15:03:12.857656+08
270	XYC6400201	P167150159	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	27.8799992	GWV0000167	ABCA1	C:C	C/T	2016-08-26 15:03:12.862396+08
271	XYC6400201	P167150159	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	27.8799992	GWV0000146	ZNF259	C:C	C/G	2016-08-26 15:03:12.867098+08
272	XYC6400201	P167150159	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	27.8799992	GWV0000204	CETP	A:A	A/C	2016-08-26 15:03:12.872241+08
273	XYC6400201	P167150159	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	27.8799992	GWV0000148	FADS1	C:T	C/T	2016-08-26 15:03:12.87718+08
274	XYC6400201	P167150159	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	27.8799992	GWV0000170	GALNT2	A:G	A/G	2016-08-26 15:03:12.882228+08
275	XYC6400201	P167150159	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	27.8799992	GWV0000179	LIPC	C:C	C/T	2016-08-26 15:03:12.887496+08
276	XYC6400201	P167150159	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	27.8799992	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:12.892473+08
277	XYC6400201	P167150159	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	27.8799992	GWV0000206	MLXIPL	C:C	C/T	2016-08-26 15:03:12.897305+08
278	XYC6400204	P167130172	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	35.9900017	GWV0000139	CELSR2	G:T	G/T	2016-08-26 15:03:12.902009+08
279	XYC6400204	P167130172	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	35.9900017	GWV0000136	Intergenic	G:G	C/G	2016-08-26 15:03:12.906842+08
280	XYC6400204	P167130172	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	35.9900017	GWV0000137	MAFB	C:T	C/T	2016-08-26 15:03:12.911914+08
281	XYC6400204	P167130172	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	35.9900017	GWV0000207	HMGCR	A:A	A/T	2016-08-26 15:03:12.916936+08
282	XYC6400204	P167130172	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	35.9900017	GWV0000208	APOC1	A:A	A/G	2016-08-26 15:03:12.922007+08
283	XYC6400204	P167130172	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	35.9900017	GWV0000209	ABO	A:G	A/G	2016-08-26 15:03:12.927062+08
284	XYC6400204	P167130172	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	35.9900017	GWV0000210	TOMM40	C:C	C/T	2016-08-26 15:03:12.932058+08
285	XYC6400204	P167130172	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	35.9900017	GWV0000211	LDLR	A:A	A/G	2016-08-26 15:03:12.937024+08
286	XYC6560281	P167230072	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000139	CELSR2	G:G	G/T	2016-08-26 15:03:12.941795+08
287	XYC6560281	P167230072	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000136	Intergenic	C:G	C/G	2016-08-26 15:03:12.94648+08
288	XYC6560281	P167230072	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000137	MAFB	C:T	C/T	2016-08-26 15:03:12.951358+08
289	XYC6560281	P167230072	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000207	HMGCR	A:T	A/T	2016-08-26 15:03:12.956248+08
290	XYC6560281	P167230072	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000208	APOC1	A:A	A/G	2016-08-26 15:03:12.961109+08
291	XYC6560281	P167230072	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000209	ABO	G:G	A/G	2016-08-26 15:03:12.966085+08
292	XYC6560281	P167230072	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000210	TOMM40	C:T	C/T	2016-08-26 15:03:12.971001+08
293	XYC6560281	P167230072	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000211	LDLR	G:G	A/G	2016-08-26 15:03:12.976237+08
294	XYC6400201	P167150159	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	40.9500008	GWV0000139	CELSR2	G:G	G/T	2016-08-26 15:03:12.980931+08
295	XYC6400201	P167150159	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	40.9500008	GWV0000136	Intergenic	C:C	C/G	2016-08-26 15:03:12.985711+08
296	XYC6400201	P167150159	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	40.9500008	GWV0000137	MAFB	T:T	C/T	2016-08-26 15:03:12.99062+08
297	XYC6400201	P167150159	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	40.9500008	GWV0000207	HMGCR	A:T	A/T	2016-08-26 15:03:12.99547+08
298	XYC6400201	P167150159	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	40.9500008	GWV0000208	APOC1	A:G	A/G	2016-08-26 15:03:13.000476+08
299	XYC6400201	P167150159	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	40.9500008	GWV0000209	ABO	G:G	A/G	2016-08-26 15:03:13.005851+08
300	XYC6400201	P167150159	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	40.9500008	GWV0000210	TOMM40	C:T	C/T	2016-08-26 15:03:13.011029+08
301	XYC6400201	P167150159	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	40.9500008	GWV0000211	LDLR	A:A	A/G	2016-08-26 15:03:13.016023+08
302	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000156	G6PC2	C:C	C/T	2016-08-26 15:03:13.02084+08
303	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000157	GCK	G:G	A/G	2016-08-26 15:03:13.025537+08
304	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000158	GCKR	T:T	C/T	2016-08-26 15:03:13.030077+08
305	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000061	MTNR1B	C:G	C/G	2016-08-26 15:03:13.034731+08
306	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000057	TCF7L2	C:C	C/T	2016-08-26 15:03:13.039479+08
307	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000159	ADRA2A	G:G	G/T	2016-08-26 15:03:13.044138+08
308	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000160	ADCY5	A:A	A/G	2016-08-26 15:03:13.048871+08
309	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000161	CRY2	A:A	A/C	2016-08-26 15:03:13.053754+08
310	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000162	FADS1	C:T	C/T	2016-08-26 15:03:13.058558+08
311	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000163	GLIS3	A:C	A/C	2016-08-26 15:03:13.063336+08
312	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000164	MADD	A:A	A/T	2016-08-26 15:03:13.06807+08
313	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000165	PROX1	C:T	C/T	2016-08-26 15:03:13.073123+08
314	XYC6400204	P167130172	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000166	SLC2A2	T:T	A/T	2016-08-26 15:03:13.077944+08
315	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000156	G6PC2	C:C	C/T	2016-08-26 15:03:13.08307+08
316	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000157	GCK	A:G	A/G	2016-08-26 15:03:13.087854+08
317	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000158	GCKR	C:C	C/T	2016-08-26 15:03:13.092491+08
318	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000061	MTNR1B	C:C	C/G	2016-08-26 15:03:13.097097+08
319	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000057	TCF7L2	C:C	C/T	2016-08-26 15:03:13.101852+08
320	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000159	ADRA2A	G:G	G/T	2016-08-26 15:03:13.106784+08
321	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000160	ADCY5	A:A	A/G	2016-08-26 15:03:13.111715+08
322	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000161	CRY2	A:A	A/C	2016-08-26 15:03:13.116524+08
323	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000162	FADS1	T:T	C/T	2016-08-26 15:03:13.121264+08
324	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000163	GLIS3	A:C	A/C	2016-08-26 15:03:13.125984+08
325	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000164	MADD	A:A	A/T	2016-08-26 15:03:13.130903+08
326	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000165	PROX1	T:T	C/T	2016-08-26 15:03:13.135856+08
327	XYC6560281	P167230072	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.0400009	GWV0000166	SLC2A2	T:T	A/T	2016-08-26 15:03:13.140607+08
328	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000156	G6PC2	C:C	C/T	2016-08-26 15:03:13.145271+08
329	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000157	GCK	A:G	A/G	2016-08-26 15:03:13.149994+08
330	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000158	GCKR	C:T	C/T	2016-08-26 15:03:13.154651+08
331	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000061	MTNR1B	C:G	C/G	2016-08-26 15:03:13.159365+08
332	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000057	TCF7L2	C:C	C/T	2016-08-26 15:03:13.164846+08
333	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000159	ADRA2A	G:G	G/T	2016-08-26 15:03:13.169579+08
334	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000160	ADCY5	A:A	A/G	2016-08-26 15:03:13.174391+08
335	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000161	CRY2	C:C	A/C	2016-08-26 15:03:13.179091+08
336	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000162	FADS1	C:T	C/T	2016-08-26 15:03:13.183824+08
337	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000163	GLIS3	A:C	A/C	2016-08-26 15:03:13.188658+08
338	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000164	MADD	A:A	A/T	2016-08-26 15:03:13.193457+08
339	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000165	PROX1	T:T	C/T	2016-08-26 15:03:13.198112+08
340	XYC6400201	P167150159	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.9399986	GWV0000166	SLC2A2	T:T	A/T	2016-08-26 15:03:13.202847+08
341	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000149	GCKR	T:T	C/T	2016-08-26 15:03:13.207568+08
342	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000145	ANGPTL3	A:C	A/C	2016-08-26 15:03:13.212373+08
343	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000146	ZNF259	C:C	C/G	2016-08-26 15:03:13.217151+08
344	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000148	FADS1	C:T	C/T	2016-08-26 15:03:13.222065+08
345	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000154	TRIB1	A:T	A/T	2016-08-26 15:03:13.226933+08
346	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000158	GCKR	T:T	C/T	2016-08-26 15:03:13.231833+08
347	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000206	MLXIPL	C:C	C/T	2016-08-26 15:03:13.236808+08
348	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:13.241786+08
349	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000212	APOE	T:T	C/T	2016-08-26 15:03:13.247181+08
350	XYC6400204	P167130172	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	52.6199989	GWV0000213	APOA5	T:T	C/T	2016-08-26 15:03:13.252078+08
351	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000149	GCKR	C:C	C/T	2016-08-26 15:03:13.257251+08
352	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000145	ANGPTL3	A:A	A/C	2016-08-26 15:03:13.26205+08
353	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000146	ZNF259	C:C	C/G	2016-08-26 15:03:13.267533+08
354	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000148	FADS1	T:T	C/T	2016-08-26 15:03:13.272603+08
355	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000154	TRIB1	A:T	A/T	2016-08-26 15:03:13.277482+08
356	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000158	GCKR	C:C	C/T	2016-08-26 15:03:13.28223+08
357	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000206	MLXIPL	C:C	C/T	2016-08-26 15:03:13.28702+08
358	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000205	LPL	C:G	C/G	2016-08-26 15:03:13.29237+08
359	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000212	APOE	C:T	C/T	2016-08-26 15:03:13.297373+08
360	XYC6560281	P167230072	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000213	APOA5	T:T	C/T	2016-08-26 15:03:13.302249+08
361	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000149	GCKR	C:T	C/T	2016-08-26 15:03:13.307046+08
362	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000145	ANGPTL3	A:C	A/C	2016-08-26 15:03:13.312023+08
363	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000146	ZNF259	C:C	C/G	2016-08-26 15:03:13.316968+08
364	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000148	FADS1	C:T	C/T	2016-08-26 15:03:13.321911+08
365	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000154	TRIB1	A:A	A/T	2016-08-26 15:03:13.326783+08
366	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000158	GCKR	C:T	C/T	2016-08-26 15:03:13.332234+08
367	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000206	MLXIPL	C:C	C/T	2016-08-26 15:03:13.337079+08
368	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:13.342036+08
369	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000212	APOE	C:C	C/T	2016-08-26 15:03:13.346993+08
370	XYC6400201	P167150159	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.6399994	GWV0000213	APOA5	T:T	C/T	2016-08-26 15:03:13.3519+08
371	XYC6400204	P167130172	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-08-26 15:03:13.356722+08
372	XYC6560281	P167230072	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-08-26 15:03:13.361373+08
373	XYC6400201	P167150159	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-08-26 15:03:13.366071+08
374	XYC6400204	P167130172	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:C	C/T	2016-08-26 15:03:13.370738+08
375	XYC6560281	P167230072	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-08-26 15:03:13.375435+08
376	XYC6400201	P167150159	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:C	C/T	2016-08-26 15:03:13.379988+08
377	XYC6400204	P167130172	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-08-26 15:03:13.384774+08
378	XYC6400204	P167130172	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-08-26 15:03:13.389611+08
379	XYC6400204	P167130172	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:13.394494+08
380	XYC6560281	P167230072	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	T:T	C/T	2016-08-26 15:03:13.399272+08
381	XYC6560281	P167230072	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:C	C/T	2016-08-26 15:03:13.404238+08
382	XYC6560281	P167230072	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-08-26 15:03:13.409044+08
383	XYC6400201	P167150159	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-08-26 15:03:13.413892+08
384	XYC6400201	P167150159	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-08-26 15:03:13.419056+08
385	XYC6400201	P167150159	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:13.423895+08
386	XYC6400204	P167130172	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:13.428736+08
387	XYC6560281	P167230072	HealthWise	运动效果	运动减脂效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-08-26 15:03:13.43378+08
388	XYC6400201	P167150159	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-08-26 15:03:13.438461+08
389	XYC6400204	P167130172	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-08-26 15:03:13.443083+08
390	XYC6560281	P167230072	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:C	C/T	2016-08-26 15:03:13.447744+08
391	XYC6400201	P167150159	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-08-26 15:03:13.452418+08
392	XYC6400204	P167130172	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-08-26 15:03:13.457017+08
393	XYC6560281	P167230072	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-08-26 15:03:13.462055+08
394	XYC6400201	P167150159	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-08-26 15:03:13.466777+08
395	XYC6400204	P167130172	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-08-26 15:03:13.471462+08
396	XYC6560281	P167230072	HealthWise	运动效果	运动提升胰岛素敏感性效果	一般	genotype_lookup	\N	GWV0000179	LIPC	T:T	C/T	2016-08-26 15:03:13.476261+08
397	XYC6400201	P167150159	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-08-26 15:03:13.480879+08
398	XYC6400204	P167130172	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-08-26 15:03:13.485596+08
399	XYC6560281	P167230072	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:G	A/G	2016-08-26 15:03:13.490236+08
400	XYC6400201	P167150159	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:G	A/G	2016-08-26 15:03:13.494715+08
401	XYC6400204	P167130172	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:C	C/G	2016-08-26 15:03:13.499364+08
402	XYC6560281	P167230072	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:G	C/G	2016-08-26 15:03:13.504045+08
403	XYC6400201	P167150159	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-08-26 15:03:13.509265+08
404	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:50.318907+08
405	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:50.331786+08
406	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:50.336425+08
407	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	T:T	A/T	2016-09-02 14:47:50.340948+08
408	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:50.345414+08
409	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:50.351146+08
410	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:50.355757+08
411	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:50.360317+08
412	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:50.364879+08
414	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:50.375063+08
416	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	A:G	A/G	2016-09-02 14:47:50.384422+08
420	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:50.402763+08
421	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:50.40744+08
423	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:50.416634+08
424	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:50.421232+08
425	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:50.425875+08
426	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:50.430603+08
427	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:50.435239+08
428	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:50.440498+08
429	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	C:C	A/C	2016-09-02 14:47:50.445261+08
430	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:50.449917+08
431	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:50.454607+08
432	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:50.459739+08
433	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:50.464457+08
434	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:50.469125+08
413	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:50.369504+08
415	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:50.379734+08
435	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:50.48441+08
422	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:50.412068+08
419	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:50.398049+08
418	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:50.393568+08
436	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:50.504574+08
437	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:50.509237+08
440	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:50.523136+08
417	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:50.389051+08
439	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:50.51852+08
438	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:50.513817+08
441	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	G:G	C/G	2016-09-02 14:47:50.527829+08
442	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-02 14:47:50.537968+08
443	XYC6560239	P168230028	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:50.542605+08
444	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:50.557713+08
445	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:50.562033+08
446	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:50.566468+08
447	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000207	HMGCR	T:T	A/T	2016-09-02 14:47:50.570921+08
448	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:50.575613+08
449	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:50.579956+08
450	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:50.584955+08
451	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:50.589405+08
452	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:T	C/T	2016-09-02 14:47:50.593955+08
454	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:50.603421+08
456	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:50.612821+08
460	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:50.632116+08
461	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000157	GCK	A:G	A/G	2016-09-02 14:47:50.636882+08
463	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:50.646514+08
464	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:50.650975+08
465	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:50.655634+08
466	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:50.661093+08
467	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000161	CRY2	C:C	A/C	2016-09-02 14:47:50.66626+08
468	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:50.671082+08
469	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000163	GLIS3	C:C	A/C	2016-09-02 14:47:50.675877+08
470	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:50.680641+08
471	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:50.685377+08
472	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:50.690604+08
473	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:50.695441+08
474	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:50.700264+08
453	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:50.598713+08
455	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:50.608068+08
475	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:A	A/T	2016-09-02 14:47:50.715156+08
462	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:50.641648+08
459	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:50.627421+08
458	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:50.622773+08
476	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:50.734958+08
477	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:50.739473+08
480	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:50.753598+08
481	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-02 14:47:50.758386+08
457	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:50.618077+08
482	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-02 14:47:50.768906+08
483	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:50.773547+08
479	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:50.748709+08
478	XYC6560248	P167270186	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:50.744058+08
484	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:50.788617+08
485	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:50.792977+08
486	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:50.797397+08
487	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000207	HMGCR	T:T	A/T	2016-09-02 14:47:50.802332+08
488	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:50.807008+08
489	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:50.811453+08
490	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:50.815868+08
491	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000211	LDLR	A:G	A/G	2016-09-02 14:47:50.820384+08
492	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:50.824877+08
494	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:50.834059+08
496	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:50.84326+08
500	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:50.862437+08
501	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:50.86706+08
503	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:50.876403+08
504	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:50.881002+08
505	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:50.885875+08
506	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:50.890515+08
507	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000161	CRY2	C:C	A/C	2016-09-02 14:47:50.895137+08
508	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:50.899862+08
509	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:50.904573+08
510	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:50.909366+08
511	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000165	PROX1	T:T	C/T	2016-09-02 14:47:50.914072+08
512	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:50.918744+08
513	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000149	GCKR	T:T	C/T	2016-09-02 14:47:50.923457+08
514	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:C	A/C	2016-09-02 14:47:50.928123+08
493	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:50.829435+08
495	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:50.838655+08
515	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000154	TRIB1	T:T	A/T	2016-09-02 14:47:50.943674+08
502	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000158	GCKR	T:T	C/T	2016-09-02 14:47:50.871769+08
499	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:50.857615+08
498	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:50.85286+08
516	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-09-02 14:47:50.964494+08
517	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:50.969061+08
520	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:50.98301+08
521	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-09-02 14:47:50.987752+08
497	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:50.847911+08
522	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-02 14:47:50.997568+08
523	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:51.00224+08
519	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:50.978242+08
518	XYC6560244	P168020117	HealthWise	饮食类型	匹配饮食	地中海饮食	diet_recommendation	\N	GWV0000059	PPARG	C:G	C/G	2016-09-02 14:47:50.973626+08
524	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:51.016919+08
525	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:51.021288+08
526	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:C	C/T	2016-09-02 14:47:51.025781+08
527	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:51.030244+08
528	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:51.034726+08
529	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	A:G	A/G	2016-09-02 14:47:51.039171+08
530	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:51.04356+08
531	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:51.048021+08
532	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:T	C/T	2016-09-02 14:47:51.052492+08
534	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:51.061783+08
536	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:51.071019+08
540	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:51.09007+08
541	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:51.094885+08
543	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:C	C/G	2016-09-02 14:47:51.104117+08
544	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:51.108669+08
545	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:51.113307+08
546	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:51.117917+08
547	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:51.122555+08
548	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:51.12716+08
549	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:51.131926+08
550	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:51.136634+08
551	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:C	C/T	2016-09-02 14:47:51.141275+08
552	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:51.145875+08
553	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:51.150691+08
554	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:51.155436+08
533	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	G:G	C/G	2016-09-02 14:47:51.057218+08
535	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:51.066488+08
555	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:51.170621+08
542	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:51.099623+08
539	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:51.084839+08
538	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:51.080252+08
556	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:51.19138+08
557	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	C:C	C/T	2016-09-02 14:47:51.195991+08
560	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:51.210095+08
561	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-02 14:47:51.214902+08
537	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:51.075651+08
562	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-02 14:47:51.224805+08
563	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:51.22951+08
559	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:51.20539+08
558	XYC6640293	P168250037	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:51.200653+08
564	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:T	G/T	2016-09-02 14:47:51.244259+08
565	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:51.249028+08
566	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000137	MAFB	T:T	C/T	2016-09-02 14:47:51.253612+08
567	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:A	A/T	2016-09-02 14:47:51.258169+08
568	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000208	APOC1	A:G	A/G	2016-09-02 14:47:51.262788+08
569	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:51.267254+08
570	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:51.271802+08
571	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:51.276381+08
572	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:51.28096+08
574	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:51.290747+08
576	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:51.30007+08
580	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:51.318639+08
581	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000157	GCK	A:G	A/G	2016-09-02 14:47:51.323426+08
583	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000061	MTNR1B	G:G	C/G	2016-09-02 14:47:51.333253+08
584	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:51.337915+08
585	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:51.342527+08
586	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:51.347126+08
587	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000161	CRY2	A:C	A/C	2016-09-02 14:47:51.35196+08
588	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:51.35666+08
589	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:A	A/C	2016-09-02 14:47:51.361386+08
590	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:51.365984+08
591	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000165	PROX1	C:C	C/T	2016-09-02 14:47:51.370734+08
592	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:51.375527+08
593	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000149	GCKR	C:C	C/T	2016-09-02 14:47:51.380139+08
594	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:51.384943+08
573	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:51.285775+08
575	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:51.295453+08
595	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:51.399977+08
582	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000158	GCKR	C:C	C/T	2016-09-02 14:47:51.32807+08
579	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:51.314033+08
578	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:51.3095+08
596	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000212	APOE	C:C	C/T	2016-09-02 14:47:51.42008+08
597	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:51.424869+08
600	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:51.439938+08
601	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-02 14:47:51.444805+08
577	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:51.304855+08
602	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-02 14:47:51.455892+08
603	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:51.460657+08
599	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:51.434442+08
598	XYC6560250	P167270187	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:51.429622+08
604	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:51.475656+08
605	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:51.479942+08
606	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:C	C/T	2016-09-02 14:47:51.484444+08
607	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:51.488937+08
608	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:51.49344+08
609	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	A:A	A/G	2016-09-02 14:47:51.497881+08
610	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:51.502428+08
611	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:51.506988+08
612	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:T	C/T	2016-09-02 14:47:51.511571+08
614	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:51.520762+08
616	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:51.530028+08
620	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:T	C/T	2016-09-02 14:47:51.549008+08
621	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	A:G	A/G	2016-09-02 14:47:51.55396+08
623	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:51.56359+08
624	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:51.56825+08
625	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:51.572973+08
626	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:51.577696+08
627	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	C:C	A/C	2016-09-02 14:47:51.582425+08
628	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:51.587092+08
629	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	C:C	A/C	2016-09-02 14:47:51.591865+08
630	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:51.59666+08
631	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:51.601354+08
632	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:51.605992+08
633	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:51.610748+08
634	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:51.615478+08
613	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:51.516065+08
615	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:51.525445+08
635	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:51.630717+08
622	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:51.558823+08
619	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:51.544157+08
618	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:51.539523+08
636	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-09-02 14:47:51.650793+08
637	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	C:T	C/T	2016-09-02 14:47:51.655519+08
640	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:51.669783+08
641	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-09-02 14:47:51.674485+08
617	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:51.534848+08
642	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-02 14:47:51.684432+08
643	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:51.689538+08
639	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:51.665073+08
638	XYC6560246	P168020116	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:51.660266+08
644	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:51.704394+08
645	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:G	C/G	2016-09-02 14:47:51.708776+08
646	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:51.713354+08
647	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000207	HMGCR	T:T	A/T	2016-09-02 14:47:51.71792+08
648	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:51.722359+08
649	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:51.726838+08
650	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:51.731385+08
651	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:51.735872+08
652	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:51.740771+08
654	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000204	CETP	A:C	A/C	2016-09-02 14:47:51.750049+08
656	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000170	GALNT2	A:G	A/G	2016-09-02 14:47:51.759515+08
660	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:51.77825+08
661	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:51.782852+08
663	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:51.79218+08
664	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:51.797058+08
665	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:51.801781+08
666	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:51.806461+08
667	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:51.811138+08
668	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:51.815854+08
669	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:51.820607+08
670	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:51.826027+08
671	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:51.830779+08
672	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:51.835491+08
673	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000149	GCKR	T:T	C/T	2016-09-02 14:47:51.840101+08
674	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:51.844987+08
653	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:51.745452+08
655	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:51.754882+08
675	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000154	TRIB1	T:T	A/T	2016-09-02 14:47:51.860024+08
662	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000158	GCKR	T:T	C/T	2016-09-02 14:47:51.787501+08
659	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:51.773632+08
658	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:51.769037+08
676	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:51.880028+08
677	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:51.88449+08
680	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:51.898959+08
681	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-02 14:47:51.903612+08
657	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:51.76415+08
682	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-02 14:47:51.913578+08
683	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:51.918278+08
679	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:51.894224+08
678	XYC6560249	P167270185	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000059	PPARG	C:G	C/G	2016-09-02 14:47:51.889488+08
684	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:51.933013+08
685	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:G	C/G	2016-09-02 14:47:51.93791+08
686	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000137	MAFB	T:T	C/T	2016-09-02 14:47:51.942488+08
687	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:51.946948+08
688	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:51.951428+08
689	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000209	ABO	A:G	A/G	2016-09-02 14:47:51.957251+08
690	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:51.961771+08
691	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000211	LDLR	G:G	A/G	2016-09-02 14:47:51.966407+08
692	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:51.970933+08
694	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:51.979986+08
696	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:51.989033+08
700	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:52.007399+08
701	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:52.01205+08
703	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000061	MTNR1B	G:G	C/G	2016-09-02 14:47:52.021412+08
704	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:52.026572+08
705	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:52.031046+08
706	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:G	A/G	2016-09-02 14:47:52.035756+08
707	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:52.040453+08
708	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:52.04602+08
709	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000163	GLIS3	C:C	A/C	2016-09-02 14:47:52.050716+08
710	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:52.055434+08
711	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000165	PROX1	T:T	C/T	2016-09-02 14:47:52.060132+08
712	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:52.064894+08
713	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000149	GCKR	T:T	C/T	2016-09-02 14:47:52.070046+08
714	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:52.074773+08
693	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:51.975474+08
695	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:51.984609+08
715	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:A	A/T	2016-09-02 14:47:52.08971+08
702	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000158	GCKR	T:T	C/T	2016-09-02 14:47:52.016847+08
699	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:T	C/T	2016-09-02 14:47:52.002768+08
698	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:51.998237+08
716	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:52.10983+08
717	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000213	APOA5	C:C	C/T	2016-09-02 14:47:52.114473+08
720	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:52.128431+08
721	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-09-02 14:47:52.1331+08
697	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:51.993586+08
722	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000180	APOA2	A:G	A/G	2016-09-02 14:47:52.14298+08
723	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:52.147879+08
719	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.123676+08
718	XYC6560236	P168170329	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.11905+08
724	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:52.162726+08
725	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:G	C/G	2016-09-02 14:47:52.167495+08
726	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:52.17206+08
727	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:52.176418+08
728	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:G	A/G	2016-09-02 14:47:52.180915+08
729	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	A:G	A/G	2016-09-02 14:47:52.185362+08
730	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:52.190936+08
731	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:G	A/G	2016-09-02 14:47:52.19599+08
732	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:52.200598+08
734	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:52.209845+08
736	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:52.219244+08
740	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:52.237865+08
741	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	A:G	A/G	2016-09-02 14:47:52.242603+08
743	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:C	C/G	2016-09-02 14:47:52.252055+08
744	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:52.256734+08
745	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:52.261436+08
746	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:52.266048+08
747	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:52.270808+08
748	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:52.275693+08
749	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:52.280491+08
750	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:52.285054+08
751	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:52.289762+08
752	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:52.294468+08
753	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:52.299077+08
754	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:52.303703+08
733	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:52.205253+08
735	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:52.214587+08
755	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:52.318806+08
742	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:52.247367+08
739	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:52.233086+08
738	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:52.228437+08
756	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-09-02 14:47:52.338741+08
757	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	C:T	C/T	2016-09-02 14:47:52.343381+08
760	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:52.357703+08
761	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-09-02 14:47:52.362529+08
737	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:52.223812+08
762	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:G	A/G	2016-09-02 14:47:52.37305+08
763	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:52.377741+08
759	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.352934+08
758	XYC6560245	P168020113	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.347987+08
764	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:52.392738+08
765	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:G	C/G	2016-09-02 14:47:52.397814+08
766	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:52.402406+08
767	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:52.406843+08
768	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:52.411314+08
769	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:52.4158+08
770	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:52.420254+08
771	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000211	LDLR	G:G	A/G	2016-09-02 14:47:52.424919+08
772	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:52.42944+08
774	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:52.43899+08
776	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:52.448621+08
780	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:52.467405+08
781	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:52.472012+08
783	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:52.48125+08
784	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:52.485903+08
785	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:52.490824+08
786	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:52.49561+08
787	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000161	CRY2	A:C	A/C	2016-09-02 14:47:52.50034+08
788	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:52.505061+08
789	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:52.509714+08
790	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:52.514467+08
791	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000165	PROX1	T:T	C/T	2016-09-02 14:47:52.519081+08
792	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:52.523721+08
793	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000149	GCKR	C:C	C/T	2016-09-02 14:47:52.528523+08
794	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:52.533165+08
773	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:52.433986+08
775	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:52.443931+08
795	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:A	A/T	2016-09-02 14:47:52.548423+08
782	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000158	GCKR	C:C	C/T	2016-09-02 14:47:52.476649+08
779	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:T	C/T	2016-09-02 14:47:52.462751+08
778	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:52.458085+08
796	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-09-02 14:47:52.568707+08
797	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000213	APOA5	C:T	C/T	2016-09-02 14:47:52.573259+08
800	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-02 14:47:52.587388+08
801	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-02 14:47:52.593657+08
777	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:52.453441+08
802	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-02 14:47:52.603772+08
803	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:52.60849+08
799	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.582625+08
798	XYC6560229	P15C280643	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.57783+08
804	XYC6560239	P168230028	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:52.623483+08
805	XYC6560248	P167270186	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:52.627986+08
806	XYC6560244	P168020117	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:52.632635+08
807	XYC6640293	P168250037	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:52.637232+08
808	XYC6560250	P167270187	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:52.64179+08
809	XYC6560246	P168020116	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:52.646805+08
810	XYC6560249	P167270185	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:52.651179+08
811	XYC6560236	P168170329	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:52.655618+08
812	XYC6560245	P168020113	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:52.660036+08
813	XYC6560229	P15C280643	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:52.664648+08
814	XYC6560239	P168230028	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.669363+08
815	XYC6560239	P168230028	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.674242+08
816	XYC6560248	P167270186	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.679001+08
817	XYC6560248	P167270186	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.68367+08
818	XYC6560244	P168020117	HealthWise	饮食类型	单不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:G	C/G	2016-09-02 14:47:52.689068+08
819	XYC6560244	P168020117	HealthWise	饮食类型	单不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.693758+08
820	XYC6640293	P168250037	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.698434+08
821	XYC6640293	P168250037	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.702864+08
822	XYC6560250	P167270187	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.707365+08
823	XYC6560250	P167270187	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.711881+08
824	XYC6560246	P168020116	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.716403+08
825	XYC6560246	P168020116	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.72102+08
826	XYC6560249	P167270185	HealthWise	饮食类型	单不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:G	C/G	2016-09-02 14:47:52.725443+08
827	XYC6560249	P167270185	HealthWise	饮食类型	单不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.72988+08
828	XYC6560236	P168170329	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.734461+08
829	XYC6560236	P168170329	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.739025+08
830	XYC6560245	P168020113	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.743701+08
831	XYC6560245	P168020113	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.748371+08
832	XYC6560229	P15C280643	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.752916+08
833	XYC6560229	P15C280643	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:52.757682+08
834	XYC6560239	P168230028	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.762427+08
835	XYC6560248	P167270186	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.767755+08
836	XYC6560244	P168020117	HealthWise	饮食类型	多不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:G	C/G	2016-09-02 14:47:52.77266+08
837	XYC6640293	P168250037	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.777159+08
838	XYC6560250	P167270187	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.781775+08
839	XYC6560246	P168020116	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.786447+08
840	XYC6560249	P167270185	HealthWise	饮食类型	多不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:G	C/G	2016-09-02 14:47:52.790906+08
841	XYC6560236	P168170329	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.795556+08
842	XYC6560245	P168020113	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.800027+08
843	XYC6560229	P15C280643	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-02 14:47:52.804479+08
844	XYC6560239	P168230028	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.57000005	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.809052+08
845	XYC6560239	P168230028	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.57000005	GWV0000183	ARMS2	G:T	G/T	2016-09-02 14:47:52.813839+08
846	XYC6560239	P168230028	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.57000005	GWV0000184	CFH	G:G	A/G	2016-09-02 14:47:52.818673+08
847	XYC6560239	P168230028	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.57000005	GWV0000185	C2	G:G	G/T	2016-09-02 14:47:52.82352+08
848	XYC6560248	P167270186	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.57000005	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.828089+08
849	XYC6560248	P167270186	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.57000005	GWV0000183	ARMS2	G:T	G/T	2016-09-02 14:47:52.832802+08
850	XYC6560248	P167270186	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.57000005	GWV0000184	CFH	G:G	A/G	2016-09-02 14:47:52.83751+08
851	XYC6560248	P167270186	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.57000005	GWV0000185	C2	G:G	G/T	2016-09-02 14:47:52.842158+08
852	XYC6560244	P168020117	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.846979+08
853	XYC6560244	P168020117	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000183	ARMS2	G:G	G/T	2016-09-02 14:47:52.851599+08
854	XYC6560244	P168020117	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000184	CFH	A:G	A/G	2016-09-02 14:47:52.856886+08
855	XYC6560244	P168020117	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000185	C2	G:G	G/T	2016-09-02 14:47:52.861707+08
856	XYC6640293	P168250037	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	2.18000007	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.866452+08
857	XYC6640293	P168250037	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	2.18000007	GWV0000183	ARMS2	T:T	G/T	2016-09-02 14:47:52.871021+08
858	XYC6640293	P168250037	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	2.18000007	GWV0000184	CFH	A:G	A/G	2016-09-02 14:47:52.875734+08
859	XYC6640293	P168250037	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	2.18000007	GWV0000185	C2	G:G	G/T	2016-09-02 14:47:52.88048+08
860	XYC6560250	P167270187	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.8851+08
861	XYC6560250	P167270187	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000183	ARMS2	G:G	G/T	2016-09-02 14:47:52.889907+08
862	XYC6560250	P167270187	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000184	CFH	G:G	A/G	2016-09-02 14:47:52.894721+08
863	XYC6560250	P167270187	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000185	C2	G:G	G/T	2016-09-02 14:47:52.899487+08
864	XYC6560246	P168020116	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.90408+08
865	XYC6560246	P168020116	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000183	ARMS2	G:T	G/T	2016-09-02 14:47:52.908703+08
866	XYC6560246	P168020116	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000184	CFH	A:G	A/G	2016-09-02 14:47:52.913463+08
867	XYC6560246	P168020116	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000185	C2	G:G	G/T	2016-09-02 14:47:52.918093+08
868	XYC6560249	P167270185	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.922724+08
869	XYC6560249	P167270185	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000183	ARMS2	G:T	G/T	2016-09-02 14:47:52.92736+08
870	XYC6560249	P167270185	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000184	CFH	A:G	A/G	2016-09-02 14:47:52.931967+08
871	XYC6560249	P167270185	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000185	C2	G:G	G/T	2016-09-02 14:47:52.937899+08
872	XYC6560236	P168170329	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.310000002	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.942792+08
873	XYC6560236	P168170329	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.310000002	GWV0000183	ARMS2	G:T	G/T	2016-09-02 14:47:52.947726+08
874	XYC6560236	P168170329	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.310000002	GWV0000184	CFH	A:G	A/G	2016-09-02 14:47:52.952521+08
875	XYC6560236	P168170329	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.310000002	GWV0000185	C2	G:T	G/T	2016-09-02 14:47:52.957266+08
876	XYC6560245	P168020113	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.96188+08
877	XYC6560245	P168020113	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000183	ARMS2	G:G	G/T	2016-09-02 14:47:52.966503+08
878	XYC6560245	P168020113	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000184	CFH	A:G	A/G	2016-09-02 14:47:52.97107+08
879	XYC6560245	P168020113	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000185	C2	G:G	G/T	2016-09-02 14:47:52.975865+08
880	XYC6560229	P15C280643	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000182	C3	G:G	A/G	2016-09-02 14:47:52.98047+08
881	XYC6560229	P15C280643	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000183	ARMS2	G:G	G/T	2016-09-02 14:47:52.985061+08
882	XYC6560229	P15C280643	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000184	CFH	A:G	A/G	2016-09-02 14:47:52.989954+08
883	XYC6560229	P15C280643	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000185	C2	G:G	G/T	2016-09-02 14:47:52.994783+08
884	XYC6560239	P168230028	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.779999971	GWV0000186	BCAT1	C:C	A/C	2016-09-02 14:47:52.999624+08
885	XYC6560239	P168230028	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.779999971	GWV0000187	FGF5	A:A	A/T	2016-09-02 14:47:53.004464+08
886	XYC6560239	P168230028	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.779999971	GWV0000188	PLEKHA7	C:T	C/T	2016-09-02 14:47:53.00911+08
887	XYC6560239	P168230028	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.779999971	GWV0000189	ATP2B1	A:G	A/G	2016-09-02 14:47:53.013867+08
888	XYC6560239	P168230028	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.779999971	GWV0000190	CSK	C:C	A/C	2016-09-02 14:47:53.018535+08
889	XYC6560239	P168230028	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.779999971	GWV0000191	CAPZA1	A:C	A/C	2016-09-02 14:47:53.023224+08
890	XYC6560239	P168230028	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.779999971	GWV0000192	CYP17A1	T:T	C/T	2016-09-02 14:47:53.028564+08
891	XYC6560248	P167270186	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	1.87	GWV0000186	BCAT1	A:C	A/C	2016-09-02 14:47:53.033423+08
892	XYC6560248	P167270186	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	1.87	GWV0000187	FGF5	A:A	A/T	2016-09-02 14:47:53.038036+08
893	XYC6560248	P167270186	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	1.87	GWV0000188	PLEKHA7	C:C	C/T	2016-09-02 14:47:53.042825+08
894	XYC6560248	P167270186	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	1.87	GWV0000189	ATP2B1	A:G	A/G	2016-09-02 14:47:53.047601+08
895	XYC6560248	P167270186	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	1.87	GWV0000190	CSK	C:C	A/C	2016-09-02 14:47:53.052436+08
896	XYC6560248	P167270186	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	1.87	GWV0000191	CAPZA1	C:C	A/C	2016-09-02 14:47:53.057169+08
897	XYC6560248	P167270186	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	1.87	GWV0000192	CYP17A1	T:T	C/T	2016-09-02 14:47:53.061919+08
898	XYC6560244	P168020117	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000186	BCAT1	C:C	A/C	2016-09-02 14:47:53.066704+08
899	XYC6560244	P168020117	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000187	FGF5	A:A	A/T	2016-09-02 14:47:53.071522+08
900	XYC6560244	P168020117	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000188	PLEKHA7	C:C	C/T	2016-09-02 14:47:53.076069+08
901	XYC6560244	P168020117	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000189	ATP2B1	A:G	A/G	2016-09-02 14:47:53.081788+08
902	XYC6560244	P168020117	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000190	CSK	A:C	A/C	2016-09-02 14:47:53.086605+08
903	XYC6560244	P168020117	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000191	CAPZA1	C:C	A/C	2016-09-02 14:47:53.091598+08
904	XYC6560244	P168020117	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000192	CYP17A1	C:T	C/T	2016-09-02 14:47:53.096434+08
905	XYC6640293	P168250037	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000186	BCAT1	A:C	A/C	2016-09-02 14:47:53.101077+08
906	XYC6640293	P168250037	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000187	FGF5	T:T	A/T	2016-09-02 14:47:53.106068+08
907	XYC6640293	P168250037	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000188	PLEKHA7	C:C	C/T	2016-09-02 14:47:53.110658+08
908	XYC6640293	P168250037	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000189	ATP2B1	A:G	A/G	2016-09-02 14:47:53.115461+08
909	XYC6640293	P168250037	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000190	CSK	C:C	A/C	2016-09-02 14:47:53.120044+08
910	XYC6640293	P168250037	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000191	CAPZA1	A:C	A/C	2016-09-02 14:47:53.124765+08
911	XYC6640293	P168250037	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.42999995	GWV0000192	CYP17A1	T:T	C/T	2016-09-02 14:47:53.129491+08
912	XYC6560250	P167270187	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.38999999	GWV0000186	BCAT1	C:C	A/C	2016-09-02 14:47:53.134153+08
913	XYC6560250	P167270187	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.38999999	GWV0000187	FGF5	A:T	A/T	2016-09-02 14:47:53.138974+08
914	XYC6560250	P167270187	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.38999999	GWV0000188	PLEKHA7	C:C	C/T	2016-09-02 14:47:53.143738+08
915	XYC6560250	P167270187	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.38999999	GWV0000189	ATP2B1	A:G	A/G	2016-09-02 14:47:53.148575+08
916	XYC6560250	P167270187	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.38999999	GWV0000190	CSK	A:C	A/C	2016-09-02 14:47:53.153487+08
917	XYC6560250	P167270187	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.38999999	GWV0000191	CAPZA1	C:C	A/C	2016-09-02 14:47:53.159033+08
918	XYC6560250	P167270187	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.38999999	GWV0000192	CYP17A1	T:T	C/T	2016-09-02 14:47:53.163763+08
919	XYC6560246	P168020116	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.879999995	GWV0000186	BCAT1	A:C	A/C	2016-09-02 14:47:53.168596+08
920	XYC6560246	P168020116	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.879999995	GWV0000187	FGF5	A:T	A/T	2016-09-02 14:47:53.173266+08
921	XYC6560246	P168020116	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.879999995	GWV0000188	PLEKHA7	C:C	C/T	2016-09-02 14:47:53.178044+08
922	XYC6560246	P168020116	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.879999995	GWV0000189	ATP2B1	G:G	A/G	2016-09-02 14:47:53.182823+08
923	XYC6560246	P168020116	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.879999995	GWV0000190	CSK	C:C	A/C	2016-09-02 14:47:53.187916+08
924	XYC6560246	P168020116	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.879999995	GWV0000191	CAPZA1	A:C	A/C	2016-09-02 14:47:53.192785+08
925	XYC6560246	P168020116	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.879999995	GWV0000192	CYP17A1	T:T	C/T	2016-09-02 14:47:53.197569+08
926	XYC6560249	P167270185	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000186	BCAT1	C:C	A/C	2016-09-02 14:47:53.202051+08
927	XYC6560249	P167270185	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000187	FGF5	A:T	A/T	2016-09-02 14:47:53.206745+08
928	XYC6560249	P167270185	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000188	PLEKHA7	C:C	C/T	2016-09-02 14:47:53.211423+08
929	XYC6560249	P167270185	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000189	ATP2B1	A:A	A/G	2016-09-02 14:47:53.216103+08
930	XYC6560249	P167270185	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000190	CSK	A:C	A/C	2016-09-02 14:47:53.220749+08
931	XYC6560249	P167270185	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000191	CAPZA1	A:C	A/C	2016-09-02 14:47:53.225408+08
932	XYC6560249	P167270185	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000192	CYP17A1	C:T	C/T	2016-09-02 14:47:53.231374+08
933	XYC6560236	P168170329	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000186	BCAT1	C:C	A/C	2016-09-02 14:47:53.236028+08
934	XYC6560236	P168170329	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000187	FGF5	A:T	A/T	2016-09-02 14:47:53.240765+08
935	XYC6560236	P168170329	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000188	PLEKHA7	C:C	C/T	2016-09-02 14:47:53.245434+08
936	XYC6560236	P168170329	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000189	ATP2B1	A:G	A/G	2016-09-02 14:47:53.250066+08
937	XYC6560236	P168170329	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000190	CSK	A:A	A/C	2016-09-02 14:47:53.254869+08
938	XYC6560236	P168170329	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000191	CAPZA1	A:C	A/C	2016-09-02 14:47:53.259645+08
939	XYC6560236	P168170329	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000192	CYP17A1	C:T	C/T	2016-09-02 14:47:53.26444+08
940	XYC6560245	P168020113	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.14999998	GWV0000186	BCAT1	C:C	A/C	2016-09-02 14:47:53.269076+08
941	XYC6560245	P168020113	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.14999998	GWV0000187	FGF5	A:T	A/T	2016-09-02 14:47:53.273755+08
942	XYC6560245	P168020113	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.14999998	GWV0000188	PLEKHA7	C:C	C/T	2016-09-02 14:47:53.278478+08
943	XYC6560245	P168020113	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.14999998	GWV0000189	ATP2B1	A:G	A/G	2016-09-02 14:47:53.283119+08
944	XYC6560245	P168020113	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.14999998	GWV0000190	CSK	C:C	A/C	2016-09-02 14:47:53.28784+08
945	XYC6560245	P168020113	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.14999998	GWV0000191	CAPZA1	A:C	A/C	2016-09-02 14:47:53.293102+08
946	XYC6560245	P168020113	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.14999998	GWV0000192	CYP17A1	C:T	C/T	2016-09-02 14:47:53.297838+08
947	XYC6560229	P15C280643	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.479999989	GWV0000186	BCAT1	C:C	A/C	2016-09-02 14:47:53.302495+08
948	XYC6560229	P15C280643	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.479999989	GWV0000187	FGF5	A:A	A/T	2016-09-02 14:47:53.307062+08
949	XYC6560229	P15C280643	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.479999989	GWV0000188	PLEKHA7	C:C	C/T	2016-09-02 14:47:53.311828+08
950	XYC6560229	P15C280643	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.479999989	GWV0000189	ATP2B1	A:G	A/G	2016-09-02 14:47:53.316478+08
951	XYC6560229	P15C280643	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.479999989	GWV0000190	CSK	A:C	A/C	2016-09-02 14:47:53.321246+08
952	XYC6560229	P15C280643	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.479999989	GWV0000191	CAPZA1	A:C	A/C	2016-09-02 14:47:53.325903+08
953	XYC6560229	P15C280643	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.479999989	GWV0000192	CYP17A1	T:T	C/T	2016-09-02 14:47:53.330696+08
954	XYC6560239	P168230028	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-02 14:47:53.335818+08
955	XYC6560248	P167270186	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-02 14:47:53.340483+08
956	XYC6560244	P168020117	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-02 14:47:53.345146+08
957	XYC6640293	P168250037	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-02 14:47:53.350056+08
958	XYC6560250	P167270187	HealthWise	遗传特质	酒精代谢能力	弱	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-09-02 14:47:53.354878+08
959	XYC6560246	P168020116	HealthWise	遗传特质	酒精代谢能力	弱	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-09-02 14:47:53.359672+08
960	XYC6560249	P167270185	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-02 14:47:53.364413+08
961	XYC6560236	P168170329	HealthWise	遗传特质	酒精代谢能力	弱	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-09-02 14:47:53.36902+08
962	XYC6560245	P168020113	HealthWise	遗传特质	酒精代谢能力	弱	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-09-02 14:47:53.37372+08
963	XYC6560229	P15C280643	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-02 14:47:53.378434+08
964	XYC6560239	P168230028	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-09-02 14:47:53.383466+08
965	XYC6560239	P168230028	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-02 14:47:53.38816+08
966	XYC6560248	P167270186	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-02 14:47:53.392947+08
967	XYC6560248	P167270186	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:53.397775+08
968	XYC6560244	P168020117	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-02 14:47:53.402448+08
969	XYC6560244	P168020117	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:53.407058+08
970	XYC6640293	P168250037	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-02 14:47:53.411793+08
971	XYC6640293	P168250037	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:53.416382+08
972	XYC6560250	P167270187	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-09-02 14:47:53.421103+08
973	XYC6560250	P167270187	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-02 14:47:53.425884+08
974	XYC6560246	P168020116	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-02 14:47:53.430571+08
975	XYC6560246	P168020116	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:53.43516+08
976	XYC6560249	P167270185	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-09-02 14:47:53.440455+08
977	XYC6560249	P167270185	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-02 14:47:53.445175+08
978	XYC6560236	P168170329	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-09-02 14:47:53.449944+08
979	XYC6560236	P168170329	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-02 14:47:53.454726+08
980	XYC6560245	P168020113	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-02 14:47:53.459404+08
981	XYC6560245	P168020113	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:53.463892+08
982	XYC6560229	P15C280643	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-02 14:47:53.469087+08
983	XYC6560229	P15C280643	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:53.47372+08
984	XYC6560239	P168230028	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-02 14:47:53.478305+08
985	XYC6560248	P167270186	HealthWise	遗传特质	甜味敏感度	低	genotype_lookup	\N	GWV0000196	TAS1R3	T:T	C/T	2016-09-02 14:47:53.482941+08
986	XYC6560244	P168020117	HealthWise	遗传特质	甜味敏感度	低	genotype_lookup	\N	GWV0000196	TAS1R3	C:T	C/T	2016-09-02 14:47:53.487614+08
987	XYC6640293	P168250037	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-02 14:47:53.492047+08
988	XYC6560250	P167270187	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-02 14:47:53.496735+08
989	XYC6560246	P168020116	HealthWise	遗传特质	甜味敏感度	低	genotype_lookup	\N	GWV0000196	TAS1R3	C:T	C/T	2016-09-02 14:47:53.501282+08
990	XYC6560249	P167270185	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-02 14:47:53.505827+08
991	XYC6560236	P168170329	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-02 14:47:53.510384+08
992	XYC6560245	P168020113	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-02 14:47:53.514987+08
993	XYC6560229	P15C280643	HealthWise	遗传特质	甜味敏感度	低	genotype_lookup	\N	GWV0000196	TAS1R3	C:T	C/T	2016-09-02 14:47:53.519407+08
994	XYC6560239	P168230028	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-02 14:47:53.52388+08
995	XYC6560248	P167270186	HealthWise	遗传特质	肌肉爆发力	弱	genotype_lookup	\N	GWV0000197	ACTN3	T:T	C/T	2016-09-02 14:47:53.528648+08
996	XYC6560244	P168020117	HealthWise	遗传特质	肌肉爆发力	弱	genotype_lookup	\N	GWV0000197	ACTN3	T:T	C/T	2016-09-02 14:47:53.533446+08
997	XYC6640293	P168250037	HealthWise	遗传特质	肌肉爆发力	强	genotype_lookup	\N	GWV0000197	ACTN3	C:C	C/T	2016-09-02 14:47:53.537991+08
998	XYC6560250	P167270187	HealthWise	遗传特质	肌肉爆发力	强	genotype_lookup	\N	GWV0000197	ACTN3	C:C	C/T	2016-09-02 14:47:53.54268+08
999	XYC6560246	P168020116	HealthWise	遗传特质	肌肉爆发力	弱	genotype_lookup	\N	GWV0000197	ACTN3	T:T	C/T	2016-09-02 14:47:53.547389+08
1000	XYC6560249	P167270185	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-02 14:47:53.552854+08
1001	XYC6560236	P168170329	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-02 14:47:53.557766+08
1002	XYC6560245	P168020113	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-02 14:47:53.56243+08
1003	XYC6560229	P15C280643	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-02 14:47:53.567048+08
1004	XYC6560239	P168230028	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.571734+08
1005	XYC6560248	P167270186	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.576498+08
1006	XYC6560244	P168020117	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.581017+08
1007	XYC6640293	P168250037	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.585728+08
1008	XYC6560250	P167270187	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.590453+08
1009	XYC6560246	P168020116	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.595139+08
1010	XYC6560249	P167270185	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.59999+08
1011	XYC6560236	P168170329	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.604761+08
1012	XYC6560245	P168020113	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.609375+08
1013	XYC6560229	P15C280643	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-02 14:47:53.613874+08
1014	XYC6560239	P168230028	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.618486+08
1015	XYC6560248	P167270186	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.62305+08
1016	XYC6560244	P168020117	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.62771+08
1017	XYC6640293	P168250037	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.632309+08
1018	XYC6560250	P167270187	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.636966+08
1019	XYC6560246	P168020116	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.642003+08
1020	XYC6560249	P167270185	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.64683+08
1021	XYC6560236	P168170329	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.651337+08
1022	XYC6560245	P168020113	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.656003+08
1023	XYC6560229	P15C280643	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-02 14:47:53.660642+08
1024	XYC6560239	P168230028	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-02 14:47:53.665429+08
1025	XYC6560248	P167270186	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-02 14:47:53.670095+08
1026	XYC6560244	P168020117	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-02 14:47:53.674873+08
1027	XYC6640293	P168250037	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-02 14:47:53.679491+08
1028	XYC6560250	P167270187	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-02 14:47:53.685096+08
1029	XYC6560246	P168020116	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-02 14:47:53.690247+08
1030	XYC6560249	P167270185	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-02 14:47:53.694984+08
1031	XYC6560236	P168170329	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-02 14:47:53.699809+08
1032	XYC6560245	P168020113	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	C:C	A/C	2016-09-02 14:47:53.704574+08
1033	XYC6560229	P15C280643	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-02 14:47:53.709271+08
1034	XYC6560239	P168230028	HealthWise	营养需求	维生素A水平	未知	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-02 14:47:53.713756+08
1035	XYC6560239	P168230028	HealthWise	营养需求	维生素A水平	未知	genotype_lookup	\N	GWV0000123	BCMO1	A:T	A/T	2016-09-02 14:47:53.7191+08
1036	XYC6560248	P167270186	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-09-02 14:47:53.723736+08
1037	XYC6560248	P167270186	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-02 14:47:53.728362+08
1038	XYC6560244	P168020117	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-09-02 14:47:53.732987+08
1039	XYC6560244	P168020117	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:T	A/T	2016-09-02 14:47:53.737674+08
1040	XYC6640293	P168250037	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-09-02 14:47:53.742434+08
1041	XYC6640293	P168250037	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-02 14:47:53.747034+08
1042	XYC6560250	P167270187	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-02 14:47:53.751671+08
1043	XYC6560250	P167270187	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-02 14:47:53.7563+08
1044	XYC6560246	P168020116	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	T:T	C/T	2016-09-02 14:47:53.761003+08
1045	XYC6560246	P168020116	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-02 14:47:53.765612+08
1046	XYC6560249	P167270185	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-09-02 14:47:53.770287+08
1047	XYC6560249	P167270185	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-02 14:47:53.774869+08
1048	XYC6560236	P168170329	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-02 14:47:53.77947+08
1049	XYC6560236	P168170329	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-02 14:47:53.783901+08
1050	XYC6560245	P168020113	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-09-02 14:47:53.788456+08
1051	XYC6560245	P168020113	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-02 14:47:53.793816+08
1052	XYC6560229	P15C280643	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-02 14:47:53.798408+08
1053	XYC6560229	P15C280643	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-02 14:47:53.803002+08
1054	XYC6560239	P168230028	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:53.807617+08
1055	XYC6560248	P167270186	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:53.812572+08
1056	XYC6560244	P168020117	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:53.817035+08
1057	XYC6640293	P168250037	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:53.821705+08
1058	XYC6560250	P167270187	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:53.826218+08
1059	XYC6560246	P168020116	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:53.830759+08
1060	XYC6560249	P167270185	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:53.835408+08
1061	XYC6560236	P168170329	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-02 14:47:53.839981+08
1062	XYC6560245	P168020113	HealthWise	营养需求	维生素B$_{2}$水平	偏低	genotype_lookup	\N	GWV0000199	MTHFR	A:A	A/G	2016-09-02 14:47:53.844622+08
1063	XYC6560229	P15C280643	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:53.849142+08
1064	XYC6560239	P168230028	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-02 14:47:53.854385+08
1065	XYC6560248	P167270186	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-02 14:47:53.858961+08
1066	XYC6560244	P168020117	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-02 14:47:53.863637+08
1067	XYC6640293	P168250037	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-02 14:47:53.868052+08
1068	XYC6560250	P167270187	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-02 14:47:53.872755+08
1069	XYC6560246	P168020116	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-02 14:47:53.877365+08
1070	XYC6560249	P167270185	HealthWise	营养需求	维生素B$_{6}$水平	正常	genotype_lookup	\N	GWV0000125	NBPF3	T:T	C/T	2016-09-02 14:47:53.881879+08
1071	XYC6560236	P168170329	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:C	C/T	2016-09-02 14:47:53.886451+08
1072	XYC6560245	P168020113	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-02 14:47:53.891005+08
1073	XYC6560229	P15C280643	HealthWise	营养需求	维生素B$_{6}$水平	正常	genotype_lookup	\N	GWV0000125	NBPF3	T:T	C/T	2016-09-02 14:47:53.895522+08
1074	XYC6560239	P168230028	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.900025+08
1075	XYC6560239	P168230028	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-09-02 14:47:53.904734+08
1076	XYC6560248	P167270186	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.909487+08
1077	XYC6560248	P167270186	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000126	FUT2	A:A	A/T	2016-09-02 14:47:53.914006+08
1078	XYC6560244	P168020117	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.918747+08
1079	XYC6560244	P168020117	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000126	FUT2	A:A	A/T	2016-09-02 14:47:53.923488+08
1080	XYC6640293	P168250037	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.928103+08
1081	XYC6640293	P168250037	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000126	FUT2	A:A	A/T	2016-09-02 14:47:53.932862+08
1082	XYC6560250	P167270187	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.938468+08
1083	XYC6560250	P167270187	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000126	FUT2	A:A	A/T	2016-09-02 14:47:53.943146+08
1084	XYC6560246	P168020116	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.947962+08
1085	XYC6560246	P168020116	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-09-02 14:47:53.95261+08
1086	XYC6560249	P167270185	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.957429+08
1087	XYC6560249	P167270185	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000126	FUT2	A:A	A/T	2016-09-02 14:47:53.962069+08
1088	XYC6560236	P168170329	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.966806+08
1089	XYC6560236	P168170329	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-09-02 14:47:53.971411+08
1090	XYC6560245	P168020113	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.976039+08
1091	XYC6560245	P168020113	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000126	FUT2	A:A	A/T	2016-09-02 14:47:53.980787+08
1092	XYC6560229	P15C280643	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-02 14:47:53.985425+08
1093	XYC6560229	P15C280643	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-09-02 14:47:53.989985+08
1094	XYC6560239	P168230028	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:G	G/T	2016-09-02 14:47:53.994607+08
1095	XYC6560248	P167270186	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-09-02 14:47:53.999052+08
1096	XYC6560244	P168020117	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-02 14:47:54.003706+08
1097	XYC6640293	P168250037	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-02 14:47:54.008302+08
1098	XYC6560250	P167270187	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-09-02 14:47:54.013053+08
1099	XYC6560246	P168020116	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-02 14:47:54.017858+08
1100	XYC6560249	P167270185	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-09-02 14:47:54.023442+08
1101	XYC6560236	P168170329	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-09-02 14:47:54.027967+08
1102	XYC6560245	P168020113	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:G	G/T	2016-09-02 14:47:54.032574+08
1103	XYC6560229	P15C280643	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-09-02 14:47:54.036996+08
1104	XYC6560239	P168230028	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.041442+08
1105	XYC6560248	P167270186	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.045982+08
1106	XYC6560244	P168020117	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.050554+08
1107	XYC6640293	P168250037	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.055146+08
1108	XYC6560250	P167270187	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.059756+08
1109	XYC6560246	P168020116	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.064375+08
1110	XYC6560249	P167270185	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.069039+08
1111	XYC6560236	P168170329	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.073664+08
1112	XYC6560245	P168020113	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.078339+08
1113	XYC6560229	P15C280643	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-02 14:47:54.082938+08
1114	XYC6560239	P168230028	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:54.087455+08
1115	XYC6560248	P167270186	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:54.092021+08
1116	XYC6560244	P168020117	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:54.096647+08
1117	XYC6640293	P168250037	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:54.101248+08
1118	XYC6560250	P167270187	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:54.105885+08
1119	XYC6560246	P168020116	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:54.11128+08
1120	XYC6560249	P167270185	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:54.115936+08
1121	XYC6560236	P168170329	HealthWise	营养需求	叶酸水平	偏低	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-02 14:47:54.120467+08
1122	XYC6560245	P168020113	HealthWise	营养需求	叶酸水平	偏低	genotype_lookup	\N	GWV0000199	MTHFR	A:A	A/G	2016-09-02 14:47:54.124951+08
1123	XYC6560229	P15C280643	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-02 14:47:54.129604+08
1124	XYC6560239	P168230028	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.134058+08
1125	XYC6560248	P167270186	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.138688+08
1126	XYC6560244	P168020117	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.143395+08
1127	XYC6640293	P168250037	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.148116+08
1128	XYC6560250	P167270187	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.15281+08
1129	XYC6560246	P168020116	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.157523+08
1130	XYC6560249	P167270185	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.162039+08
1131	XYC6560236	P168170329	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.166743+08
1132	XYC6560245	P168020113	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.171587+08
1133	XYC6560229	P15C280643	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-02 14:47:54.17608+08
1134	XYC6560239	P168230028	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000051	MC4R	T:T	C/T	2016-09-02 14:47:54.180724+08
1135	XYC6560239	P168230028	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.18541+08
1136	XYC6560248	P167270186	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.14999998	GWV0000051	MC4R	T:T	C/T	2016-09-02 14:47:54.190794+08
1137	XYC6560248	P167270186	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.14999998	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:54.195799+08
1138	XYC6560244	P168020117	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000051	MC4R	T:T	C/T	2016-09-02 14:47:54.200619+08
1139	XYC6560244	P168020117	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.205478+08
1140	XYC6640293	P168250037	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.45000005	GWV0000051	MC4R	C:C	C/T	2016-09-02 14:47:54.21007+08
1141	XYC6640293	P168250037	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.45000005	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:54.215075+08
1142	XYC6560250	P167270187	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.14999998	GWV0000051	MC4R	T:T	C/T	2016-09-02 14:47:54.21984+08
1143	XYC6560250	P167270187	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.14999998	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:54.224571+08
1144	XYC6560246	P168020116	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.14999998	GWV0000051	MC4R	T:T	C/T	2016-09-02 14:47:54.229268+08
1145	XYC6560246	P168020116	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.14999998	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:54.23391+08
1146	XYC6560249	P167270185	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000051	MC4R	C:T	C/T	2016-09-02 14:47:54.238676+08
1147	XYC6560249	P167270185	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.243486+08
1148	XYC6560236	P168170329	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000051	MC4R	T:T	C/T	2016-09-02 14:47:54.248159+08
1149	XYC6560236	P168170329	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.253065+08
1150	XYC6560245	P168020113	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000051	MC4R	T:T	C/T	2016-09-02 14:47:54.257843+08
1151	XYC6560245	P168020113	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.262494+08
1152	XYC6560229	P15C280643	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000051	MC4R	T:T	C/T	2016-09-02 14:47:54.267081+08
1153	XYC6560229	P15C280643	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.271908+08
1154	XYC6560239	P168230028	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.276781+08
1155	XYC6560248	P167270186	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.28141+08
1156	XYC6560244	P168020117	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.285946+08
1157	XYC6640293	P168250037	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.2905+08
1158	XYC6560250	P167270187	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.294957+08
1159	XYC6560246	P168020116	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.299426+08
1160	XYC6560249	P167270185	HealthWise	体重管理	脂联素水平降低风险	高风险	genotype_lookup	\N	GWV0000200	ADIPOQ	A:G	A/G	2016-09-02 14:47:54.30393+08
1161	XYC6560236	P168170329	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.308405+08
1162	XYC6560245	P168020113	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.313022+08
1163	XYC6560229	P15C280643	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.317705+08
1164	XYC6560239	P168230028	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.322381+08
1165	XYC6560248	P167270186	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.327059+08
1166	XYC6560244	P168020117	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.33181+08
1167	XYC6640293	P168250037	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.336451+08
1168	XYC6560250	P167270187	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.341094+08
1169	XYC6560246	P168020116	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.345815+08
1170	XYC6560249	P167270185	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.350668+08
1171	XYC6560236	P168170329	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.355467+08
1172	XYC6560245	P168020113	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.360857+08
1173	XYC6560229	P15C280643	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-02 14:47:54.365682+08
1174	XYC6560239	P168230028	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.37048+08
1175	XYC6560248	P167270186	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.375256+08
1176	XYC6560244	P168020117	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.379918+08
1177	XYC6640293	P168250037	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.384566+08
1178	XYC6560250	P167270187	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.38917+08
1179	XYC6560246	P168020116	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.39385+08
1180	XYC6560249	P167270185	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.398469+08
1181	XYC6560236	P168170329	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.403087+08
1182	XYC6560245	P168020113	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.407829+08
1183	XYC6560229	P15C280643	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-02 14:47:54.412539+08
1184	XYC6560239	P168230028	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-02 14:47:54.41696+08
1185	XYC6560248	P167270186	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:54.421606+08
1186	XYC6560244	P168020117	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:54.426136+08
1187	XYC6640293	P168250037	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:54.430841+08
1188	XYC6560250	P167270187	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-02 14:47:54.435364+08
1189	XYC6560246	P168020116	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:54.440418+08
1190	XYC6560249	P167270185	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-02 14:47:54.445061+08
1191	XYC6560236	P168170329	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-02 14:47:54.450074+08
1192	XYC6560245	P168020113	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:54.454783+08
1193	XYC6560229	P15C280643	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-02 14:47:54.459386+08
1194	XYC6560239	P168230028	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:A	A/G	2016-09-02 14:47:54.463908+08
1195	XYC6560248	P167270186	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-09-02 14:47:54.468577+08
1196	XYC6560244	P168020117	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-09-02 14:47:54.473106+08
1197	XYC6640293	P168250037	HealthWise	饮食习惯	饮食偏好	正常	genotype_lookup	\N	GWV0000121	ANKK1	G:G	A/G	2016-09-02 14:47:54.477945+08
1198	XYC6560250	P167270187	HealthWise	饮食习惯	饮食偏好	正常	genotype_lookup	\N	GWV0000121	ANKK1	G:G	A/G	2016-09-02 14:47:54.482431+08
1199	XYC6560246	P168020116	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-09-02 14:47:54.486973+08
1200	XYC6560249	P167270185	HealthWise	饮食习惯	饮食偏好	正常	genotype_lookup	\N	GWV0000121	ANKK1	G:G	A/G	2016-09-02 14:47:54.491645+08
1201	XYC6560236	P168170329	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:A	A/G	2016-09-02 14:47:54.496509+08
1202	XYC6560245	P168020113	HealthWise	饮食习惯	饮食偏好	正常	genotype_lookup	\N	GWV0000121	ANKK1	G:G	A/G	2016-09-02 14:47:54.501071+08
1203	XYC6560229	P15C280643	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-09-02 14:47:54.505821+08
1204	XYC6560239	P168230028	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.510431+08
1205	XYC6560248	P167270186	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:54.515007+08
1206	XYC6560244	P168020117	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.519698+08
1207	XYC6640293	P168250037	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:54.524287+08
1208	XYC6560250	P167270187	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:54.528948+08
1209	XYC6560246	P168020116	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	A:T	A/T	2016-09-02 14:47:54.534373+08
1210	XYC6560249	P167270185	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.538923+08
1211	XYC6560236	P168170329	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.543544+08
1212	XYC6560245	P168020113	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.548239+08
1213	XYC6560229	P15C280643	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-02 14:47:54.55288+08
1214	XYC6560239	P168230028	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-02 14:47:54.55768+08
1215	XYC6560248	P167270186	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-02 14:47:54.562397+08
1216	XYC6560244	P168020117	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:T	G/T	2016-09-02 14:47:54.567084+08
1217	XYC6640293	P168250037	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-02 14:47:54.571811+08
1218	XYC6560250	P167270187	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-02 14:47:54.576656+08
1219	XYC6560246	P168020116	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-02 14:47:54.581489+08
1220	XYC6560249	P167270185	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:T	G/T	2016-09-02 14:47:54.587283+08
1221	XYC6560236	P168170329	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-02 14:47:54.592011+08
1222	XYC6560245	P168020113	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:T	G/T	2016-09-02 14:47:54.596897+08
1223	XYC6560229	P15C280643	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:T	G/T	2016-09-02 14:47:54.601494+08
1224	XYC6560239	P168230028	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-02 14:47:54.606077+08
1225	XYC6560248	P167270186	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-09-02 14:47:54.610851+08
1226	XYC6560244	P168020117	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-02 14:47:54.615652+08
1227	XYC6640293	P168250037	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-02 14:47:54.620376+08
1228	XYC6560250	P167270187	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-02 14:47:54.624992+08
1229	XYC6560246	P168020116	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-09-02 14:47:54.629651+08
1230	XYC6560249	P167270185	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-09-02 14:47:54.63438+08
1231	XYC6560236	P168170329	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-02 14:47:54.639091+08
1232	XYC6560245	P168020113	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-02 14:47:54.643751+08
1233	XYC6560229	P15C280643	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-09-02 14:47:54.648412+08
1234	XYC6560239	P168230028	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.653094+08
1235	XYC6560248	P167270186	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.657846+08
1236	XYC6560244	P168020117	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.662624+08
1237	XYC6640293	P168250037	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.667442+08
1238	XYC6560250	P167270187	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.672929+08
1239	XYC6560246	P168020116	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.677769+08
1240	XYC6560249	P167270185	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.682454+08
1241	XYC6560236	P168170329	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.687409+08
1242	XYC6560245	P168020113	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.692072+08
1243	XYC6560229	P15C280643	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-02 14:47:54.696802+08
1244	XYC6560239	P168230028	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	40.3800011	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:54.701672+08
1245	XYC6560239	P168230028	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	40.3800011	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:54.706514+08
1246	XYC6560239	P168230028	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	40.3800011	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:54.711632+08
1247	XYC6560239	P168230028	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	40.3800011	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:54.716516+08
1248	XYC6560239	P168230028	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	40.3800011	GWV0000170	GALNT2	A:G	A/G	2016-09-02 14:47:54.721976+08
1249	XYC6560239	P168230028	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	40.3800011	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:54.727091+08
1250	XYC6560239	P168230028	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	40.3800011	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:54.732233+08
1251	XYC6560239	P168230028	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	40.3800011	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:54.737364+08
1252	XYC6560248	P167270186	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000167	ABCA1	C:T	C/T	2016-09-02 14:47:54.742547+08
1253	XYC6560248	P167270186	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:54.74718+08
1254	XYC6560248	P167270186	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:54.752031+08
1255	XYC6560248	P167270186	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:54.757515+08
1256	XYC6560248	P167270186	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:54.762639+08
1257	XYC6560248	P167270186	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:54.767707+08
1258	XYC6560248	P167270186	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:54.772656+08
1259	XYC6560248	P167270186	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:54.778019+08
1260	XYC6560244	P168020117	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:54.785395+08
1261	XYC6560244	P168020117	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:54.799394+08
1262	XYC6560244	P168020117	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:54.804432+08
1263	XYC6560244	P168020117	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:54.809378+08
1264	XYC6560244	P168020117	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:54.814248+08
1265	XYC6560244	P168020117	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:54.819238+08
1266	XYC6560244	P168020117	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:54.824154+08
1267	XYC6560244	P168020117	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	45.1899986	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:54.82907+08
1268	XYC6640293	P168250037	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高风险	metabolic_disease	87.5	GWV0000167	ABCA1	C:T	C/T	2016-09-02 14:47:54.833872+08
1269	XYC6640293	P168250037	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高风险	metabolic_disease	87.5	GWV0000146	ZNF259	G:G	C/G	2016-09-02 14:47:54.838652+08
1270	XYC6640293	P168250037	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高风险	metabolic_disease	87.5	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:54.844122+08
1271	XYC6640293	P168250037	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高风险	metabolic_disease	87.5	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:54.849112+08
1272	XYC6640293	P168250037	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高风险	metabolic_disease	87.5	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:54.854006+08
1273	XYC6640293	P168250037	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高风险	metabolic_disease	87.5	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:54.859058+08
1274	XYC6640293	P168250037	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高风险	metabolic_disease	87.5	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:54.863943+08
1275	XYC6640293	P168250037	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高风险	metabolic_disease	87.5	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:54.868802+08
1276	XYC6560250	P167270187	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:54.873639+08
1277	XYC6560250	P167270187	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:54.878494+08
1278	XYC6560250	P167270187	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:54.883517+08
1279	XYC6560250	P167270187	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:54.888466+08
1280	XYC6560250	P167270187	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:54.893563+08
1281	XYC6560250	P167270187	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:54.898649+08
1282	XYC6560250	P167270187	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:54.903776+08
1283	XYC6560250	P167270187	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:54.908761+08
1284	XYC6560246	P168020116	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	69.2300034	GWV0000167	ABCA1	C:T	C/T	2016-09-02 14:47:54.913622+08
1285	XYC6560246	P168020116	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	69.2300034	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:54.918472+08
1286	XYC6560246	P168020116	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	69.2300034	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:54.92352+08
1287	XYC6560246	P168020116	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	69.2300034	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:54.928531+08
1288	XYC6560246	P168020116	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	69.2300034	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:54.933605+08
1289	XYC6560246	P168020116	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	69.2300034	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:54.939161+08
1290	XYC6560246	P168020116	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	69.2300034	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:54.944094+08
1291	XYC6560246	P168020116	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	69.2300034	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:54.949105+08
1292	XYC6560249	P167270185	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	36.5400009	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:54.95385+08
1293	XYC6560249	P167270185	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	36.5400009	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:54.958598+08
1294	XYC6560249	P167270185	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	36.5400009	GWV0000204	CETP	A:C	A/C	2016-09-02 14:47:54.963502+08
1295	XYC6560249	P167270185	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	36.5400009	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:54.968352+08
1296	XYC6560249	P167270185	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	36.5400009	GWV0000170	GALNT2	A:G	A/G	2016-09-02 14:47:54.973253+08
1297	XYC6560249	P167270185	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	36.5400009	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:54.97825+08
1298	XYC6560249	P167270185	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	36.5400009	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:54.98325+08
1299	XYC6560249	P167270185	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	36.5400009	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:54.988085+08
1300	XYC6560236	P168170329	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:54.992954+08
1301	XYC6560236	P168170329	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:54.997806+08
1302	XYC6560236	P168170329	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:55.003479+08
1303	XYC6560236	P168170329	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:55.008555+08
1304	XYC6560236	P168170329	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:55.013744+08
1305	XYC6560236	P168170329	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:55.019784+08
1306	XYC6560236	P168170329	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:55.024897+08
1307	XYC6560236	P168170329	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000206	MLXIPL	C:T	C/T	2016-09-02 14:47:55.029887+08
1308	XYC6560245	P168020113	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	65.3799973	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:55.034739+08
1309	XYC6560245	P168020113	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	65.3799973	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:55.039549+08
1310	XYC6560245	P168020113	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	65.3799973	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:55.045012+08
1311	XYC6560245	P168020113	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	65.3799973	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:55.049964+08
1312	XYC6560245	P168020113	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	65.3799973	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:55.055001+08
1313	XYC6560245	P168020113	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	65.3799973	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:55.0601+08
1314	XYC6560245	P168020113	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	65.3799973	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:55.065171+08
1315	XYC6560245	P168020113	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	65.3799973	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:55.070095+08
1316	XYC6560229	P15C280643	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	58.6500015	GWV0000167	ABCA1	C:C	C/T	2016-09-02 14:47:55.074952+08
1317	XYC6560229	P15C280643	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	58.6500015	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:55.07967+08
1318	XYC6560229	P15C280643	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	58.6500015	GWV0000204	CETP	C:C	A/C	2016-09-02 14:47:55.084647+08
1319	XYC6560229	P15C280643	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	58.6500015	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:55.089523+08
1320	XYC6560229	P15C280643	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	58.6500015	GWV0000170	GALNT2	G:G	A/G	2016-09-02 14:47:55.094545+08
1321	XYC6560229	P15C280643	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	58.6500015	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:55.099564+08
1322	XYC6560229	P15C280643	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	58.6500015	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:55.104531+08
1323	XYC6560229	P15C280643	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	58.6500015	GWV0000206	MLXIPL	C:T	C/T	2016-09-02 14:47:55.10944+08
1324	XYC6560239	P168230028	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:55.11402+08
1325	XYC6560239	P168230028	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:55.118778+08
1326	XYC6560239	P168230028	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:55.123876+08
1327	XYC6560239	P168230028	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000207	HMGCR	T:T	A/T	2016-09-02 14:47:55.128775+08
1328	XYC6560239	P168230028	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:55.133714+08
1329	XYC6560239	P168230028	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:55.13869+08
1330	XYC6560239	P168230028	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:55.143631+08
1331	XYC6560239	P168230028	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:55.148563+08
1332	XYC6560248	P167270186	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:55.153439+08
1333	XYC6560248	P167270186	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:55.15847+08
1334	XYC6560248	P167270186	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:55.163267+08
1335	XYC6560248	P167270186	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000207	HMGCR	T:T	A/T	2016-09-02 14:47:55.168105+08
1336	XYC6560248	P167270186	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:55.173253+08
1337	XYC6560248	P167270186	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:55.178488+08
1338	XYC6560248	P167270186	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:55.183444+08
1339	XYC6560248	P167270186	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:55.188876+08
1340	XYC6560244	P168020117	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.9900017	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:55.193865+08
1341	XYC6560244	P168020117	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.9900017	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:55.198737+08
1342	XYC6560244	P168020117	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.9900017	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:55.203725+08
1343	XYC6560244	P168020117	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.9900017	GWV0000207	HMGCR	T:T	A/T	2016-09-02 14:47:55.208654+08
1344	XYC6560244	P168020117	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.9900017	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:55.213527+08
1345	XYC6560244	P168020117	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.9900017	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:55.218482+08
1346	XYC6560244	P168020117	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.9900017	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:55.223456+08
1347	XYC6560244	P168020117	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.9900017	GWV0000211	LDLR	A:G	A/G	2016-09-02 14:47:55.228371+08
1348	XYC6640293	P168250037	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	50	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:55.233781+08
1349	XYC6640293	P168250037	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	50	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:55.238814+08
1350	XYC6640293	P168250037	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	50	GWV0000137	MAFB	C:C	C/T	2016-09-02 14:47:55.243806+08
1351	XYC6640293	P168250037	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	50	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:55.248848+08
1352	XYC6640293	P168250037	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	50	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:55.253886+08
1353	XYC6640293	P168250037	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	50	GWV0000209	ABO	A:G	A/G	2016-09-02 14:47:55.259129+08
1354	XYC6640293	P168250037	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	50	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:55.264093+08
1355	XYC6640293	P168250037	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	50	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:55.269142+08
1356	XYC6560250	P167270187	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	28.2199993	GWV0000139	CELSR2	G:T	G/T	2016-09-02 14:47:55.273919+08
1357	XYC6560250	P167270187	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	28.2199993	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:55.278664+08
1358	XYC6560250	P167270187	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	28.2199993	GWV0000137	MAFB	T:T	C/T	2016-09-02 14:47:55.283549+08
1359	XYC6560250	P167270187	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	28.2199993	GWV0000207	HMGCR	A:A	A/T	2016-09-02 14:47:55.288519+08
1360	XYC6560250	P167270187	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	28.2199993	GWV0000208	APOC1	A:G	A/G	2016-09-02 14:47:55.293554+08
1361	XYC6560250	P167270187	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	28.2199993	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:55.298854+08
1362	XYC6560250	P167270187	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	28.2199993	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:55.303828+08
1363	XYC6560250	P167270187	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	28.2199993	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:55.308795+08
1446	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000061	MTNR1B	C:C	C/G	2016-09-02 14:47:55.713537+08
1364	XYC6560246	P168020116	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	61.0600014	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:55.313511+08
1365	XYC6560246	P168020116	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	61.0600014	GWV0000136	Intergenic	C:C	C/G	2016-09-02 14:47:55.319068+08
1366	XYC6560246	P168020116	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	61.0600014	GWV0000137	MAFB	C:C	C/T	2016-09-02 14:47:55.323923+08
1367	XYC6560246	P168020116	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	61.0600014	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:55.328886+08
1368	XYC6560246	P168020116	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	61.0600014	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:55.333626+08
1369	XYC6560246	P168020116	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	61.0600014	GWV0000209	ABO	A:A	A/G	2016-09-02 14:47:55.338494+08
1370	XYC6560246	P168020116	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	61.0600014	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:55.343625+08
1371	XYC6560246	P168020116	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	61.0600014	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:55.348528+08
1372	XYC6560249	P167270185	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.7099991	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:55.353467+08
1373	XYC6560249	P167270185	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.7099991	GWV0000136	Intergenic	C:G	C/G	2016-09-02 14:47:55.358151+08
1374	XYC6560249	P167270185	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.7099991	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:55.363071+08
1375	XYC6560249	P167270185	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.7099991	GWV0000207	HMGCR	T:T	A/T	2016-09-02 14:47:55.367917+08
1376	XYC6560249	P167270185	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.7099991	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:55.372868+08
1377	XYC6560249	P167270185	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.7099991	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:55.377715+08
1378	XYC6560249	P167270185	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.7099991	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:55.382647+08
1379	XYC6560249	P167270185	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.7099991	GWV0000211	LDLR	A:A	A/G	2016-09-02 14:47:55.387563+08
1380	XYC6560236	P168170329	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:55.392402+08
1381	XYC6560236	P168170329	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000136	Intergenic	C:G	C/G	2016-09-02 14:47:55.397088+08
1382	XYC6560236	P168170329	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000137	MAFB	T:T	C/T	2016-09-02 14:47:55.402022+08
1383	XYC6560236	P168170329	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:55.406942+08
1384	XYC6560236	P168170329	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:55.411815+08
1385	XYC6560236	P168170329	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000209	ABO	A:G	A/G	2016-09-02 14:47:55.416656+08
1386	XYC6560236	P168170329	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:55.421665+08
1387	XYC6560236	P168170329	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000211	LDLR	G:G	A/G	2016-09-02 14:47:55.426534+08
1388	XYC6560245	P168020113	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	65.4800034	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:55.431238+08
1389	XYC6560245	P168020113	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	65.4800034	GWV0000136	Intergenic	C:G	C/G	2016-09-02 14:47:55.436458+08
1390	XYC6560245	P168020113	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	65.4800034	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:55.441477+08
1391	XYC6560245	P168020113	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	65.4800034	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:55.446353+08
1392	XYC6560245	P168020113	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	65.4800034	GWV0000208	APOC1	A:G	A/G	2016-09-02 14:47:55.451078+08
1393	XYC6560245	P168020113	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	65.4800034	GWV0000209	ABO	A:G	A/G	2016-09-02 14:47:55.455971+08
1394	XYC6560245	P168020113	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	65.4800034	GWV0000210	TOMM40	C:C	C/T	2016-09-02 14:47:55.46086+08
1395	XYC6560245	P168020113	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	65.4800034	GWV0000211	LDLR	A:G	A/G	2016-09-02 14:47:55.4659+08
1396	XYC6560229	P15C280643	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000139	CELSR2	G:G	G/T	2016-09-02 14:47:55.470785+08
1397	XYC6560229	P15C280643	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000136	Intergenic	C:G	C/G	2016-09-02 14:47:55.475455+08
1398	XYC6560229	P15C280643	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000137	MAFB	C:T	C/T	2016-09-02 14:47:55.480249+08
1399	XYC6560229	P15C280643	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000207	HMGCR	A:T	A/T	2016-09-02 14:47:55.485154+08
1400	XYC6560229	P15C280643	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000208	APOC1	A:A	A/G	2016-09-02 14:47:55.490626+08
1401	XYC6560229	P15C280643	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000209	ABO	G:G	A/G	2016-09-02 14:47:55.49574+08
1402	XYC6560229	P15C280643	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000210	TOMM40	C:T	C/T	2016-09-02 14:47:55.500678+08
1403	XYC6560229	P15C280643	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000211	LDLR	G:G	A/G	2016-09-02 14:47:55.505616+08
1404	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:55.510623+08
1405	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:55.515415+08
1406	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:55.520092+08
1407	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:55.52515+08
1408	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:55.529926+08
1409	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:55.534801+08
1410	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:55.539658+08
1411	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:55.544705+08
1412	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:55.549466+08
1413	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000163	GLIS3	C:C	A/C	2016-09-02 14:47:55.554178+08
1414	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:55.558961+08
1415	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:55.56377+08
1416	XYC6560239	P168230028	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.3300018	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:55.568683+08
1417	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:55.573491+08
1418	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000157	GCK	A:G	A/G	2016-09-02 14:47:55.578462+08
1419	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:55.583241+08
1420	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:55.588018+08
1421	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:55.592889+08
1422	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:55.597764+08
1423	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:55.602481+08
1424	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000161	CRY2	C:C	A/C	2016-09-02 14:47:55.607261+08
1425	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:55.612006+08
1426	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000163	GLIS3	C:C	A/C	2016-09-02 14:47:55.616839+08
1427	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:55.621737+08
1428	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:55.626614+08
1429	XYC6560248	P167270186	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.3300018	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:55.631537+08
1430	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:55.636257+08
1431	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:55.640846+08
1432	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000158	GCKR	T:T	C/T	2016-09-02 14:47:55.645581+08
1433	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:55.650403+08
1434	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:55.655094+08
1435	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:55.660501+08
1436	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:55.665251+08
1437	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000161	CRY2	C:C	A/C	2016-09-02 14:47:55.670037+08
1438	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:55.675128+08
1439	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:55.679947+08
1440	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:55.684649+08
1441	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000165	PROX1	T:T	C/T	2016-09-02 14:47:55.689919+08
1442	XYC6560244	P168020117	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	50.7299995	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:55.694794+08
1443	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:55.699401+08
1444	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:55.703942+08
1445	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:55.708651+08
1667	XYC6560250	P167270187	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-02 14:47:56.790877+08
1447	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:55.718457+08
1448	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:55.724793+08
1449	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:55.729572+08
1450	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:55.734303+08
1451	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:55.73907+08
1452	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:55.744708+08
1453	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:55.749671+08
1454	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000165	PROX1	C:C	C/T	2016-09-02 14:47:55.754725+08
1455	XYC6640293	P168250037	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.0099983	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:55.759803+08
1456	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:55.764585+08
1457	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000157	GCK	A:G	A/G	2016-09-02 14:47:55.769156+08
1458	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000158	GCKR	C:C	C/T	2016-09-02 14:47:55.773973+08
1459	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000061	MTNR1B	G:G	C/G	2016-09-02 14:47:55.779617+08
1460	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:55.786717+08
1461	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:55.791566+08
1462	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:55.796173+08
1463	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000161	CRY2	A:C	A/C	2016-09-02 14:47:55.800967+08
1464	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:55.805796+08
1465	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000163	GLIS3	A:A	A/C	2016-09-02 14:47:55.810493+08
1466	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:55.815233+08
1467	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000165	PROX1	C:C	C/T	2016-09-02 14:47:55.819977+08
1468	XYC6560250	P167270187	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	82.8899994	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:55.824818+08
1469	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000156	G6PC2	C:T	C/T	2016-09-02 14:47:55.83006+08
1470	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000157	GCK	A:G	A/G	2016-09-02 14:47:55.834868+08
1471	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:55.839707+08
1472	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:55.844594+08
1473	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:55.849436+08
1474	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:55.85407+08
1475	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:55.859015+08
1476	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000161	CRY2	C:C	A/C	2016-09-02 14:47:55.863947+08
1477	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:55.868855+08
1478	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000163	GLIS3	C:C	A/C	2016-09-02 14:47:55.873756+08
1479	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:55.878598+08
1480	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:55.883511+08
1481	XYC6560246	P168020116	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	52.0800018	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:55.888263+08
1482	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:55.893005+08
1483	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:55.897756+08
1484	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000158	GCKR	T:T	C/T	2016-09-02 14:47:55.902459+08
1485	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:55.907165+08
1486	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:55.911945+08
1487	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:55.916994+08
1488	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:55.921826+08
1489	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:55.926647+08
1490	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:55.931477+08
1491	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:55.936588+08
1492	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:55.941741+08
1493	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:55.946728+08
1494	XYC6560249	P167270185	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.0699997	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:55.95171+08
1495	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:55.956496+08
1496	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:55.961086+08
1497	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000158	GCKR	T:T	C/T	2016-09-02 14:47:55.965848+08
1498	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000061	MTNR1B	G:G	C/G	2016-09-02 14:47:55.970713+08
1499	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:55.975501+08
1500	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:55.98015+08
1501	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000160	ADCY5	A:G	A/G	2016-09-02 14:47:55.98502+08
1502	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:55.98992+08
1503	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:55.995538+08
1504	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000163	GLIS3	C:C	A/C	2016-09-02 14:47:56.000456+08
1505	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:56.005179+08
1506	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000165	PROX1	T:T	C/T	2016-09-02 14:47:56.010256+08
1507	XYC6560236	P168170329	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	57.0900002	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:56.015251+08
1508	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:56.019886+08
1509	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000157	GCK	A:G	A/G	2016-09-02 14:47:56.024611+08
1510	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:56.030148+08
1511	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000061	MTNR1B	C:C	C/G	2016-09-02 14:47:56.034986+08
1512	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:56.039879+08
1513	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:56.044667+08
1514	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:56.049468+08
1515	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000161	CRY2	A:A	A/C	2016-09-02 14:47:56.054753+08
1516	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000162	FADS1	C:C	C/T	2016-09-02 14:47:56.059516+08
1517	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:56.064229+08
1518	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:56.068982+08
1519	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000165	PROX1	C:T	C/T	2016-09-02 14:47:56.073711+08
1520	XYC6560245	P168020113	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	58.9199982	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:56.07836+08
1521	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000156	G6PC2	C:C	C/T	2016-09-02 14:47:56.083017+08
1522	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000157	GCK	G:G	A/G	2016-09-02 14:47:56.08779+08
1523	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000158	GCKR	C:C	C/T	2016-09-02 14:47:56.092459+08
1524	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000061	MTNR1B	C:G	C/G	2016-09-02 14:47:56.097168+08
1525	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000057	TCF7L2	C:C	C/T	2016-09-02 14:47:56.101895+08
1526	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000159	ADRA2A	G:G	G/T	2016-09-02 14:47:56.106493+08
1527	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000160	ADCY5	A:A	A/G	2016-09-02 14:47:56.111251+08
1528	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000161	CRY2	A:C	A/C	2016-09-02 14:47:56.115973+08
1529	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000162	FADS1	C:T	C/T	2016-09-02 14:47:56.120798+08
1530	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000163	GLIS3	A:C	A/C	2016-09-02 14:47:56.12564+08
1531	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000164	MADD	A:A	A/T	2016-09-02 14:47:56.130425+08
1532	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000165	PROX1	T:T	C/T	2016-09-02 14:47:56.13527+08
1533	XYC6560229	P15C280643	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	61.7400017	GWV0000166	SLC2A2	T:T	A/T	2016-09-02 14:47:56.139923+08
1534	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:56.144712+08
1535	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:56.149688+08
1536	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:56.155085+08
1537	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:56.160027+08
1538	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:56.165037+08
1539	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:56.170018+08
1540	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:56.175061+08
1541	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.180025+08
1542	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:56.184987+08
1543	XYC6560239	P168230028	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.2099991	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:56.190495+08
1544	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:56.195388+08
1545	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:56.200462+08
1546	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:56.205254+08
1547	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:56.210065+08
1548	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000154	TRIB1	A:A	A/T	2016-09-02 14:47:56.214946+08
1549	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:56.219808+08
1550	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:56.224705+08
1551	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.229605+08
1552	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:56.234674+08
1553	XYC6560248	P167270186	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.9500008	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:56.239472+08
1554	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000149	GCKR	T:T	C/T	2016-09-02 14:47:56.244065+08
1555	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000145	ANGPTL3	A:C	A/C	2016-09-02 14:47:56.248986+08
1556	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:56.253888+08
1557	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:56.258838+08
1558	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000154	TRIB1	T:T	A/T	2016-09-02 14:47:56.263753+08
1559	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000158	GCKR	T:T	C/T	2016-09-02 14:47:56.268584+08
1560	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:56.273509+08
1561	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.27846+08
1562	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000212	APOE	C:T	C/T	2016-09-02 14:47:56.283424+08
1563	XYC6560244	P168020117	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	54	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:56.288558+08
1564	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:56.293534+08
1565	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:56.298176+08
1566	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000146	ZNF259	G:G	C/G	2016-09-02 14:47:56.302957+08
1567	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:56.307797+08
1568	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:56.312521+08
1569	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:56.317298+08
1570	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:56.32201+08
1571	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.326894+08
1572	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:56.331762+08
1573	XYC6640293	P168250037	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	71.6399994	GWV0000213	APOA5	C:C	C/T	2016-09-02 14:47:56.336505+08
1574	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000149	GCKR	C:C	C/T	2016-09-02 14:47:56.341101+08
1575	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:56.345877+08
1576	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:56.350735+08
1668	XYC6560250	P167270187	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.795725+08
1577	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:56.355746+08
1578	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:56.361447+08
1579	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000158	GCKR	C:C	C/T	2016-09-02 14:47:56.366249+08
1580	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:56.371037+08
1581	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.375988+08
1582	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000212	APOE	C:C	C/T	2016-09-02 14:47:56.380926+08
1583	XYC6560250	P167270187	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:56.385816+08
1584	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:56.390598+08
1585	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:56.395384+08
1586	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:56.400102+08
1587	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:56.404965+08
1588	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:56.40986+08
1589	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:56.414743+08
1590	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:56.419578+08
1591	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.42453+08
1592	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000212	APOE	C:T	C/T	2016-09-02 14:47:56.429438+08
1593	XYC6560246	P168020116	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000213	APOA5	C:T	C/T	2016-09-02 14:47:56.434067+08
1594	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000149	GCKR	T:T	C/T	2016-09-02 14:47:56.439121+08
1595	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:56.444542+08
1596	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000146	ZNF259	C:C	C/G	2016-09-02 14:47:56.449336+08
1597	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:56.454045+08
1598	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000154	TRIB1	T:T	A/T	2016-09-02 14:47:56.458908+08
1599	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000158	GCKR	T:T	C/T	2016-09-02 14:47:56.463676+08
1600	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:56.468469+08
1601	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.473231+08
1602	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:56.478048+08
1603	XYC6560249	P167270185	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	53.1300011	GWV0000213	APOA5	T:T	C/T	2016-09-02 14:47:56.482823+08
1604	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000149	GCKR	T:T	C/T	2016-09-02 14:47:56.487482+08
1605	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:56.492174+08
1606	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:56.497093+08
1607	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:56.503024+08
1608	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000154	TRIB1	A:A	A/T	2016-09-02 14:47:56.507901+08
1609	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000158	GCKR	T:T	C/T	2016-09-02 14:47:56.512783+08
1610	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000206	MLXIPL	C:T	C/T	2016-09-02 14:47:56.517596+08
1611	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.522422+08
1612	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000212	APOE	T:T	C/T	2016-09-02 14:47:56.527267+08
1613	XYC6560236	P168170329	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000213	APOA5	C:C	C/T	2016-09-02 14:47:56.532022+08
1614	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000149	GCKR	C:T	C/T	2016-09-02 14:47:56.536823+08
1615	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:56.541639+08
1616	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:56.546621+08
1617	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000148	FADS1	C:C	C/T	2016-09-02 14:47:56.55157+08
1618	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000154	TRIB1	A:T	A/T	2016-09-02 14:47:56.556485+08
1619	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000158	GCKR	C:T	C/T	2016-09-02 14:47:56.561249+08
1620	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000206	MLXIPL	C:C	C/T	2016-09-02 14:47:56.566096+08
1621	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.571033+08
1622	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000212	APOE	C:T	C/T	2016-09-02 14:47:56.576018+08
1623	XYC6560245	P168020113	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	62.8199997	GWV0000213	APOA5	C:T	C/T	2016-09-02 14:47:56.580852+08
1624	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000149	GCKR	C:C	C/T	2016-09-02 14:47:56.585643+08
1625	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000145	ANGPTL3	A:A	A/C	2016-09-02 14:47:56.590458+08
1626	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000146	ZNF259	C:G	C/G	2016-09-02 14:47:56.595303+08
1627	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000148	FADS1	C:T	C/T	2016-09-02 14:47:56.600228+08
1628	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000154	TRIB1	A:A	A/T	2016-09-02 14:47:56.605092+08
1629	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000158	GCKR	C:C	C/T	2016-09-02 14:47:56.609962+08
1630	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000206	MLXIPL	C:T	C/T	2016-09-02 14:47:56.614844+08
1631	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.619745+08
1632	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000212	APOE	C:T	C/T	2016-09-02 14:47:56.624706+08
1633	XYC6560229	P15C280643	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	46.5600014	GWV0000213	APOA5	C:T	C/T	2016-09-02 14:47:56.62954+08
1634	XYC6560239	P168230028	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-09-02 14:47:56.63439+08
1635	XYC6560248	P167270186	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-02 14:47:56.639005+08
1636	XYC6560244	P168020117	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-09-02 14:47:56.643733+08
1637	XYC6640293	P168250037	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-09-02 14:47:56.648431+08
1638	XYC6560250	P167270187	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-09-02 14:47:56.653032+08
1639	XYC6560246	P168020116	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-09-02 14:47:56.657828+08
1640	XYC6560249	P167270185	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-09-02 14:47:56.662462+08
1641	XYC6560236	P168170329	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-02 14:47:56.667143+08
1642	XYC6560245	P168020113	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-02 14:47:56.671857+08
1643	XYC6560229	P15C280643	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-02 14:47:56.676656+08
1644	XYC6560239	P168230028	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-09-02 14:47:56.681321+08
1645	XYC6560248	P167270186	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:C	C/T	2016-09-02 14:47:56.686163+08
1646	XYC6560244	P168020117	HealthWise	运动效果	最大吸氧量	较低	genotype_lookup	\N	GWV0000215	PPARGC1A	T:T	C/T	2016-09-02 14:47:56.691003+08
1647	XYC6640293	P168250037	HealthWise	运动效果	最大吸氧量	较低	genotype_lookup	\N	GWV0000215	PPARGC1A	T:T	C/T	2016-09-02 14:47:56.695557+08
1648	XYC6560250	P167270187	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-09-02 14:47:56.700046+08
1649	XYC6560246	P168020116	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-09-02 14:47:56.704692+08
1650	XYC6560249	P167270185	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:C	C/T	2016-09-02 14:47:56.709222+08
1651	XYC6560236	P168170329	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-09-02 14:47:56.713845+08
1652	XYC6560245	P168020113	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:C	C/T	2016-09-02 14:47:56.718337+08
1653	XYC6560229	P15C280643	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:C	C/T	2016-09-02 14:47:56.72284+08
1654	XYC6560239	P168230028	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:56.727794+08
1655	XYC6560239	P168230028	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.732669+08
1656	XYC6560239	P168230028	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.737458+08
1657	XYC6560248	P167270186	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:56.74214+08
1658	XYC6560248	P167270186	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.746866+08
1659	XYC6560248	P167270186	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.751694+08
1660	XYC6560244	P168020117	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:56.75674+08
1661	XYC6560244	P168020117	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-02 14:47:56.761479+08
1662	XYC6560244	P168020117	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.766231+08
1663	XYC6640293	P168250037	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:56.770971+08
1664	XYC6640293	P168250037	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.775689+08
1665	XYC6640293	P168250037	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.78097+08
1666	XYC6560250	P167270187	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:56.786085+08
1669	XYC6560246	P168020116	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:56.800474+08
1670	XYC6560246	P168020116	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.805372+08
1671	XYC6560246	P168020116	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.810071+08
1672	XYC6560249	P167270185	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:56.814778+08
1673	XYC6560249	P167270185	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.820093+08
1674	XYC6560249	P167270185	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.824902+08
1675	XYC6560236	P168170329	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:56.829762+08
1676	XYC6560236	P168170329	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.83454+08
1677	XYC6560236	P168170329	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.839255+08
1678	XYC6560245	P168020113	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:56.844511+08
1679	XYC6560245	P168020113	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-02 14:47:56.84927+08
1680	XYC6560245	P168020113	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.853989+08
1681	XYC6560229	P15C280643	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:56.858714+08
1682	XYC6560229	P15C280643	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-02 14:47:56.863475+08
1683	XYC6560229	P15C280643	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.868148+08
1684	XYC6560239	P168230028	HealthWise	运动效果	运动减脂效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.872987+08
1685	XYC6560248	P167270186	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.87753+08
1686	XYC6560244	P168020117	HealthWise	运动效果	运动减脂效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.881957+08
1687	XYC6640293	P168250037	HealthWise	运动效果	运动减脂效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.886448+08
1688	XYC6560250	P167270187	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.890945+08
1689	XYC6560246	P168020116	HealthWise	运动效果	运动减脂效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.895589+08
1690	XYC6560249	P167270185	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.900073+08
1691	XYC6560236	P168170329	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.904672+08
1692	XYC6560245	P168020113	HealthWise	运动效果	运动减脂效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-02 14:47:56.909762+08
1693	XYC6560229	P15C280643	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-02 14:47:56.914261+08
1694	XYC6560239	P168230028	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.918923+08
1695	XYC6560248	P167270186	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.923532+08
1696	XYC6560244	P168020117	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-02 14:47:56.927979+08
1697	XYC6640293	P168250037	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.932612+08
1698	XYC6560250	P167270187	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-02 14:47:56.937554+08
1699	XYC6560246	P168020116	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.942129+08
1700	XYC6560249	P167270185	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.946954+08
1701	XYC6560236	P168170329	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-02 14:47:56.951486+08
1702	XYC6560245	P168020113	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-02 14:47:56.956095+08
1703	XYC6560229	P15C280643	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-02 14:47:56.961801+08
1704	XYC6560239	P168230028	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-02 14:47:56.966435+08
1705	XYC6560248	P167270186	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-02 14:47:56.970998+08
1706	XYC6560244	P168020117	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-09-02 14:47:56.975696+08
1707	XYC6640293	P168250037	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-02 14:47:56.980363+08
1708	XYC6560250	P167270187	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-09-02 14:47:56.984975+08
1709	XYC6560246	P168020116	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-09-02 14:47:56.989994+08
1710	XYC6560249	P167270185	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-02 14:47:56.99469+08
1711	XYC6560236	P168170329	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-09-02 14:47:56.999263+08
1712	XYC6560245	P168020113	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-09-02 14:47:57.003918+08
1713	XYC6560229	P15C280643	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-02 14:47:57.008512+08
1714	XYC6560239	P168230028	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:57.01303+08
1715	XYC6560248	P167270186	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:57.017754+08
1716	XYC6560244	P168020117	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:57.022418+08
1717	XYC6640293	P168250037	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:57.027027+08
1718	XYC6560250	P167270187	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:57.031894+08
1719	XYC6560246	P168020116	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:57.036858+08
1720	XYC6560249	P167270185	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:57.041641+08
1721	XYC6560236	P168170329	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:57.046232+08
1722	XYC6560245	P168020113	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-02 14:47:57.050823+08
1723	XYC6560229	P15C280643	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-02 14:47:57.055428+08
1724	XYC6560239	P168230028	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-02 14:47:57.060072+08
1725	XYC6560248	P167270186	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:A	A/G	2016-09-02 14:47:57.064724+08
1726	XYC6560244	P168020117	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-02 14:47:57.069614+08
1727	XYC6640293	P168250037	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:G	A/G	2016-09-02 14:47:57.074143+08
1728	XYC6560250	P167270187	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:G	A/G	2016-09-02 14:47:57.078801+08
1729	XYC6560246	P168020116	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:G	A/G	2016-09-02 14:47:57.083456+08
1730	XYC6560249	P167270185	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-02 14:47:57.088076+08
1731	XYC6560236	P168170329	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-02 14:47:57.092801+08
1732	XYC6560245	P168020113	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-02 14:47:57.097614+08
1733	XYC6560229	P15C280643	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-02 14:47:57.10224+08
1734	XYC6560239	P168230028	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:G	C/G	2016-09-02 14:47:57.106856+08
1735	XYC6560248	P167270186	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-09-02 14:47:57.111542+08
1736	XYC6560244	P168020117	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:G	C/G	2016-09-02 14:47:57.116159+08
1737	XYC6640293	P168250037	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:G	C/G	2016-09-02 14:47:57.120867+08
1738	XYC6560250	P167270187	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:C	C/G	2016-09-02 14:47:57.125687+08
1739	XYC6560246	P168020116	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-09-02 14:47:57.130502+08
1740	XYC6560249	P167270185	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:G	C/G	2016-09-02 14:47:57.135059+08
1741	XYC6560236	P168170329	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:G	C/G	2016-09-02 14:47:57.139787+08
1742	XYC6560245	P168020113	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:G	C/G	2016-09-02 14:47:57.144427+08
1743	XYC6560229	P15C280643	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:C	C/G	2016-09-02 14:47:57.149241+08
1744	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:34:57.284021+08
1745	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000136	Intergenic	G:G	C/G	2016-09-08 10:34:57.291696+08
1746	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-08 10:34:57.296455+08
1747	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-08 10:34:57.30092+08
1748	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000208	APOC1	A:G	A/G	2016-09-08 10:34:57.305534+08
1749	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000209	ABO	A:A	A/G	2016-09-08 10:34:57.31014+08
1750	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-08 10:34:57.315026+08
1751	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:34:57.319637+08
1752	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-08 10:34:57.324286+08
1754	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000204	CETP	A:C	A/C	2016-09-08 10:34:57.340794+08
1756	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:34:57.35043+08
1760	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-08 10:34:57.369805+08
1761	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000157	GCK	A:G	A/G	2016-09-08 10:34:57.37463+08
1763	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-08 10:34:57.384165+08
1764	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:34:57.388947+08
1755	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:34:57.3456+08
1762	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:34:57.379483+08
1759	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:34:57.364922+08
1758	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000205	LPL	C:G	C/G	2016-09-08 10:34:57.359994+08
1757	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:57.355166+08
1765	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-08 10:34:57.393692+08
1766	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-08 10:34:57.399715+08
1767	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000161	CRY2	A:C	A/C	2016-09-08 10:34:57.404521+08
1768	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-08 10:34:57.40928+08
1769	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000163	GLIS3	C:C	A/C	2016-09-08 10:34:57.41399+08
1770	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-08 10:34:57.418822+08
1771	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-08 10:34:57.423637+08
1772	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-08 10:34:57.428931+08
1773	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000149	GCKR	T:T	C/T	2016-09-08 10:34:57.433786+08
1774	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-08 10:34:57.438621+08
1753	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:34:57.335812+08
1775	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000154	TRIB1	T:T	A/T	2016-09-08 10:34:57.455853+08
1776	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-09-08 10:34:57.476466+08
1777	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:34:57.481086+08
1780	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-08 10:34:57.495406+08
1781	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-08 10:34:57.500153+08
1782	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-08 10:34:57.510164+08
1783	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-08 10:34:57.515022+08
1779	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-08 10:34:57.490564+08
1778	XYC6560232	P167291284	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:34:57.485875+08
1784	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:34:57.530135+08
1785	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:G	C/G	2016-09-08 10:34:57.5353+08
1786	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000137	MAFB	T:T	C/T	2016-09-08 10:34:57.53993+08
1787	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:A	A/T	2016-09-08 10:34:57.544381+08
1788	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-08 10:34:57.548879+08
1789	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000209	ABO	A:A	A/G	2016-09-08 10:34:57.553368+08
1790	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-08 10:34:57.557799+08
1791	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:34:57.562263+08
1792	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:T	C/T	2016-09-08 10:34:57.566874+08
1794	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000204	CETP	A:C	A/C	2016-09-08 10:34:57.57655+08
1796	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000170	GALNT2	A:G	A/G	2016-09-08 10:34:57.586247+08
1800	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-08 10:34:57.605468+08
1801	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-08 10:34:57.610274+08
1803	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:C	C/G	2016-09-08 10:34:57.619846+08
1804	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:34:57.624482+08
1805	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-08 10:34:57.62906+08
1806	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-08 10:34:57.633743+08
1807	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000161	CRY2	A:C	A/C	2016-09-08 10:34:57.638511+08
1808	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-08 10:34:57.64327+08
1809	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-08 10:34:57.648066+08
1793	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:G	C/G	2016-09-08 10:34:57.571429+08
1795	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:34:57.581217+08
1802	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000158	GCKR	C:C	C/T	2016-09-08 10:34:57.615109+08
1799	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:34:57.600733+08
1798	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:57.595913+08
1797	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:57.591061+08
1810	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-08 10:34:57.652972+08
1811	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-08 10:34:57.657918+08
1812	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-08 10:34:57.662846+08
1813	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000149	GCKR	C:C	C/T	2016-09-08 10:34:57.668368+08
1814	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-08 10:34:57.67308+08
1815	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-09-08 10:34:57.688437+08
1816	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-09-08 10:34:57.709149+08
1817	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000213	APOA5	C:T	C/T	2016-09-08 10:34:57.714014+08
1820	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-08 10:34:57.728401+08
1821	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-09-08 10:34:57.733147+08
1822	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-08 10:34:57.743165+08
1823	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000050	FTO	A:A	A/T	2016-09-08 10:34:57.747956+08
1819	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-08 10:34:57.723559+08
1818	XYC6560231	P168120026	HealthWise	饮食类型	匹配饮食	低脂饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:34:57.718745+08
1824	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:34:57.762969+08
1825	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-08 10:34:57.768368+08
1826	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:C	C/T	2016-09-08 10:34:57.773+08
1827	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-08 10:34:57.777635+08
1828	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-08 10:34:57.782723+08
1829	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-08 10:34:57.787337+08
1830	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-08 10:34:57.791895+08
1831	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:34:57.796483+08
1832	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:T	C/T	2016-09-08 10:34:57.801034+08
1834	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	A:C	A/C	2016-09-08 10:34:57.810532+08
1836	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:34:57.820041+08
1840	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-08 10:34:57.840402+08
1841	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-08 10:34:57.844971+08
1843	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-08 10:34:57.854409+08
1844	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:34:57.858984+08
1845	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:T	G/T	2016-09-08 10:34:57.863524+08
1846	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-08 10:34:57.868239+08
1847	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-08 10:34:57.872963+08
1848	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	T:T	C/T	2016-09-08 10:34:57.877745+08
1849	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:A	A/C	2016-09-08 10:34:57.882549+08
1850	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-08 10:34:57.887331+08
1851	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-08 10:34:57.892149+08
1852	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-08 10:34:57.896955+08
1853	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-09-08 10:34:57.901597+08
1854	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:C	A/C	2016-09-08 10:34:57.906282+08
1833	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:34:57.805797+08
1835	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	T:T	C/T	2016-09-08 10:34:57.815336+08
1855	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	T:T	A/T	2016-09-08 10:34:57.922492+08
1842	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:34:57.849672+08
1839	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:34:57.835471+08
1838	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:57.830401+08
1856	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-09-08 10:34:57.943117+08
1837	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:57.825598+08
1857	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:34:57.947952+08
1860	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-08 10:34:57.962605+08
1861	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-09-08 10:34:57.967455+08
1862	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-08 10:34:57.977542+08
1863	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-08 10:34:57.982345+08
1859	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-08 10:34:57.9577+08
1858	XYC6560247	P168020114	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:34:57.952872+08
1864	XYC6560232	P167291284	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:34:57.997308+08
1865	XYC6560231	P168120026	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:34:58.001795+08
1866	XYC6560247	P168020114	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	平均风险	genotype_lookup	\N	GWV0000148	FADS1	T:T	C/T	2016-09-08 10:34:58.006441+08
1867	XYC6560232	P167291284	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:34:58.010906+08
1868	XYC6560232	P167291284	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-08 10:34:58.0157+08
1869	XYC6560231	P168120026	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:34:58.020411+08
1870	XYC6560231	P168120026	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-08 10:34:58.025731+08
1871	XYC6560247	P168020114	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:34:58.030414+08
1872	XYC6560247	P168020114	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-08 10:34:58.035861+08
1873	XYC6560232	P167291284	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:34:58.040619+08
1874	XYC6560231	P168120026	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:34:58.045142+08
1875	XYC6560247	P168020114	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:34:58.049783+08
1876	XYC6560232	P167291284	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000182	C3	G:G	A/G	2016-09-08 10:34:58.054468+08
1877	XYC6560232	P167291284	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000183	ARMS2	G:T	G/T	2016-09-08 10:34:58.05943+08
1878	XYC6560232	P167291284	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000184	CFH	A:G	A/G	2016-09-08 10:34:58.064168+08
1879	XYC6560232	P167291284	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000185	C2	G:G	G/T	2016-09-08 10:34:58.068987+08
1880	XYC6560231	P168120026	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000182	C3	G:G	A/G	2016-09-08 10:34:58.073753+08
1881	XYC6560231	P168120026	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000183	ARMS2	G:G	G/T	2016-09-08 10:34:58.078366+08
1882	XYC6560231	P168120026	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000184	CFH	G:G	A/G	2016-09-08 10:34:58.083032+08
1883	XYC6560231	P168120026	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000185	C2	G:G	G/T	2016-09-08 10:34:58.088127+08
1884	XYC6560247	P168020114	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000182	C3	G:G	A/G	2016-09-08 10:34:58.092924+08
1885	XYC6560247	P168020114	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000183	ARMS2	G:G	G/T	2016-09-08 10:34:58.097617+08
1886	XYC6560247	P168020114	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000184	CFH	A:G	A/G	2016-09-08 10:34:58.102451+08
1887	XYC6560247	P168020114	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000185	C2	G:G	G/T	2016-09-08 10:34:58.107143+08
1888	XYC6560232	P167291284	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.379999995	GWV0000186	BCAT1	A:C	A/C	2016-09-08 10:34:58.111843+08
1889	XYC6560232	P167291284	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.379999995	GWV0000187	FGF5	A:A	A/T	2016-09-08 10:34:58.116776+08
1890	XYC6560232	P167291284	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.379999995	GWV0000188	PLEKHA7	C:C	C/T	2016-09-08 10:34:58.121418+08
1891	XYC6560232	P167291284	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.379999995	GWV0000189	ATP2B1	A:G	A/G	2016-09-08 10:34:58.126033+08
1892	XYC6560232	P167291284	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.379999995	GWV0000190	CSK	C:C	A/C	2016-09-08 10:34:58.130782+08
1893	XYC6560232	P167291284	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.379999995	GWV0000191	CAPZA1	A:A	A/C	2016-09-08 10:34:58.135493+08
1894	XYC6560232	P167291284	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.379999995	GWV0000192	CYP17A1	T:T	C/T	2016-09-08 10:34:58.14022+08
1895	XYC6560231	P168120026	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.36000001	GWV0000186	BCAT1	C:C	A/C	2016-09-08 10:34:58.144885+08
1896	XYC6560231	P168120026	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.36000001	GWV0000187	FGF5	A:T	A/T	2016-09-08 10:34:58.149463+08
1897	XYC6560231	P168120026	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.36000001	GWV0000188	PLEKHA7	C:T	C/T	2016-09-08 10:34:58.15406+08
1898	XYC6560231	P168120026	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.36000001	GWV0000189	ATP2B1	A:G	A/G	2016-09-08 10:34:58.158875+08
1899	XYC6560231	P168120026	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.36000001	GWV0000190	CSK	C:C	A/C	2016-09-08 10:34:58.163668+08
1900	XYC6560231	P168120026	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.36000001	GWV0000191	CAPZA1	A:C	A/C	2016-09-08 10:34:58.168477+08
1901	XYC6560231	P168120026	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.36000001	GWV0000192	CYP17A1	C:T	C/T	2016-09-08 10:34:58.173505+08
1902	XYC6560247	P168020114	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.29999995	GWV0000186	BCAT1	A:A	A/C	2016-09-08 10:34:58.178386+08
1903	XYC6560247	P168020114	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.29999995	GWV0000187	FGF5	T:T	A/T	2016-09-08 10:34:58.18328+08
1904	XYC6560247	P168020114	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.29999995	GWV0000188	PLEKHA7	C:C	C/T	2016-09-08 10:34:58.18793+08
1905	XYC6560247	P168020114	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.29999995	GWV0000189	ATP2B1	A:A	A/G	2016-09-08 10:34:58.192904+08
1906	XYC6560247	P168020114	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.29999995	GWV0000190	CSK	C:C	A/C	2016-09-08 10:34:58.197467+08
1907	XYC6560247	P168020114	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.29999995	GWV0000191	CAPZA1	A:C	A/C	2016-09-08 10:34:58.202083+08
1908	XYC6560247	P168020114	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.29999995	GWV0000192	CYP17A1	T:T	C/T	2016-09-08 10:34:58.206851+08
1909	XYC6560232	P167291284	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:34:58.211505+08
1910	XYC6560231	P168120026	HealthWise	遗传特质	酒精代谢能力	弱	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-09-08 10:34:58.216042+08
1911	XYC6560247	P168020114	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:34:58.220765+08
1912	XYC6560232	P167291284	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-08 10:34:58.225495+08
1913	XYC6560232	P167291284	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-08 10:34:58.230062+08
1914	XYC6560231	P168120026	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-09-08 10:34:58.235088+08
1915	XYC6560231	P168120026	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-08 10:34:58.239902+08
1916	XYC6560247	P168020114	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-08 10:34:58.244574+08
1917	XYC6560247	P168020114	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-08 10:34:58.249125+08
1918	XYC6560232	P167291284	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-08 10:34:58.253811+08
1919	XYC6560231	P168120026	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-08 10:34:58.258463+08
1920	XYC6560247	P168020114	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-08 10:34:58.263427+08
1921	XYC6560232	P167291284	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-08 10:34:58.268062+08
1922	XYC6560231	P168120026	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-08 10:34:58.272911+08
1923	XYC6560247	P168020114	HealthWise	遗传特质	肌肉爆发力	强	genotype_lookup	\N	GWV0000197	ACTN3	C:C	C/T	2016-09-08 10:34:58.278447+08
1924	XYC6560232	P167291284	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-08 10:34:58.283261+08
1925	XYC6560231	P168120026	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-08 10:34:58.287959+08
1926	XYC6560247	P168020114	HealthWise	遗传特质	尼古丁依赖性	强	genotype_lookup	\N	GWV0000198	CHRNA3	A:G	A/G	2016-09-08 10:34:58.29402+08
1927	XYC6560232	P167291284	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-08 10:34:58.298748+08
1928	XYC6560231	P168120026	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-08 10:34:58.303568+08
1929	XYC6560247	P168020114	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-08 10:34:58.308279+08
1930	XYC6560232	P167291284	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	C:C	A/C	2016-09-08 10:34:58.313032+08
1931	XYC6560231	P168120026	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-08 10:34:58.31779+08
1932	XYC6560247	P168020114	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-08 10:34:58.322464+08
1933	XYC6560232	P167291284	HealthWise	营养需求	维生素A水平	未知	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-08 10:34:58.327039+08
1934	XYC6560232	P167291284	HealthWise	营养需求	维生素A水平	未知	genotype_lookup	\N	GWV0000123	BCMO1	A:T	A/T	2016-09-08 10:34:58.33215+08
1935	XYC6560231	P168120026	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-08 10:34:58.33725+08
1936	XYC6560231	P168120026	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-08 10:34:58.342028+08
1937	XYC6560247	P168020114	HealthWise	营养需求	维生素A水平	未知	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-08 10:34:58.346749+08
1938	XYC6560247	P168020114	HealthWise	营养需求	维生素A水平	未知	genotype_lookup	\N	GWV0000123	BCMO1	A:T	A/T	2016-09-08 10:34:58.352295+08
1939	XYC6560232	P167291284	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-08 10:34:58.357011+08
1940	XYC6560231	P168120026	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:34:58.368005+08
1941	XYC6560247	P168020114	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-08 10:34:58.372819+08
1942	XYC6560232	P167291284	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-08 10:34:58.377961+08
1943	XYC6560231	P168120026	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-08 10:34:58.38263+08
1944	XYC6560247	P168020114	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-08 10:34:58.387437+08
1945	XYC6560232	P167291284	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-08 10:34:58.391986+08
1946	XYC6560232	P167291284	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-09-08 10:34:58.396733+08
1947	XYC6560231	P168120026	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-08 10:34:58.401546+08
1948	XYC6560231	P168120026	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-09-08 10:34:58.40627+08
1949	XYC6560247	P168020114	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-08 10:34:58.411035+08
1950	XYC6560247	P168020114	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	T:T	A/T	2016-09-08 10:34:58.416004+08
1951	XYC6560232	P167291284	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-09-08 10:34:58.420678+08
1952	XYC6560231	P168120026	HealthWise	营养需求	维生素D水平	正常	genotype_lookup	\N	GWV0000129	GC	T:T	G/T	2016-09-08 10:34:58.425466+08
1953	XYC6560247	P168020114	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-08 10:34:58.430083+08
1954	XYC6560232	P167291284	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-08 10:34:58.434767+08
1955	XYC6560231	P168120026	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-08 10:34:58.439363+08
1956	XYC6560247	P168020114	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-08 10:34:58.443985+08
1957	XYC6560232	P167291284	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-08 10:34:58.448538+08
1958	XYC6560231	P168120026	HealthWise	营养需求	叶酸水平	偏低	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:34:58.453029+08
1959	XYC6560247	P168020114	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-08 10:34:58.457726+08
1960	XYC6560232	P167291284	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-08 10:34:58.462342+08
1961	XYC6560231	P168120026	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-08 10:34:58.467005+08
1962	XYC6560247	P168020114	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-08 10:34:58.471627+08
1963	XYC6560232	P167291284	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000051	MC4R	T:T	C/T	2016-09-08 10:34:58.476348+08
1964	XYC6560232	P167291284	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000050	FTO	T:T	A/T	2016-09-08 10:34:58.481107+08
1965	XYC6560231	P168120026	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.69000006	GWV0000051	MC4R	C:T	C/T	2016-09-08 10:34:58.485893+08
1966	XYC6560231	P168120026	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.69000006	GWV0000050	FTO	A:A	A/T	2016-09-08 10:34:58.490493+08
1967	XYC6560247	P168020114	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000051	MC4R	T:T	C/T	2016-09-08 10:34:58.495079+08
1968	XYC6560247	P168020114	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000050	FTO	T:T	A/T	2016-09-08 10:34:58.499964+08
1969	XYC6560232	P167291284	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-08 10:34:58.505179+08
1970	XYC6560231	P168120026	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-08 10:34:58.509836+08
1971	XYC6560247	P168020114	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-08 10:34:58.514615+08
1972	XYC6560232	P167291284	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-08 10:34:58.519301+08
1973	XYC6560231	P168120026	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-08 10:34:58.523862+08
1974	XYC6560247	P168020114	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-08 10:34:58.528466+08
1975	XYC6560232	P167291284	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-08 10:34:58.533272+08
1976	XYC6560231	P168120026	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-08 10:34:58.538001+08
1977	XYC6560247	P168020114	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-08 10:34:58.542734+08
1978	XYC6560232	P167291284	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-08 10:34:58.547537+08
1979	XYC6560231	P168120026	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-08 10:34:58.552107+08
1980	XYC6560247	P168020114	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-08 10:34:58.556783+08
1981	XYC6560232	P167291284	HealthWise	饮食习惯	饮食偏好	正常	genotype_lookup	\N	GWV0000121	ANKK1	G:G	A/G	2016-09-08 10:34:58.561458+08
1982	XYC6560231	P168120026	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-09-08 10:34:58.566059+08
1983	XYC6560247	P168020114	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-09-08 10:34:58.570706+08
1984	XYC6560232	P167291284	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-08 10:34:58.575285+08
1985	XYC6560231	P168120026	HealthWise	饮食习惯	饱腹感	不易感知	genotype_lookup	\N	GWV0000050	FTO	A:A	A/T	2016-09-08 10:34:58.579869+08
1986	XYC6560247	P168020114	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-08 10:34:58.584883+08
1987	XYC6560232	P167291284	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-08 10:34:58.589832+08
1988	XYC6560231	P168120026	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-08 10:34:58.595066+08
1989	XYC6560247	P168020114	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-08 10:34:58.599839+08
1990	XYC6560232	P167291284	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-09-08 10:34:58.604543+08
1991	XYC6560231	P168120026	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-08 10:34:58.609143+08
1992	XYC6560247	P168020114	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-08 10:34:58.613877+08
1993	XYC6560232	P167291284	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-08 10:34:58.618538+08
1994	XYC6560231	P168120026	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-08 10:34:58.623037+08
1995	XYC6560247	P168020114	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-08 10:34:58.627747+08
1996	XYC6560232	P167291284	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	38.4599991	GWV0000167	ABCA1	C:C	C/T	2016-09-08 10:34:58.63251+08
1997	XYC6560232	P167291284	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	38.4599991	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:34:58.637263+08
1998	XYC6560232	P167291284	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	38.4599991	GWV0000204	CETP	A:C	A/C	2016-09-08 10:34:58.642075+08
1999	XYC6560232	P167291284	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	38.4599991	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:34:58.646921+08
2000	XYC6560232	P167291284	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	38.4599991	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:34:58.651749+08
2001	XYC6560232	P167291284	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	38.4599991	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:58.656875+08
2002	XYC6560232	P167291284	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	38.4599991	GWV0000205	LPL	C:G	C/G	2016-09-08 10:34:58.661818+08
2003	XYC6560232	P167291284	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	38.4599991	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:34:58.666801+08
2004	XYC6560231	P168120026	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000167	ABCA1	C:T	C/T	2016-09-08 10:34:58.671618+08
2005	XYC6560231	P168120026	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000146	ZNF259	C:G	C/G	2016-09-08 10:34:58.677242+08
2006	XYC6560231	P168120026	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000204	CETP	A:C	A/C	2016-09-08 10:34:58.682227+08
2007	XYC6560231	P168120026	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:34:58.687257+08
2008	XYC6560231	P168120026	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000170	GALNT2	A:G	A/G	2016-09-08 10:34:58.692247+08
2009	XYC6560231	P168120026	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:58.697275+08
2010	XYC6560231	P168120026	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:58.702263+08
2011	XYC6560231	P168120026	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:34:58.707254+08
2012	XYC6560247	P168020114	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	47.1199989	GWV0000167	ABCA1	C:T	C/T	2016-09-08 10:34:58.712014+08
2013	XYC6560247	P168020114	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	47.1199989	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:34:58.716878+08
2014	XYC6560247	P168020114	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	47.1199989	GWV0000204	CETP	A:C	A/C	2016-09-08 10:34:58.721656+08
2015	XYC6560247	P168020114	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	47.1199989	GWV0000148	FADS1	T:T	C/T	2016-09-08 10:34:58.726521+08
2016	XYC6560247	P168020114	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	47.1199989	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:34:58.731466+08
2017	XYC6560247	P168020114	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	47.1199989	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:58.736442+08
2018	XYC6560247	P168020114	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	47.1199989	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:58.741382+08
2019	XYC6560247	P168020114	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	47.1199989	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:34:58.746092+08
2020	XYC6560232	P167291284	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	73.1900024	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:34:58.751439+08
2021	XYC6560232	P167291284	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	73.1900024	GWV0000136	Intergenic	G:G	C/G	2016-09-08 10:34:58.75612+08
2022	XYC6560232	P167291284	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	73.1900024	GWV0000137	MAFB	C:T	C/T	2016-09-08 10:34:58.761031+08
2023	XYC6560232	P167291284	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	73.1900024	GWV0000207	HMGCR	A:T	A/T	2016-09-08 10:34:58.765993+08
2024	XYC6560232	P167291284	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	73.1900024	GWV0000208	APOC1	A:G	A/G	2016-09-08 10:34:58.771092+08
2025	XYC6560232	P167291284	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	73.1900024	GWV0000209	ABO	A:A	A/G	2016-09-08 10:34:58.776072+08
2026	XYC6560232	P167291284	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	73.1900024	GWV0000210	TOMM40	C:C	C/T	2016-09-08 10:34:58.781046+08
2027	XYC6560232	P167291284	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	73.1900024	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:34:58.786008+08
2028	XYC6560231	P168120026	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	63.8100014	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:34:58.79082+08
2029	XYC6560231	P168120026	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	63.8100014	GWV0000136	Intergenic	C:G	C/G	2016-09-08 10:34:58.795638+08
2030	XYC6560231	P168120026	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	63.8100014	GWV0000137	MAFB	T:T	C/T	2016-09-08 10:34:58.800572+08
2031	XYC6560231	P168120026	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	63.8100014	GWV0000207	HMGCR	A:A	A/T	2016-09-08 10:34:58.805492+08
2032	XYC6560231	P168120026	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	63.8100014	GWV0000208	APOC1	A:A	A/G	2016-09-08 10:34:58.810411+08
2033	XYC6560231	P168120026	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	63.8100014	GWV0000209	ABO	A:A	A/G	2016-09-08 10:34:58.815257+08
2034	XYC6560231	P168120026	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	63.8100014	GWV0000210	TOMM40	C:C	C/T	2016-09-08 10:34:58.820084+08
2035	XYC6560231	P168120026	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	63.8100014	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:34:58.825045+08
2036	XYC6560247	P168020114	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.75	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:34:58.830275+08
2037	XYC6560247	P168020114	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.75	GWV0000136	Intergenic	C:C	C/G	2016-09-08 10:34:58.835422+08
2038	XYC6560247	P168020114	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.75	GWV0000137	MAFB	C:C	C/T	2016-09-08 10:34:58.840501+08
2039	XYC6560247	P168020114	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.75	GWV0000207	HMGCR	A:T	A/T	2016-09-08 10:34:58.845482+08
2040	XYC6560247	P168020114	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.75	GWV0000208	APOC1	A:A	A/G	2016-09-08 10:34:58.850454+08
2041	XYC6560247	P168020114	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.75	GWV0000209	ABO	G:G	A/G	2016-09-08 10:34:58.855241+08
2042	XYC6560247	P168020114	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.75	GWV0000210	TOMM40	C:C	C/T	2016-09-08 10:34:58.860134+08
2043	XYC6560247	P168020114	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.75	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:34:58.865153+08
2044	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000156	G6PC2	C:C	C/T	2016-09-08 10:34:58.869986+08
2045	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000157	GCK	A:G	A/G	2016-09-08 10:34:58.874756+08
2046	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:34:58.879598+08
2047	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000061	MTNR1B	C:G	C/G	2016-09-08 10:34:58.884428+08
2048	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:34:58.889234+08
2049	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000159	ADRA2A	G:G	G/T	2016-09-08 10:34:58.893895+08
2050	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000160	ADCY5	A:A	A/G	2016-09-08 10:34:58.898639+08
2051	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000161	CRY2	A:C	A/C	2016-09-08 10:34:58.90342+08
2052	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000162	FADS1	C:T	C/T	2016-09-08 10:34:58.908143+08
2053	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000163	GLIS3	C:C	A/C	2016-09-08 10:34:58.913625+08
2054	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000164	MADD	A:A	A/T	2016-09-08 10:34:58.918612+08
2055	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000165	PROX1	C:T	C/T	2016-09-08 10:34:58.923511+08
2056	XYC6560232	P167291284	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	65.1600037	GWV0000166	SLC2A2	T:T	A/T	2016-09-08 10:34:58.928075+08
2057	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000156	G6PC2	C:C	C/T	2016-09-08 10:34:58.93288+08
2058	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000157	GCK	G:G	A/G	2016-09-08 10:34:58.937573+08
2059	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000158	GCKR	C:C	C/T	2016-09-08 10:34:58.942377+08
2060	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000061	MTNR1B	C:C	C/G	2016-09-08 10:34:58.947066+08
2061	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:34:58.951881+08
2062	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000159	ADRA2A	G:G	G/T	2016-09-08 10:34:58.956798+08
2063	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000160	ADCY5	A:A	A/G	2016-09-08 10:34:58.961664+08
2064	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000161	CRY2	A:C	A/C	2016-09-08 10:34:58.966524+08
2065	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000162	FADS1	C:T	C/T	2016-09-08 10:34:58.971107+08
2066	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000163	GLIS3	A:C	A/C	2016-09-08 10:34:58.975947+08
2067	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000164	MADD	A:A	A/T	2016-09-08 10:34:58.980753+08
2068	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000165	PROX1	C:T	C/T	2016-09-08 10:34:58.985502+08
2069	XYC6560231	P168120026	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	55.1300011	GWV0000166	SLC2A2	T:T	A/T	2016-09-08 10:34:58.990242+08
2070	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000156	G6PC2	C:C	C/T	2016-09-08 10:34:58.995926+08
2071	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000157	GCK	G:G	A/G	2016-09-08 10:34:59.000737+08
2072	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:34:59.005572+08
2073	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000061	MTNR1B	C:G	C/G	2016-09-08 10:34:59.010439+08
2074	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:34:59.015277+08
2075	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000159	ADRA2A	G:T	G/T	2016-09-08 10:34:59.020067+08
2076	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000160	ADCY5	A:A	A/G	2016-09-08 10:34:59.024872+08
2077	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000161	CRY2	A:A	A/C	2016-09-08 10:34:59.029645+08
2078	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000162	FADS1	T:T	C/T	2016-09-08 10:34:59.035094+08
2079	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000163	GLIS3	A:A	A/C	2016-09-08 10:34:59.039991+08
2080	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000164	MADD	A:A	A/T	2016-09-08 10:34:59.044812+08
2081	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000165	PROX1	C:T	C/T	2016-09-08 10:34:59.049624+08
2082	XYC6560247	P168020114	HealthWise	代谢因子	血糖水平升高遗传风险	平均风险	metabolic_disease	63.2000008	GWV0000166	SLC2A2	T:T	A/T	2016-09-08 10:34:59.054482+08
2083	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000149	GCKR	T:T	C/T	2016-09-08 10:34:59.059615+08
2084	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000145	ANGPTL3	A:A	A/C	2016-09-08 10:34:59.064615+08
2085	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:34:59.069606+08
2086	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:34:59.074583+08
2087	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000154	TRIB1	T:T	A/T	2016-09-08 10:34:59.080244+08
2088	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:34:59.085477+08
2089	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:34:59.090507+08
2090	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000205	LPL	C:G	C/G	2016-09-08 10:34:59.095435+08
2091	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000212	APOE	C:T	C/T	2016-09-08 10:34:59.100412+08
2092	XYC6560232	P167291284	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	46.8199997	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:34:59.105259+08
2093	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000149	GCKR	C:C	C/T	2016-09-08 10:34:59.110084+08
2094	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000145	ANGPTL3	A:A	A/C	2016-09-08 10:34:59.115055+08
2095	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000146	ZNF259	C:G	C/G	2016-09-08 10:34:59.120122+08
2096	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:34:59.125068+08
2097	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000154	TRIB1	A:T	A/T	2016-09-08 10:34:59.130013+08
2098	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000158	GCKR	C:C	C/T	2016-09-08 10:34:59.134946+08
2099	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:34:59.139831+08
2100	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:59.144764+08
2101	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000212	APOE	T:T	C/T	2016-09-08 10:34:59.149758+08
2102	XYC6560231	P168120026	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	48.0999985	GWV0000213	APOA5	C:T	C/T	2016-09-08 10:34:59.154668+08
2103	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000149	GCKR	C:T	C/T	2016-09-08 10:34:59.15951+08
2104	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000145	ANGPTL3	A:C	A/C	2016-09-08 10:34:59.16445+08
2105	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:34:59.16941+08
2106	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000148	FADS1	T:T	C/T	2016-09-08 10:34:59.174162+08
2107	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000154	TRIB1	T:T	A/T	2016-09-08 10:34:59.179076+08
2108	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:34:59.183981+08
2109	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:34:59.189173+08
2110	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:59.194088+08
2111	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000212	APOE	T:T	C/T	2016-09-08 10:34:59.199257+08
2112	XYC6560247	P168020114	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	37.7400017	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:34:59.204095+08
2113	XYC6560232	P167291284	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-09-08 10:34:59.20906+08
2114	XYC6560231	P168120026	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-08 10:34:59.213896+08
2115	XYC6560247	P168020114	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-08 10:34:59.218809+08
2116	XYC6560232	P167291284	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-09-08 10:34:59.22368+08
2117	XYC6560231	P168120026	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:C	C/T	2016-09-08 10:34:59.22846+08
2118	XYC6560247	P168020114	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-09-08 10:34:59.233104+08
2119	XYC6560232	P167291284	HealthWise	运动效果	耐力训练效果	非常显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:59.237873+08
2120	XYC6560232	P167291284	HealthWise	运动效果	耐力训练效果	非常显著	genotype_lookup	\N	GWV0000216	PPARD	C:C	C/T	2016-09-08 10:34:59.242607+08
2121	XYC6560232	P167291284	HealthWise	运动效果	耐力训练效果	非常显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-08 10:34:59.247648+08
2122	XYC6560231	P168120026	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:59.252439+08
2123	XYC6560231	P168120026	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-08 10:34:59.257158+08
2124	XYC6560231	P168120026	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:59.261962+08
2125	XYC6560247	P168020114	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:59.266844+08
2126	XYC6560247	P168020114	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-08 10:34:59.271592+08
2127	XYC6560247	P168020114	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:59.276412+08
2128	XYC6560232	P167291284	HealthWise	运动效果	运动减脂效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-08 10:34:59.28136+08
2129	XYC6560231	P168120026	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:59.285988+08
2130	XYC6560247	P168020114	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-08 10:34:59.290728+08
2131	XYC6560232	P167291284	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:C	C/T	2016-09-08 10:34:59.295471+08
2132	XYC6560231	P168120026	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-08 10:34:59.30005+08
2133	XYC6560247	P168020114	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-08 10:34:59.30476+08
2134	XYC6560232	P167291284	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-08 10:34:59.309497+08
2135	XYC6560231	P168120026	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	T:T	G/T	2016-09-08 10:34:59.314325+08
2136	XYC6560247	P168020114	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-08 10:34:59.319093+08
2137	XYC6560232	P167291284	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:59.323904+08
2138	XYC6560231	P168120026	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:59.328535+08
2139	XYC6560247	P168020114	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:34:59.333367+08
2140	XYC6560232	P167291284	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-08 10:34:59.338515+08
2141	XYC6560231	P168120026	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:A	A/G	2016-09-08 10:34:59.343232+08
2142	XYC6560247	P168020114	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-08 10:34:59.347908+08
2143	XYC6560232	P167291284	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-09-08 10:34:59.352638+08
2144	XYC6560231	P168120026	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:C	C/G	2016-09-08 10:34:59.3574+08
2145	XYC6560247	P168020114	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:G	C/G	2016-09-08 10:34:59.362224+08
2146	XYC6560251	P167290010	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	72.1200027	GWV0000167	ABCA1	C:T	C/T	2016-09-08 10:35:47.012782+08
2147	XYC6560251	P167290010	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	72.1200027	GWV0000146	ZNF259	C:G	C/G	2016-09-08 10:35:47.018805+08
2148	XYC6560251	P167290010	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	72.1200027	GWV0000204	CETP	C:C	A/C	2016-09-08 10:35:47.02371+08
2149	XYC6560251	P167290010	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	72.1200027	GWV0000148	FADS1	C:C	C/T	2016-09-08 10:35:47.028447+08
2150	XYC6560251	P167290010	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	72.1200027	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:35:47.033254+08
2151	XYC6560251	P167290010	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	72.1200027	GWV0000179	LIPC	C:T	C/T	2016-09-08 10:35:47.038065+08
2152	XYC6560251	P167290010	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	72.1200027	GWV0000205	LPL	C:C	C/G	2016-09-08 10:35:47.042883+08
2153	XYC6560251	P167290010	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	72.1200027	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.047727+08
2154	XYC6560238	P168220014	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000167	ABCA1	C:C	C/T	2016-09-08 10:35:47.052373+08
2155	XYC6560238	P168220014	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.057535+08
2156	XYC6560238	P168220014	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000204	CETP	A:C	A/C	2016-09-08 10:35:47.062275+08
2157	XYC6560238	P168220014	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000148	FADS1	C:C	C/T	2016-09-08 10:35:47.067101+08
2158	XYC6560238	P168220014	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:35:47.072122+08
2159	XYC6560238	P168220014	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000179	LIPC	T:T	C/T	2016-09-08 10:35:47.077104+08
2160	XYC6560238	P168220014	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000205	LPL	C:C	C/G	2016-09-08 10:35:47.08208+08
2161	XYC6560238	P168220014	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.087076+08
2162	XYC6560237	P168190032	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	55.7700005	GWV0000167	ABCA1	C:T	C/T	2016-09-08 10:35:47.092353+08
2163	XYC6560237	P168190032	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	55.7700005	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.096999+08
2164	XYC6560237	P168190032	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	55.7700005	GWV0000204	CETP	C:C	A/C	2016-09-08 10:35:47.101804+08
2165	XYC6560237	P168190032	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	55.7700005	GWV0000148	FADS1	C:C	C/T	2016-09-08 10:35:47.106646+08
2166	XYC6560237	P168190032	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	55.7700005	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:35:47.111553+08
2167	XYC6560237	P168190032	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	55.7700005	GWV0000179	LIPC	C:T	C/T	2016-09-08 10:35:47.11666+08
2168	XYC6560237	P168190032	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	55.7700005	GWV0000205	LPL	C:C	C/G	2016-09-08 10:35:47.12207+08
2169	XYC6560237	P168190032	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	55.7700005	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.126973+08
2170	XYC6560281	P167230072	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000167	ABCA1	C:C	C/T	2016-09-08 10:35:47.131992+08
2171	XYC6560281	P167230072	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.137588+08
2172	XYC6560281	P167230072	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000204	CETP	C:C	A/C	2016-09-08 10:35:47.142498+08
2173	XYC6560281	P167230072	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000148	FADS1	T:T	C/T	2016-09-08 10:35:47.147413+08
2174	XYC6560281	P167230072	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:35:47.152304+08
2175	XYC6560281	P167230072	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000179	LIPC	T:T	C/T	2016-09-08 10:35:47.157107+08
2176	XYC6560281	P167230072	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000205	LPL	C:G	C/G	2016-09-08 10:35:47.162007+08
2177	XYC6560281	P167230072	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.166907+08
2178	XYC6560233	P168160792	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	44.2299995	GWV0000167	ABCA1	C:C	C/T	2016-09-08 10:35:47.171735+08
2179	XYC6560233	P168160792	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	44.2299995	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.176398+08
2180	XYC6560233	P168160792	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	44.2299995	GWV0000204	CETP	C:C	A/C	2016-09-08 10:35:47.181099+08
2181	XYC6560233	P168160792	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	44.2299995	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:35:47.185799+08
2182	XYC6560233	P168160792	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	44.2299995	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:35:47.190653+08
2183	XYC6560233	P168160792	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	44.2299995	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:35:47.195477+08
2184	XYC6560233	P168160792	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	44.2299995	GWV0000205	LPL	G:G	C/G	2016-09-08 10:35:47.20025+08
2185	XYC6560233	P168160792	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	44.2299995	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.205052+08
2186	XYC6560234	P168160788	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000167	ABCA1	C:C	C/T	2016-09-08 10:35:47.209735+08
2187	XYC6560234	P168160788	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.214332+08
2188	XYC6560234	P168160788	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000204	CETP	C:C	A/C	2016-09-08 10:35:47.219239+08
2189	XYC6560234	P168160788	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:35:47.224604+08
2190	XYC6560234	P168160788	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:35:47.229466+08
2191	XYC6560234	P168160788	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000179	LIPC	T:T	C/T	2016-09-08 10:35:47.234529+08
2192	XYC6560234	P168160788	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000205	LPL	C:G	C/G	2016-09-08 10:35:47.239555+08
2193	XYC6560234	P168160788	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	35.5800018	GWV0000206	MLXIPL	C:T	C/T	2016-09-08 10:35:47.244512+08
2194	XYC6560235	P168170068	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	51.9199982	GWV0000167	ABCA1	C:C	C/T	2016-09-08 10:35:47.24903+08
2195	XYC6560235	P168170068	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	51.9199982	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.253741+08
2196	XYC6560235	P168170068	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	51.9199982	GWV0000204	CETP	C:C	A/C	2016-09-08 10:35:47.25856+08
2197	XYC6560235	P168170068	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	51.9199982	GWV0000148	FADS1	C:C	C/T	2016-09-08 10:35:47.263455+08
2198	XYC6560235	P168170068	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	51.9199982	GWV0000170	GALNT2	G:G	A/G	2016-09-08 10:35:47.268458+08
2199	XYC6560235	P168170068	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	51.9199982	GWV0000179	LIPC	C:C	C/T	2016-09-08 10:35:47.273427+08
2200	XYC6560235	P168170068	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	51.9199982	GWV0000205	LPL	C:C	C/G	2016-09-08 10:35:47.278171+08
2201	XYC6560235	P168170068	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	51.9199982	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.283012+08
2202	XYC6560251	P167290010	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	18.7700005	GWV0000139	CELSR2	G:T	G/T	2016-09-08 10:35:47.287694+08
2203	XYC6560251	P167290010	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	18.7700005	GWV0000136	Intergenic	C:C	C/G	2016-09-08 10:35:47.292432+08
2204	XYC6560251	P167290010	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	18.7700005	GWV0000137	MAFB	C:C	C/T	2016-09-08 10:35:47.29718+08
2205	XYC6560251	P167290010	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	18.7700005	GWV0000207	HMGCR	A:A	A/T	2016-09-08 10:35:47.302061+08
2206	XYC6560251	P167290010	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	18.7700005	GWV0000208	APOC1	A:A	A/G	2016-09-08 10:35:47.306898+08
2207	XYC6560251	P167290010	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	18.7700005	GWV0000209	ABO	G:G	A/G	2016-09-08 10:35:47.312309+08
2208	XYC6560251	P167290010	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	18.7700005	GWV0000210	TOMM40	T:T	C/T	2016-09-08 10:35:47.317134+08
2334	XYC6560281	P167230072	CardioWise	风险评估	心房颤动	高风险	risk_estimation_bin	2.21000004	GWV0000223	PITX2	T:T	C/T	2016-09-08 10:35:47.941471+08
2209	XYC6560251	P167290010	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低风险	metabolic_disease	18.7700005	GWV0000211	LDLR	A:A	A/G	2016-09-08 10:35:47.322004+08
2210	XYC6560238	P168220014	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.0600014	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:35:47.326954+08
2211	XYC6560238	P168220014	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.0600014	GWV0000136	Intergenic	G:G	C/G	2016-09-08 10:35:47.331654+08
2212	XYC6560238	P168220014	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.0600014	GWV0000137	MAFB	T:T	C/T	2016-09-08 10:35:47.337059+08
2213	XYC6560238	P168220014	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.0600014	GWV0000207	HMGCR	A:A	A/T	2016-09-08 10:35:47.342549+08
2214	XYC6560238	P168220014	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.0600014	GWV0000208	APOC1	A:G	A/G	2016-09-08 10:35:47.347228+08
2215	XYC6560238	P168220014	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.0600014	GWV0000209	ABO	A:G	A/G	2016-09-08 10:35:47.352078+08
2216	XYC6560238	P168220014	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.0600014	GWV0000210	TOMM40	C:C	C/T	2016-09-08 10:35:47.357315+08
2217	XYC6560238	P168220014	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.0600014	GWV0000211	LDLR	A:A	A/G	2016-09-08 10:35:47.362452+08
2218	XYC6560237	P168190032	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.0400009	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:35:47.367249+08
2219	XYC6560237	P168190032	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.0400009	GWV0000136	Intergenic	C:C	C/G	2016-09-08 10:35:47.371939+08
2220	XYC6560237	P168190032	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.0400009	GWV0000137	MAFB	T:T	C/T	2016-09-08 10:35:47.376765+08
2221	XYC6560237	P168190032	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.0400009	GWV0000207	HMGCR	A:A	A/T	2016-09-08 10:35:47.38163+08
2222	XYC6560237	P168190032	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.0400009	GWV0000208	APOC1	A:A	A/G	2016-09-08 10:35:47.386493+08
2223	XYC6560237	P168190032	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.0400009	GWV0000209	ABO	G:G	A/G	2016-09-08 10:35:47.391156+08
2224	XYC6560237	P168190032	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.0400009	GWV0000210	TOMM40	C:C	C/T	2016-09-08 10:35:47.3959+08
2225	XYC6560237	P168190032	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	45.0400009	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:35:47.400764+08
2226	XYC6560281	P167230072	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:35:47.405461+08
2227	XYC6560281	P167230072	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000136	Intergenic	C:G	C/G	2016-09-08 10:35:47.410046+08
2228	XYC6560281	P167230072	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000137	MAFB	C:T	C/T	2016-09-08 10:35:47.415068+08
2229	XYC6560281	P167230072	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000207	HMGCR	A:T	A/T	2016-09-08 10:35:47.420034+08
2230	XYC6560281	P167230072	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000208	APOC1	A:A	A/G	2016-09-08 10:35:47.424954+08
2231	XYC6560281	P167230072	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000209	ABO	G:G	A/G	2016-09-08 10:35:47.429959+08
2232	XYC6560281	P167230072	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000210	TOMM40	C:T	C/T	2016-09-08 10:35:47.434785+08
2233	XYC6560281	P167230072	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	48.3199997	GWV0000211	LDLR	G:G	A/G	2016-09-08 10:35:47.439634+08
2234	XYC6560233	P168160792	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	58.3800011	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:35:47.444307+08
2235	XYC6560233	P168160792	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	58.3800011	GWV0000136	Intergenic	C:G	C/G	2016-09-08 10:35:47.448815+08
2236	XYC6560233	P168160792	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	58.3800011	GWV0000137	MAFB	C:T	C/T	2016-09-08 10:35:47.453611+08
2237	XYC6560233	P168160792	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	58.3800011	GWV0000207	HMGCR	A:A	A/T	2016-09-08 10:35:47.458397+08
2238	XYC6560233	P168160792	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	58.3800011	GWV0000208	APOC1	A:A	A/G	2016-09-08 10:35:47.463454+08
2239	XYC6560233	P168160792	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	58.3800011	GWV0000209	ABO	A:A	A/G	2016-09-08 10:35:47.468084+08
2240	XYC6560233	P168160792	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	58.3800011	GWV0000210	TOMM40	C:T	C/T	2016-09-08 10:35:47.47292+08
2241	XYC6560233	P168160792	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	58.3800011	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:35:47.489704+08
2242	XYC6560234	P168160788	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	62.7299995	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:35:47.495466+08
2243	XYC6560234	P168160788	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	62.7299995	GWV0000136	Intergenic	C:G	C/G	2016-09-08 10:35:47.500049+08
2244	XYC6560234	P168160788	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	62.7299995	GWV0000137	MAFB	C:T	C/T	2016-09-08 10:35:47.50561+08
2245	XYC6560234	P168160788	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	62.7299995	GWV0000207	HMGCR	T:T	A/T	2016-09-08 10:35:47.510511+08
2246	XYC6560234	P168160788	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	62.7299995	GWV0000208	APOC1	A:G	A/G	2016-09-08 10:35:47.515529+08
2247	XYC6560234	P168160788	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	62.7299995	GWV0000209	ABO	A:G	A/G	2016-09-08 10:35:47.520472+08
2248	XYC6560234	P168160788	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	62.7299995	GWV0000210	TOMM40	C:T	C/T	2016-09-08 10:35:47.525371+08
2249	XYC6560234	P168160788	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	62.7299995	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:35:47.530273+08
2250	XYC6560235	P168170068	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.0800018	GWV0000139	CELSR2	G:G	G/T	2016-09-08 10:35:47.535426+08
2251	XYC6560235	P168170068	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.0800018	GWV0000136	Intergenic	C:G	C/G	2016-09-08 10:35:47.540013+08
2252	XYC6560235	P168170068	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.0800018	GWV0000137	MAFB	C:T	C/T	2016-09-08 10:35:47.544819+08
2253	XYC6560235	P168170068	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.0800018	GWV0000207	HMGCR	T:T	A/T	2016-09-08 10:35:47.549597+08
2254	XYC6560235	P168170068	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.0800018	GWV0000208	APOC1	A:A	A/G	2016-09-08 10:35:47.554438+08
2255	XYC6560235	P168170068	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.0800018	GWV0000209	ABO	G:G	A/G	2016-09-08 10:35:47.559156+08
2256	XYC6560235	P168170068	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.0800018	GWV0000210	TOMM40	C:C	C/T	2016-09-08 10:35:47.564282+08
2257	XYC6560235	P168170068	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	53.0800018	GWV0000211	LDLR	A:G	A/G	2016-09-08 10:35:47.569261+08
2258	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000149	GCKR	C:T	C/T	2016-09-08 10:35:47.574047+08
2259	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000145	ANGPTL3	A:C	A/C	2016-09-08 10:35:47.578816+08
2260	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000146	ZNF259	C:G	C/G	2016-09-08 10:35:47.583542+08
2261	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000148	FADS1	C:C	C/T	2016-09-08 10:35:47.588781+08
2262	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000154	TRIB1	A:T	A/T	2016-09-08 10:35:47.593795+08
2263	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:35:47.598592+08
2264	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.603438+08
2265	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000205	LPL	C:C	C/G	2016-09-08 10:35:47.608052+08
2266	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000212	APOE	C:C	C/T	2016-09-08 10:35:47.613163+08
2267	XYC6560251	P167290010	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000213	APOA5	C:T	C/T	2016-09-08 10:35:47.618048+08
2268	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000149	GCKR	C:T	C/T	2016-09-08 10:35:47.622878+08
2269	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000145	ANGPTL3	A:A	A/C	2016-09-08 10:35:47.627488+08
2270	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.632123+08
2271	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000148	FADS1	C:C	C/T	2016-09-08 10:35:47.636914+08
2272	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000154	TRIB1	A:T	A/T	2016-09-08 10:35:47.641668+08
2273	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:35:47.647428+08
2274	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.65223+08
2275	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000205	LPL	C:C	C/G	2016-09-08 10:35:47.657076+08
2276	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000212	APOE	C:T	C/T	2016-09-08 10:35:47.661956+08
2277	XYC6560238	P168220014	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	50.5600014	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:35:47.666804+08
2278	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000149	GCKR	C:T	C/T	2016-09-08 10:35:47.671616+08
2279	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000145	ANGPTL3	A:C	A/C	2016-09-08 10:35:47.676893+08
2280	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.681764+08
2281	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000148	FADS1	C:C	C/T	2016-09-08 10:35:47.686607+08
2282	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000154	TRIB1	A:T	A/T	2016-09-08 10:35:47.691392+08
2283	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:35:47.696031+08
2284	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.70079+08
2285	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000205	LPL	C:C	C/G	2016-09-08 10:35:47.705634+08
2286	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000212	APOE	T:T	C/T	2016-09-08 10:35:47.710545+08
2287	XYC6560237	P168190032	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8699989	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:35:47.715272+08
2288	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000149	GCKR	C:C	C/T	2016-09-08 10:35:47.719997+08
2289	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000145	ANGPTL3	A:A	A/C	2016-09-08 10:35:47.724766+08
2290	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.729602+08
2291	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000148	FADS1	T:T	C/T	2016-09-08 10:35:47.734629+08
2292	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000154	TRIB1	A:T	A/T	2016-09-08 10:35:47.739437+08
2293	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000158	GCKR	C:C	C/T	2016-09-08 10:35:47.744147+08
2294	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.74899+08
2295	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000205	LPL	C:G	C/G	2016-09-08 10:35:47.753874+08
2296	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000212	APOE	C:T	C/T	2016-09-08 10:35:47.759074+08
2297	XYC6560281	P167230072	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	32.9700012	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:35:47.763925+08
2298	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000149	GCKR	C:T	C/T	2016-09-08 10:35:47.768775+08
2299	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000145	ANGPTL3	A:A	A/C	2016-09-08 10:35:47.773428+08
2300	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.77807+08
2301	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:35:47.782815+08
2302	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000154	TRIB1	T:T	A/T	2016-09-08 10:35:47.787556+08
2303	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000158	GCKR	C:T	C/T	2016-09-08 10:35:47.792224+08
2304	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.796946+08
2305	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000205	LPL	G:G	C/G	2016-09-08 10:35:47.801758+08
2306	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000212	APOE	C:T	C/T	2016-09-08 10:35:47.806603+08
2307	XYC6560233	P168160792	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	40.5099983	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:35:47.811421+08
2308	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000149	GCKR	C:C	C/T	2016-09-08 10:35:47.815915+08
2309	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000145	ANGPTL3	A:C	A/C	2016-09-08 10:35:47.820589+08
2310	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.825407+08
2311	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000148	FADS1	C:T	C/T	2016-09-08 10:35:47.830057+08
2312	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000154	TRIB1	T:T	A/T	2016-09-08 10:35:47.834926+08
2313	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000158	GCKR	C:C	C/T	2016-09-08 10:35:47.840695+08
2314	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000206	MLXIPL	C:T	C/T	2016-09-08 10:35:47.845642+08
2315	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000205	LPL	C:G	C/G	2016-09-08 10:35:47.85056+08
2316	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000212	APOE	C:C	C/T	2016-09-08 10:35:47.855427+08
2317	XYC6560234	P168160788	CardioWise	代谢因子	甘油三酯水平升高遗传风险	低风险	metabolic_disease	26.3099995	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:35:47.860279+08
2318	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000149	GCKR	T:T	C/T	2016-09-08 10:35:47.865077+08
2319	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000145	ANGPTL3	A:A	A/C	2016-09-08 10:35:47.869847+08
2320	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000146	ZNF259	C:C	C/G	2016-09-08 10:35:47.874547+08
2321	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000148	FADS1	C:C	C/T	2016-09-08 10:35:47.879368+08
2322	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000154	TRIB1	A:T	A/T	2016-09-08 10:35:47.88418+08
2323	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000158	GCKR	T:T	C/T	2016-09-08 10:35:47.888979+08
2324	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000206	MLXIPL	C:C	C/T	2016-09-08 10:35:47.893797+08
2325	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000205	LPL	C:C	C/G	2016-09-08 10:35:47.898662+08
2326	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000212	APOE	T:T	C/T	2016-09-08 10:35:47.903571+08
2327	XYC6560235	P168170068	CardioWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	56.7200012	GWV0000213	APOA5	T:T	C/T	2016-09-08 10:35:47.909053+08
2328	XYC6560251	P167290010	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.839999974	GWV0000223	PITX2	C:T	C/T	2016-09-08 10:35:47.914009+08
2329	XYC6560251	P167290010	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.839999974	GWV0000224	IL6R	C:T	C/T	2016-09-08 10:35:47.918847+08
2330	XYC6560238	P168220014	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.839999974	GWV0000223	PITX2	C:T	C/T	2016-09-08 10:35:47.923221+08
2331	XYC6560238	P168220014	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.839999974	GWV0000224	IL6R	C:T	C/T	2016-09-08 10:35:47.92776+08
2332	XYC6560237	P168190032	CardioWise	风险评估	心房颤动	高于平均风险	risk_estimation_bin	1.54999995	GWV0000223	PITX2	C:T	C/T	2016-09-08 10:35:47.932417+08
2333	XYC6560237	P168190032	CardioWise	风险评估	心房颤动	高于平均风险	risk_estimation_bin	1.54999995	GWV0000224	IL6R	T:T	C/T	2016-09-08 10:35:47.936965+08
2335	XYC6560281	P167230072	CardioWise	风险评估	心房颤动	高风险	risk_estimation_bin	2.21000004	GWV0000224	IL6R	T:T	C/T	2016-09-08 10:35:47.945922+08
2336	XYC6560233	P168160792	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.839999974	GWV0000223	PITX2	C:T	C/T	2016-09-08 10:35:47.950576+08
2337	XYC6560233	P168160792	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.839999974	GWV0000224	IL6R	C:T	C/T	2016-09-08 10:35:47.955009+08
2338	XYC6560234	P168160788	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.460000008	GWV0000223	PITX2	C:T	C/T	2016-09-08 10:35:47.959386+08
2339	XYC6560234	P168160788	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.460000008	GWV0000224	IL6R	C:C	C/T	2016-09-08 10:35:47.96407+08
2340	XYC6560235	P168170068	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.589999974	GWV0000223	PITX2	C:C	C/T	2016-09-08 10:35:47.968698+08
2341	XYC6560235	P168170068	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.589999974	GWV0000224	IL6R	C:T	C/T	2016-09-08 10:35:47.973162+08
2342	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000226	CXCL12	C:T	C/T	2016-09-08 10:35:47.977772+08
2343	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:47.982376+08
2344	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000227	BRAP	T:T	C/T	2016-09-08 10:35:47.986947+08
2345	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000228	WDR35	C:T	C/T	2016-09-08 10:35:47.991553+08
2346	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000229	GUCY1A3	G:T	G/T	2016-09-08 10:35:47.996032+08
2347	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000230	C6orf10	A:G	A/G	2016-09-08 10:35:48.000569+08
2348	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000231	ATP2B1	C:C	C/T	2016-09-08 10:35:48.005091+08
2349	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000232	HLA,DRB-DQB	C:C	C/T	2016-09-08 10:35:48.009744+08
2350	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000233	ADTRP	G:G	A/G	2016-09-08 10:35:48.014361+08
2351	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000234	CDKN2B-AS1	A:C	A/C	2016-09-08 10:35:48.019019+08
2352	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000235	PDGFD	T:T	C/T	2016-09-08 10:35:48.023686+08
2353	XYC6560251	P167290010	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.75999999	GWV0000236	HNF1A	G:T	G/T	2016-09-08 10:35:48.028262+08
2354	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000226	CXCL12	C:T	C/T	2016-09-08 10:35:48.032792+08
2355	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000193	ALDH2	A:G	A/G	2016-09-08 10:35:48.037386+08
2356	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000227	BRAP	C:T	C/T	2016-09-08 10:35:48.041989+08
2357	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000228	WDR35	C:T	C/T	2016-09-08 10:35:48.046697+08
2358	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000229	GUCY1A3	T:T	G/T	2016-09-08 10:35:48.051259+08
2359	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000230	C6orf10	A:G	A/G	2016-09-08 10:35:48.055774+08
2360	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000231	ATP2B1	T:T	C/T	2016-09-08 10:35:48.06043+08
2361	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000232	HLA,DRB-DQB	C:C	C/T	2016-09-08 10:35:48.065078+08
2362	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000233	ADTRP	G:G	A/G	2016-09-08 10:35:48.069904+08
2363	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000234	CDKN2B-AS1	A:C	A/C	2016-09-08 10:35:48.074509+08
2364	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000235	PDGFD	C:T	C/T	2016-09-08 10:35:48.079076+08
2365	XYC6560238	P168220014	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.97000003	GWV0000236	HNF1A	T:T	G/T	2016-09-08 10:35:48.083695+08
2366	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000226	CXCL12	C:T	C/T	2016-09-08 10:35:48.088605+08
2367	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:48.09339+08
2368	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000227	BRAP	T:T	C/T	2016-09-08 10:35:48.097955+08
2369	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000228	WDR35	C:T	C/T	2016-09-08 10:35:48.102576+08
2370	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000229	GUCY1A3	T:T	G/T	2016-09-08 10:35:48.107076+08
2371	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000230	C6orf10	A:G	A/G	2016-09-08 10:35:48.111738+08
2372	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000231	ATP2B1	C:T	C/T	2016-09-08 10:35:48.116566+08
2373	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000232	HLA,DRB-DQB	C:C	C/T	2016-09-08 10:35:48.121357+08
2374	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000233	ADTRP	G:G	A/G	2016-09-08 10:35:48.125905+08
2375	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000234	CDKN2B-AS1	A:C	A/C	2016-09-08 10:35:48.131073+08
2376	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000235	PDGFD	C:C	C/T	2016-09-08 10:35:48.135776+08
2377	XYC6560237	P168190032	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.730000019	GWV0000236	HNF1A	G:T	G/T	2016-09-08 10:35:48.140523+08
2378	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000226	CXCL12	C:T	C/T	2016-09-08 10:35:48.145069+08
2379	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:48.149749+08
2380	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000227	BRAP	T:T	C/T	2016-09-08 10:35:48.154392+08
2381	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000228	WDR35	C:C	C/T	2016-09-08 10:35:48.159078+08
2382	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000229	GUCY1A3	G:T	G/T	2016-09-08 10:35:48.163702+08
2383	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000230	C6orf10	A:G	A/G	2016-09-08 10:35:48.168965+08
2384	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000231	ATP2B1	C:C	C/T	2016-09-08 10:35:48.173733+08
2385	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000232	HLA,DRB-DQB	C:C	C/T	2016-09-08 10:35:48.178571+08
2386	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000233	ADTRP	A:G	A/G	2016-09-08 10:35:48.18312+08
2387	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000234	CDKN2B-AS1	A:C	A/C	2016-09-08 10:35:48.187826+08
2388	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000235	PDGFD	C:C	C/T	2016-09-08 10:35:48.192533+08
2389	XYC6560281	P167230072	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000236	HNF1A	T:T	G/T	2016-09-08 10:35:48.197259+08
2390	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000226	CXCL12	T:T	C/T	2016-09-08 10:35:48.202552+08
2391	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:48.20708+08
2392	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000227	BRAP	T:T	C/T	2016-09-08 10:35:48.211785+08
2393	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000228	WDR35	C:C	C/T	2016-09-08 10:35:48.21645+08
2394	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000229	GUCY1A3	G:T	G/T	2016-09-08 10:35:48.221026+08
2395	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000230	C6orf10	G:G	A/G	2016-09-08 10:35:48.225628+08
2396	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000231	ATP2B1	C:T	C/T	2016-09-08 10:35:48.230352+08
2397	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000232	HLA,DRB-DQB	C:C	C/T	2016-09-08 10:35:48.234969+08
2398	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000233	ADTRP	A:G	A/G	2016-09-08 10:35:48.23966+08
2399	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000234	CDKN2B-AS1	A:C	A/C	2016-09-08 10:35:48.244363+08
2400	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000235	PDGFD	T:T	C/T	2016-09-08 10:35:48.249021+08
2401	XYC6560233	P168160792	CardioWise	风险评估	冠心病	高于平均风险	risk_estimation_bin	1.67999995	GWV0000236	HNF1A	G:T	G/T	2016-09-08 10:35:48.253763+08
2402	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000226	CXCL12	T:T	C/T	2016-09-08 10:35:48.258378+08
2403	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:48.262846+08
2404	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000227	BRAP	T:T	C/T	2016-09-08 10:35:48.267605+08
2405	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000228	WDR35	C:C	C/T	2016-09-08 10:35:48.272322+08
2406	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000229	GUCY1A3	G:T	G/T	2016-09-08 10:35:48.27693+08
2407	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000230	C6orf10	G:G	A/G	2016-09-08 10:35:48.281557+08
2408	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000231	ATP2B1	C:T	C/T	2016-09-08 10:35:48.286862+08
2409	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000232	HLA,DRB-DQB	C:C	C/T	2016-09-08 10:35:48.291529+08
2410	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000233	ADTRP	G:G	A/G	2016-09-08 10:35:48.296008+08
2411	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000234	CDKN2B-AS1	C:C	A/C	2016-09-08 10:35:48.300775+08
2412	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000235	PDGFD	C:T	C/T	2016-09-08 10:35:48.305412+08
2413	XYC6560234	P168160788	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.99000001	GWV0000236	HNF1A	G:G	G/T	2016-09-08 10:35:48.310025+08
2414	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000226	CXCL12	C:T	C/T	2016-09-08 10:35:48.314709+08
2415	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:48.319552+08
2416	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000227	BRAP	T:T	C/T	2016-09-08 10:35:48.324254+08
2417	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000228	WDR35	C:C	C/T	2016-09-08 10:35:48.328934+08
2418	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000229	GUCY1A3	T:T	G/T	2016-09-08 10:35:48.333477+08
2419	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000230	C6orf10	A:G	A/G	2016-09-08 10:35:48.338394+08
2420	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000231	ATP2B1	C:T	C/T	2016-09-08 10:35:48.343066+08
2421	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000232	HLA,DRB-DQB	C:C	C/T	2016-09-08 10:35:48.347717+08
2422	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000233	ADTRP	G:G	A/G	2016-09-08 10:35:48.352436+08
2423	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000234	CDKN2B-AS1	A:A	A/C	2016-09-08 10:35:48.357021+08
2424	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000235	PDGFD	T:T	C/T	2016-09-08 10:35:48.361768+08
2425	XYC6560235	P168170068	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	0.779999971	GWV0000236	HNF1A	T:T	G/T	2016-09-08 10:35:48.366445+08
2426	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000237	LIPA	C:C	C/T	2016-09-08 10:35:48.371088+08
2427	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000238	TCF21	C:C	C/G	2016-09-08 10:35:48.376357+08
2428	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000239	LTA	A:A	A/C	2016-09-08 10:35:48.380896+08
2429	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000240	PSMA6	C:C	C/G	2016-09-08 10:35:48.385435+08
2430	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000241	MIAT	C:C	C/T	2016-09-08 10:35:48.389928+08
2431	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000242	LGALS2	G:G	A/G	2016-09-08 10:35:48.394511+08
2432	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000243	CDKN2B-AS1	A:G	A/G	2016-09-08 10:35:48.399+08
2433	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000244	CXCL12	C:T	C/T	2016-09-08 10:35:48.403742+08
2434	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000245	MIA3	C:C	A/C	2016-09-08 10:35:48.408225+08
2435	XYC6560251	P167290010	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.949999988	GWV0000246	IRX1	C:C	C/T	2016-09-08 10:35:48.41273+08
2436	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000237	LIPA	T:T	C/T	2016-09-08 10:35:48.417351+08
2437	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000238	TCF21	C:G	C/G	2016-09-08 10:35:48.421941+08
2438	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000239	LTA	C:C	A/C	2016-09-08 10:35:48.426458+08
2439	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000240	PSMA6	C:G	C/G	2016-09-08 10:35:48.431025+08
2440	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000241	MIAT	C:C	C/T	2016-09-08 10:35:48.435618+08
2441	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000242	LGALS2	A:G	A/G	2016-09-08 10:35:48.440149+08
2442	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000243	CDKN2B-AS1	A:G	A/G	2016-09-08 10:35:48.444776+08
2443	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000244	CXCL12	C:T	C/T	2016-09-08 10:35:48.449334+08
2444	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000245	MIA3	C:C	A/C	2016-09-08 10:35:48.453925+08
2445	XYC6560238	P168220014	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.34000003	GWV0000246	IRX1	C:T	C/T	2016-09-08 10:35:48.458417+08
2446	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000237	LIPA	C:C	C/T	2016-09-08 10:35:48.463407+08
2447	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000238	TCF21	C:C	C/G	2016-09-08 10:35:48.468+08
2448	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000239	LTA	A:C	A/C	2016-09-08 10:35:48.472691+08
2449	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000240	PSMA6	C:G	C/G	2016-09-08 10:35:48.477143+08
2450	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000241	MIAT	C:C	C/T	2016-09-08 10:35:48.481726+08
2451	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000242	LGALS2	G:G	A/G	2016-09-08 10:35:48.48663+08
2452	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000243	CDKN2B-AS1	A:G	A/G	2016-09-08 10:35:48.49124+08
2453	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000244	CXCL12	C:T	C/T	2016-09-08 10:35:48.495789+08
2454	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000245	MIA3	A:C	A/C	2016-09-08 10:35:48.500334+08
2455	XYC6560237	P168190032	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.5	GWV0000246	IRX1	C:C	C/T	2016-09-08 10:35:48.505099+08
2456	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000237	LIPA	C:T	C/T	2016-09-08 10:35:48.509864+08
2457	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000238	TCF21	C:G	C/G	2016-09-08 10:35:48.51459+08
2458	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000239	LTA	A:C	A/C	2016-09-08 10:35:48.51905+08
2459	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000240	PSMA6	C:G	C/G	2016-09-08 10:35:48.523711+08
2460	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000241	MIAT	C:C	C/T	2016-09-08 10:35:48.528293+08
2461	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000242	LGALS2	A:G	A/G	2016-09-08 10:35:48.532868+08
2462	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000243	CDKN2B-AS1	A:G	A/G	2016-09-08 10:35:48.537539+08
2463	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000244	CXCL12	C:T	C/T	2016-09-08 10:35:48.542072+08
2464	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000245	MIA3	C:C	A/C	2016-09-08 10:35:48.546761+08
2465	XYC6560281	P167230072	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.850000024	GWV0000246	IRX1	C:C	C/T	2016-09-08 10:35:48.551377+08
2466	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000237	LIPA	C:T	C/T	2016-09-08 10:35:48.555874+08
2467	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000238	TCF21	C:G	C/G	2016-09-08 10:35:48.560453+08
2468	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000239	LTA	A:A	A/C	2016-09-08 10:35:48.564987+08
2469	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000240	PSMA6	C:G	C/G	2016-09-08 10:35:48.569468+08
2470	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000241	MIAT	C:C	C/T	2016-09-08 10:35:48.574018+08
2471	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000242	LGALS2	G:G	A/G	2016-09-08 10:35:48.578612+08
2472	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000243	CDKN2B-AS1	A:G	A/G	2016-09-08 10:35:48.583079+08
2473	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000244	CXCL12	C:C	C/T	2016-09-08 10:35:48.58825+08
2474	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000245	MIA3	A:A	A/C	2016-09-08 10:35:48.593044+08
2475	XYC6560233	P168160792	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	1.20000005	GWV0000246	IRX1	C:C	C/T	2016-09-08 10:35:48.597702+08
2476	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000237	LIPA	C:T	C/T	2016-09-08 10:35:48.602167+08
2477	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000238	TCF21	C:G	C/G	2016-09-08 10:35:48.606747+08
2478	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000239	LTA	A:A	A/C	2016-09-08 10:35:48.611266+08
2479	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000240	PSMA6	G:G	C/G	2016-09-08 10:35:48.61587+08
2480	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000241	MIAT	C:C	C/T	2016-09-08 10:35:48.620451+08
2481	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000242	LGALS2	G:G	A/G	2016-09-08 10:35:48.62504+08
2482	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000243	CDKN2B-AS1	G:G	A/G	2016-09-08 10:35:48.629869+08
2483	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000244	CXCL12	C:C	C/T	2016-09-08 10:35:48.634424+08
2484	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000245	MIA3	C:C	A/C	2016-09-08 10:35:48.638968+08
2485	XYC6560234	P168160788	CardioWise	风险评估	心肌梗死	高于平均风险	risk_estimation_bin	3.6099999	GWV0000246	IRX1	T:T	C/T	2016-09-08 10:35:48.64348+08
2486	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000237	LIPA	C:C	C/T	2016-09-08 10:35:48.64795+08
2487	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000238	TCF21	C:G	C/G	2016-09-08 10:35:48.652441+08
2488	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000239	LTA	A:C	A/C	2016-09-08 10:35:48.657031+08
2489	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000240	PSMA6	G:G	C/G	2016-09-08 10:35:48.661604+08
2490	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000241	MIAT	C:C	C/T	2016-09-08 10:35:48.666029+08
2491	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000242	LGALS2	A:G	A/G	2016-09-08 10:35:48.670529+08
2492	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000243	CDKN2B-AS1	A:A	A/G	2016-09-08 10:35:48.675765+08
2493	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000244	CXCL12	C:T	C/T	2016-09-08 10:35:48.680285+08
2494	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000245	MIA3	A:C	A/C	2016-09-08 10:35:48.684883+08
2495	XYC6560235	P168170068	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.540000021	GWV0000246	IRX1	C:C	C/T	2016-09-08 10:35:48.689508+08
2496	XYC6560251	P167290010	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.460000008	GWV0000199	MTHFR	G:G	A/G	2016-09-08 10:35:48.694016+08
2497	XYC6560251	P167290010	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.460000008	GWV0000247	PROC	C:C	C/T	2016-09-08 10:35:48.698674+08
2498	XYC6560238	P168220014	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:35:48.703325+08
2499	XYC6560238	P168220014	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000247	PROC	C:C	C/T	2016-09-08 10:35:48.708016+08
2500	XYC6560237	P168190032	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:35:48.712791+08
2501	XYC6560237	P168190032	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000247	PROC	C:C	C/T	2016-09-08 10:35:48.717479+08
2502	XYC6560281	P167230072	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:35:48.722037+08
2503	XYC6560281	P167230072	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000247	PROC	C:C	C/T	2016-09-08 10:35:48.726686+08
2504	XYC6560233	P168160792	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:35:48.731402+08
2505	XYC6560233	P168160792	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000247	PROC	C:C	C/T	2016-09-08 10:35:48.735865+08
2506	XYC6560234	P168160788	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.460000008	GWV0000199	MTHFR	G:G	A/G	2016-09-08 10:35:48.740386+08
2507	XYC6560234	P168160788	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.460000008	GWV0000247	PROC	C:C	C/T	2016-09-08 10:35:48.744912+08
2508	XYC6560235	P168170068	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	1.97000003	GWV0000199	MTHFR	A:A	A/G	2016-09-08 10:35:48.749443+08
2509	XYC6560235	P168170068	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	1.97000003	GWV0000247	PROC	C:C	C/T	2016-09-08 10:35:48.754051+08
2510	XYC6560251	P167290010	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.44000006	GWV0000052	CLEC16A	T:T	G/T	2016-09-08 10:35:48.758819+08
2511	XYC6560251	P167290010	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.44000006	GWV0000053	PTPN22	C:G	C/G	2016-09-08 10:35:48.763418+08
2512	XYC6560251	P167290010	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.44000006	GWV0000054	IL2RA	C:T	C/T	2016-09-08 10:35:48.767978+08
2513	XYC6560251	P167290010	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.44000006	GWV0000055	IFIH1	C:T	C/T	2016-09-08 10:35:48.772588+08
2514	XYC6560238	P168220014	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.44000006	GWV0000052	CLEC16A	T:T	G/T	2016-09-08 10:35:48.777077+08
2515	XYC6560238	P168220014	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.44000006	GWV0000053	PTPN22	C:G	C/G	2016-09-08 10:35:48.781668+08
2516	XYC6560238	P168220014	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.44000006	GWV0000054	IL2RA	C:T	C/T	2016-09-08 10:35:48.786233+08
2517	XYC6560238	P168220014	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.44000006	GWV0000055	IFIH1	C:T	C/T	2016-09-08 10:35:48.790809+08
2518	XYC6560237	P168190032	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.72000003	GWV0000052	CLEC16A	G:T	G/T	2016-09-08 10:35:48.795238+08
2519	XYC6560237	P168190032	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.72000003	GWV0000053	PTPN22	C:G	C/G	2016-09-08 10:35:48.799821+08
2520	XYC6560237	P168190032	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.72000003	GWV0000054	IL2RA	C:C	C/T	2016-09-08 10:35:48.804299+08
2521	XYC6560237	P168190032	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.72000003	GWV0000055	IFIH1	C:T	C/T	2016-09-08 10:35:48.808907+08
2522	XYC6560281	P167230072	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.439999998	GWV0000052	CLEC16A	G:T	G/T	2016-09-08 10:35:48.81347+08
2523	XYC6560281	P167230072	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.439999998	GWV0000053	PTPN22	G:G	C/G	2016-09-08 10:35:48.817949+08
2524	XYC6560281	P167230072	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.439999998	GWV0000054	IL2RA	C:T	C/T	2016-09-08 10:35:48.822546+08
2525	XYC6560281	P167230072	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.439999998	GWV0000055	IFIH1	T:T	C/T	2016-09-08 10:35:48.827178+08
2526	XYC6560233	P168160792	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.439999998	GWV0000052	CLEC16A	G:T	G/T	2016-09-08 10:35:48.83175+08
2527	XYC6560233	P168160792	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.439999998	GWV0000053	PTPN22	G:G	C/G	2016-09-08 10:35:48.836344+08
2528	XYC6560233	P168160792	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.439999998	GWV0000054	IL2RA	C:T	C/T	2016-09-08 10:35:48.841385+08
2529	XYC6560233	P168160792	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.439999998	GWV0000055	IFIH1	T:T	C/T	2016-09-08 10:35:48.846336+08
2530	XYC6560234	P168160788	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.30999994	GWV0000052	CLEC16A	T:T	G/T	2016-09-08 10:35:48.850979+08
2531	XYC6560234	P168160788	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.30999994	GWV0000053	PTPN22	C:G	C/G	2016-09-08 10:35:48.855512+08
2532	XYC6560234	P168160788	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.30999994	GWV0000054	IL2RA	T:T	C/T	2016-09-08 10:35:48.860014+08
2533	XYC6560234	P168160788	CardioWise	风险评估	I型糖尿病	高于平均风险	risk_estimation_bin	1.30999994	GWV0000055	IFIH1	C:T	C/T	2016-09-08 10:35:48.864742+08
2534	XYC6560235	P168170068	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	1.00999999	GWV0000052	CLEC16A	T:T	G/T	2016-09-08 10:35:48.86936+08
2535	XYC6560235	P168170068	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	1.00999999	GWV0000053	PTPN22	G:G	C/G	2016-09-08 10:35:48.873882+08
2536	XYC6560235	P168170068	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	1.00999999	GWV0000054	IL2RA	T:T	C/T	2016-09-08 10:35:48.878411+08
2537	XYC6560235	P168170068	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	1.00999999	GWV0000055	IFIH1	C:T	C/T	2016-09-08 10:35:48.883002+08
2538	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000056	SLC30A8	T:T	C/T	2016-09-08 10:35:48.887657+08
2539	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:35:48.892163+08
2540	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000058	KCNJ11	C:T	C/T	2016-09-08 10:35:48.89682+08
2541	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:35:48.901482+08
2542	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000060	CDKN2B	C:T	C/T	2016-09-08 10:35:48.906259+08
2543	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000061	MTNR1B	C:C	C/G	2016-09-08 10:35:48.91092+08
2544	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000062	CDKAL1	A:C	A/C	2016-09-08 10:35:48.915838+08
2545	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000063	HHEX	T:T	C/T	2016-09-08 10:35:48.920602+08
2546	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000064	IGF2BP2	A:A	A/C	2016-09-08 10:35:48.925172+08
2547	XYC6560251	P167290010	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.639999986	GWV0000065	KCNQ1	C:C	C/T	2016-09-08 10:35:48.930832+08
2548	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000056	SLC30A8	T:T	C/T	2016-09-08 10:35:48.935466+08
2549	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:35:48.939993+08
2550	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000058	KCNJ11	C:C	C/T	2016-09-08 10:35:48.94461+08
2551	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:35:48.949252+08
2552	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000060	CDKN2B	C:T	C/T	2016-09-08 10:35:48.953806+08
2553	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000061	MTNR1B	C:G	C/G	2016-09-08 10:35:48.958335+08
2554	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000062	CDKAL1	A:A	A/C	2016-09-08 10:35:48.962959+08
2555	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000063	HHEX	C:T	C/T	2016-09-08 10:35:48.967544+08
2556	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000064	IGF2BP2	A:A	A/C	2016-09-08 10:35:48.972139+08
2557	XYC6560238	P168220014	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.419999987	GWV0000065	KCNQ1	C:T	C/T	2016-09-08 10:35:48.97685+08
2558	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000056	SLC30A8	T:T	C/T	2016-09-08 10:35:48.981438+08
2559	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:35:48.985869+08
2560	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000058	KCNJ11	C:C	C/T	2016-09-08 10:35:48.990478+08
2561	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:35:48.995109+08
2562	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000060	CDKN2B	C:T	C/T	2016-09-08 10:35:48.999709+08
2563	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000061	MTNR1B	C:G	C/G	2016-09-08 10:35:49.004302+08
2564	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000062	CDKAL1	C:C	A/C	2016-09-08 10:35:49.008932+08
2565	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000063	HHEX	C:T	C/T	2016-09-08 10:35:49.013608+08
2566	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000064	IGF2BP2	A:C	A/C	2016-09-08 10:35:49.018984+08
2567	XYC6560237	P168190032	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.790000021	GWV0000065	KCNQ1	C:T	C/T	2016-09-08 10:35:49.023735+08
2568	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000056	SLC30A8	C:T	C/T	2016-09-08 10:35:49.02827+08
2569	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:35:49.032906+08
2570	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000058	KCNJ11	C:T	C/T	2016-09-08 10:35:49.037667+08
2571	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:35:49.042365+08
2572	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000060	CDKN2B	T:T	C/T	2016-09-08 10:35:49.046991+08
2573	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000061	MTNR1B	C:C	C/G	2016-09-08 10:35:49.051732+08
2574	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000062	CDKAL1	A:A	A/C	2016-09-08 10:35:49.056633+08
2575	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000063	HHEX	C:T	C/T	2016-09-08 10:35:49.061431+08
2576	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000064	IGF2BP2	A:A	A/C	2016-09-08 10:35:49.066059+08
2577	XYC6560281	P167230072	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.870000005	GWV0000065	KCNQ1	C:T	C/T	2016-09-08 10:35:49.0709+08
2578	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000056	SLC30A8	T:T	C/T	2016-09-08 10:35:49.07549+08
2579	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:35:49.080085+08
2580	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000058	KCNJ11	T:T	C/T	2016-09-08 10:35:49.084661+08
2581	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:35:49.089794+08
2582	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000060	CDKN2B	C:T	C/T	2016-09-08 10:35:49.094496+08
2583	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000061	MTNR1B	C:C	C/G	2016-09-08 10:35:49.099218+08
2584	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000062	CDKAL1	A:C	A/C	2016-09-08 10:35:49.103893+08
2585	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000063	HHEX	C:T	C/T	2016-09-08 10:35:49.108551+08
2586	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000064	IGF2BP2	A:A	A/C	2016-09-08 10:35:49.113281+08
2587	XYC6560233	P168160792	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.899999976	GWV0000065	KCNQ1	C:T	C/T	2016-09-08 10:35:49.118251+08
2588	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000056	SLC30A8	T:T	C/T	2016-09-08 10:35:49.122935+08
2589	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:35:49.127445+08
2590	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000058	KCNJ11	C:T	C/T	2016-09-08 10:35:49.132042+08
2591	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:35:49.136749+08
2592	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000060	CDKN2B	C:C	C/T	2016-09-08 10:35:49.141298+08
2593	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000061	MTNR1B	C:G	C/G	2016-09-08 10:35:49.145876+08
2594	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000062	CDKAL1	A:C	A/C	2016-09-08 10:35:49.150532+08
2595	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000063	HHEX	C:T	C/T	2016-09-08 10:35:49.155258+08
2596	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000064	IGF2BP2	A:C	A/C	2016-09-08 10:35:49.159846+08
2597	XYC6560234	P168160788	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.629999995	GWV0000065	KCNQ1	C:T	C/T	2016-09-08 10:35:49.164466+08
2598	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000056	SLC30A8	C:T	C/T	2016-09-08 10:35:49.169041+08
2599	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000057	TCF7L2	C:C	C/T	2016-09-08 10:35:49.173474+08
2600	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000058	KCNJ11	C:T	C/T	2016-09-08 10:35:49.178012+08
2601	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000059	PPARG	C:C	C/G	2016-09-08 10:35:49.182628+08
2602	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000060	CDKN2B	C:C	C/T	2016-09-08 10:35:49.187999+08
2603	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000061	MTNR1B	C:G	C/G	2016-09-08 10:35:49.192712+08
2604	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000062	CDKAL1	A:C	A/C	2016-09-08 10:35:49.19788+08
2605	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000063	HHEX	C:T	C/T	2016-09-08 10:35:49.202617+08
2606	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000064	IGF2BP2	A:C	A/C	2016-09-08 10:35:49.207303+08
2607	XYC6560235	P168170068	CardioWise	风险评估	II型糖尿病	平均风险	risk_estimation_bin	0.75999999	GWV0000065	KCNQ1	C:T	C/T	2016-09-08 10:35:49.211988+08
2608	XYC6560251	P167290010	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.670000017	GWV0000186	BCAT1	A:C	A/C	2016-09-08 10:35:49.216708+08
2609	XYC6560251	P167290010	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.670000017	GWV0000187	FGF5	A:A	A/T	2016-09-08 10:35:49.221821+08
2610	XYC6560251	P167290010	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.670000017	GWV0000188	PLEKHA7	C:C	C/T	2016-09-08 10:35:49.226547+08
2611	XYC6560251	P167290010	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.670000017	GWV0000189	ATP2B1	G:G	A/G	2016-09-08 10:35:49.23107+08
2612	XYC6560251	P167290010	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.670000017	GWV0000190	CSK	A:C	A/C	2016-09-08 10:35:49.235781+08
2613	XYC6560251	P167290010	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.670000017	GWV0000191	CAPZA1	A:C	A/C	2016-09-08 10:35:49.240374+08
2614	XYC6560251	P167290010	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.670000017	GWV0000192	CYP17A1	C:T	C/T	2016-09-08 10:35:49.244988+08
2615	XYC6560238	P168220014	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.49000001	GWV0000186	BCAT1	C:C	A/C	2016-09-08 10:35:49.249608+08
2616	XYC6560238	P168220014	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.49000001	GWV0000187	FGF5	A:T	A/T	2016-09-08 10:35:49.254234+08
2617	XYC6560238	P168220014	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.49000001	GWV0000188	PLEKHA7	C:C	C/T	2016-09-08 10:35:49.258888+08
2618	XYC6560238	P168220014	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.49000001	GWV0000189	ATP2B1	G:G	A/G	2016-09-08 10:35:49.263588+08
2619	XYC6560238	P168220014	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.49000001	GWV0000190	CSK	A:C	A/C	2016-09-08 10:35:49.268427+08
2620	XYC6560238	P168220014	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.49000001	GWV0000191	CAPZA1	C:C	A/C	2016-09-08 10:35:49.273016+08
2621	XYC6560238	P168220014	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.49000001	GWV0000192	CYP17A1	C:T	C/T	2016-09-08 10:35:49.277702+08
2622	XYC6560237	P168190032	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.07000005	GWV0000186	BCAT1	C:C	A/C	2016-09-08 10:35:49.282346+08
2623	XYC6560237	P168190032	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.07000005	GWV0000187	FGF5	A:A	A/T	2016-09-08 10:35:49.286974+08
2624	XYC6560237	P168190032	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.07000005	GWV0000188	PLEKHA7	C:C	C/T	2016-09-08 10:35:49.291643+08
2625	XYC6560237	P168190032	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.07000005	GWV0000189	ATP2B1	A:G	A/G	2016-09-08 10:35:49.296434+08
2626	XYC6560237	P168190032	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.07000005	GWV0000190	CSK	A:C	A/C	2016-09-08 10:35:49.301069+08
2627	XYC6560237	P168190032	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.07000005	GWV0000191	CAPZA1	C:C	A/C	2016-09-08 10:35:49.305776+08
2628	XYC6560237	P168190032	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.07000005	GWV0000192	CYP17A1	T:T	C/T	2016-09-08 10:35:49.310801+08
2629	XYC6560281	P167230072	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000186	BCAT1	A:C	A/C	2016-09-08 10:35:49.315474+08
2630	XYC6560281	P167230072	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000187	FGF5	A:T	A/T	2016-09-08 10:35:49.320271+08
2631	XYC6560281	P167230072	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000188	PLEKHA7	C:C	C/T	2016-09-08 10:35:49.324971+08
2632	XYC6560281	P167230072	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000189	ATP2B1	G:G	A/G	2016-09-08 10:35:49.329611+08
2633	XYC6560281	P167230072	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000190	CSK	C:C	A/C	2016-09-08 10:35:49.33424+08
2634	XYC6560281	P167230072	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000191	CAPZA1	A:A	A/C	2016-09-08 10:35:49.339367+08
2635	XYC6560281	P167230072	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.400000006	GWV0000192	CYP17A1	T:T	C/T	2016-09-08 10:35:49.344091+08
2636	XYC6560233	P168160792	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.730000019	GWV0000186	BCAT1	C:C	A/C	2016-09-08 10:35:49.348821+08
2637	XYC6560233	P168160792	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.730000019	GWV0000187	FGF5	A:T	A/T	2016-09-08 10:35:49.353894+08
2638	XYC6560233	P168160792	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.730000019	GWV0000188	PLEKHA7	T:T	C/T	2016-09-08 10:35:49.358535+08
2639	XYC6560233	P168160792	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.730000019	GWV0000189	ATP2B1	A:G	A/G	2016-09-08 10:35:49.36323+08
2640	XYC6560233	P168160792	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.730000019	GWV0000190	CSK	C:C	A/C	2016-09-08 10:35:49.367928+08
2641	XYC6560233	P168160792	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.730000019	GWV0000191	CAPZA1	A:A	A/C	2016-09-08 10:35:49.372684+08
2642	XYC6560233	P168160792	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.730000019	GWV0000192	CYP17A1	C:T	C/T	2016-09-08 10:35:49.377292+08
2643	XYC6560234	P168160788	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.270000011	GWV0000186	BCAT1	A:C	A/C	2016-09-08 10:35:49.381939+08
2644	XYC6560234	P168160788	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.270000011	GWV0000187	FGF5	A:T	A/T	2016-09-08 10:35:49.386442+08
2645	XYC6560234	P168160788	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.270000011	GWV0000188	PLEKHA7	C:C	C/T	2016-09-08 10:35:49.391016+08
2646	XYC6560234	P168160788	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.270000011	GWV0000189	ATP2B1	A:G	A/G	2016-09-08 10:35:49.395992+08
2647	XYC6560234	P168160788	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.270000011	GWV0000190	CSK	A:A	A/C	2016-09-08 10:35:49.400748+08
2648	XYC6560234	P168160788	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.270000011	GWV0000191	CAPZA1	A:A	A/C	2016-09-08 10:35:49.405439+08
2649	XYC6560234	P168160788	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.270000011	GWV0000192	CYP17A1	T:T	C/T	2016-09-08 10:35:49.410141+08
2650	XYC6560235	P168170068	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000186	BCAT1	C:C	A/C	2016-09-08 10:35:49.414765+08
2651	XYC6560235	P168170068	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000187	FGF5	A:A	A/T	2016-09-08 10:35:49.419533+08
2652	XYC6560235	P168170068	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000188	PLEKHA7	C:T	C/T	2016-09-08 10:35:49.424064+08
2653	XYC6560235	P168170068	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000189	ATP2B1	A:G	A/G	2016-09-08 10:35:49.428779+08
2654	XYC6560235	P168170068	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000190	CSK	C:C	A/C	2016-09-08 10:35:49.433508+08
2655	XYC6560235	P168170068	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000191	CAPZA1	A:C	A/C	2016-09-08 10:35:49.438021+08
2656	XYC6560235	P168170068	CardioWise	风险评估	高血压	高于平均风险	risk_estimation_bin	1.04999995	GWV0000192	CYP17A1	C:T	C/T	2016-09-08 10:35:49.442695+08
2657	XYC6560251	P167290010	CardioWise	药物反应	$\\beta$受体阻滞剂对心力衰竭患者生存益处	正常	genotype_lookup	\N	GWV0000248	GRK5	A:A	A/T	2016-09-08 10:35:49.447387+08
2658	XYC6560238	P168220014	CardioWise	药物反应	$\\beta$受体阻滞剂对心力衰竭患者生存益处	正常	genotype_lookup	\N	GWV0000248	GRK5	A:A	A/T	2016-09-08 10:35:49.452086+08
2659	XYC6560237	P168190032	CardioWise	药物反应	$\\beta$受体阻滞剂对心力衰竭患者生存益处	正常	genotype_lookup	\N	GWV0000248	GRK5	A:A	A/T	2016-09-08 10:35:49.456674+08
2660	XYC6560281	P167230072	CardioWise	药物反应	$\\beta$受体阻滞剂对心力衰竭患者生存益处	正常	genotype_lookup	\N	GWV0000248	GRK5	A:A	A/T	2016-09-08 10:35:49.461159+08
2661	XYC6560233	P168160792	CardioWise	药物反应	$\\beta$受体阻滞剂对心力衰竭患者生存益处	降低	genotype_lookup	\N	GWV0000248	GRK5	A:T	A/T	2016-09-08 10:35:49.465826+08
2662	XYC6560234	P168160788	CardioWise	药物反应	$\\beta$受体阻滞剂对心力衰竭患者生存益处	正常	genotype_lookup	\N	GWV0000248	GRK5	A:A	A/T	2016-09-08 10:35:49.470417+08
2663	XYC6560235	P168170068	CardioWise	药物反应	$\\beta$受体阻滞剂对心力衰竭患者生存益处	正常	genotype_lookup	\N	GWV0000248	GRK5	A:A	A/T	2016-09-08 10:35:49.47494+08
2664	XYC6560251	P167290010	CardioWise	药物反应	氯吡格雷代谢	中间代谢	genotype_lookup	\N	GWV0000249	CYP2C19	G:G	A/G	2016-09-08 10:35:49.479813+08
2665	XYC6560251	P167290010	CardioWise	药物反应	氯吡格雷代谢	中间代谢	genotype_lookup	\N	GWV0000250	CYP2C19	A:G	A/G	2016-09-08 10:35:49.484459+08
2666	XYC6560251	P167290010	CardioWise	药物反应	氯吡格雷代谢	中间代谢	genotype_lookup	\N	GWV0000251	CYP2C19	A:A	A/G	2016-09-08 10:35:49.48902+08
2667	XYC6560251	P167290010	CardioWise	药物反应	氯吡格雷代谢	中间代谢	genotype_lookup	\N	GWV0000252	CYP2C19	C:C	C/T	2016-09-08 10:35:49.493652+08
2668	XYC6560238	P168220014	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000249	CYP2C19	G:G	A/G	2016-09-08 10:35:49.498645+08
2669	XYC6560238	P168220014	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000250	CYP2C19	G:G	A/G	2016-09-08 10:35:49.503229+08
2670	XYC6560238	P168220014	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000251	CYP2C19	A:A	A/G	2016-09-08 10:35:49.507895+08
2671	XYC6560238	P168220014	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000252	CYP2C19	C:C	C/T	2016-09-08 10:35:49.512731+08
2672	XYC6560237	P168190032	CardioWise	药物反应	氯吡格雷代谢	中间代谢	genotype_lookup	\N	GWV0000249	CYP2C19	A:G	A/G	2016-09-08 10:35:49.517655+08
2673	XYC6560237	P168190032	CardioWise	药物反应	氯吡格雷代谢	中间代谢	genotype_lookup	\N	GWV0000250	CYP2C19	G:G	A/G	2016-09-08 10:35:49.522393+08
2674	XYC6560237	P168190032	CardioWise	药物反应	氯吡格雷代谢	中间代谢	genotype_lookup	\N	GWV0000251	CYP2C19	A:A	A/G	2016-09-08 10:35:49.527027+08
2675	XYC6560237	P168190032	CardioWise	药物反应	氯吡格雷代谢	中间代谢	genotype_lookup	\N	GWV0000252	CYP2C19	C:C	C/T	2016-09-08 10:35:49.531675+08
2676	XYC6560281	P167230072	CardioWise	药物反应	氯吡格雷代谢	慢代谢	genotype_lookup	\N	GWV0000249	CYP2C19	A:A	A/G	2016-09-08 10:35:49.536302+08
2677	XYC6560281	P167230072	CardioWise	药物反应	氯吡格雷代谢	慢代谢	genotype_lookup	\N	GWV0000250	CYP2C19	G:G	A/G	2016-09-08 10:35:49.540894+08
2678	XYC6560281	P167230072	CardioWise	药物反应	氯吡格雷代谢	慢代谢	genotype_lookup	\N	GWV0000251	CYP2C19	A:A	A/G	2016-09-08 10:35:49.545465+08
2679	XYC6560281	P167230072	CardioWise	药物反应	氯吡格雷代谢	慢代谢	genotype_lookup	\N	GWV0000252	CYP2C19	C:C	C/T	2016-09-08 10:35:49.550058+08
2680	XYC6560233	P168160792	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000249	CYP2C19	G:G	A/G	2016-09-08 10:35:49.554709+08
2681	XYC6560233	P168160792	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000250	CYP2C19	G:G	A/G	2016-09-08 10:35:49.55923+08
2682	XYC6560233	P168160792	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000251	CYP2C19	A:A	A/G	2016-09-08 10:35:49.563829+08
2683	XYC6560233	P168160792	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000252	CYP2C19	C:C	C/T	2016-09-08 10:35:49.56857+08
2684	XYC6560234	P168160788	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000249	CYP2C19	G:G	A/G	2016-09-08 10:35:49.573064+08
2685	XYC6560234	P168160788	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000250	CYP2C19	G:G	A/G	2016-09-08 10:35:49.577724+08
2686	XYC6560234	P168160788	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000251	CYP2C19	A:A	A/G	2016-09-08 10:35:49.582294+08
2687	XYC6560234	P168160788	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000252	CYP2C19	C:C	C/T	2016-09-08 10:35:49.586927+08
2688	XYC6560235	P168170068	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000249	CYP2C19	G:G	A/G	2016-09-08 10:35:49.592055+08
2689	XYC6560235	P168170068	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000250	CYP2C19	G:G	A/G	2016-09-08 10:35:49.596733+08
2690	XYC6560235	P168170068	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000251	CYP2C19	A:A	A/G	2016-09-08 10:35:49.601259+08
2691	XYC6560235	P168170068	CardioWise	药物反应	氯吡格雷代谢	快代谢	genotype_lookup	\N	GWV0000252	CYP2C19	C:C	C/T	2016-09-08 10:35:49.605844+08
2692	XYC6560251	P167290010	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000260	AGTR1	T:T	A/T	2016-09-08 10:35:49.610448+08
2693	XYC6560251	P167290010	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000261	AGTR1	C:T	C/T	2016-09-08 10:35:49.615236+08
2694	XYC6560251	P167290010	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000262	BDKRB1	G:G	A/G	2016-09-08 10:35:49.619943+08
2695	XYC6560238	P168220014	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000260	AGTR1	T:T	A/T	2016-09-08 10:35:49.624626+08
2696	XYC6560238	P168220014	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000261	AGTR1	C:C	C/T	2016-09-08 10:35:49.629361+08
2697	XYC6560238	P168220014	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000262	BDKRB1	A:G	A/G	2016-09-08 10:35:49.634021+08
2698	XYC6560237	P168190032	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	无效	allele_count_new	\N	GWV0000260	AGTR1	T:T	A/T	2016-09-08 10:35:49.63861+08
2699	XYC6560237	P168190032	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	无效	allele_count_new	\N	GWV0000261	AGTR1	T:T	C/T	2016-09-08 10:35:49.643671+08
2700	XYC6560237	P168190032	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	无效	allele_count_new	\N	GWV0000262	BDKRB1	A:A	A/G	2016-09-08 10:35:49.648496+08
2701	XYC6560281	P167230072	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000260	AGTR1	T:T	A/T	2016-09-08 10:35:49.653251+08
2702	XYC6560281	P167230072	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000261	AGTR1	C:T	C/T	2016-09-08 10:35:49.657951+08
2703	XYC6560281	P167230072	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000262	BDKRB1	G:G	A/G	2016-09-08 10:35:49.662739+08
2704	XYC6560233	P168160792	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	无效	allele_count_new	\N	GWV0000260	AGTR1	T:T	A/T	2016-09-08 10:35:49.667357+08
2705	XYC6560233	P168160792	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	无效	allele_count_new	\N	GWV0000261	AGTR1	T:T	C/T	2016-09-08 10:35:49.671999+08
2706	XYC6560233	P168160792	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	无效	allele_count_new	\N	GWV0000262	BDKRB1	A:G	A/G	2016-09-08 10:35:49.676769+08
2707	XYC6560234	P168160788	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000260	AGTR1	T:T	A/T	2016-09-08 10:35:49.681304+08
2708	XYC6560234	P168160788	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000261	AGTR1	C:T	C/T	2016-09-08 10:35:49.685944+08
2709	XYC6560234	P168160788	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000262	BDKRB1	A:G	A/G	2016-09-08 10:35:49.69107+08
2710	XYC6560235	P168170068	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	无效	allele_count_new	\N	GWV0000260	AGTR1	T:T	A/T	2016-09-08 10:35:49.695817+08
2711	XYC6560235	P168170068	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	无效	allele_count_new	\N	GWV0000261	AGTR1	T:T	C/T	2016-09-08 10:35:49.700549+08
2712	XYC6560235	P168170068	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	无效	allele_count_new	\N	GWV0000262	BDKRB1	A:G	A/G	2016-09-08 10:35:49.705372+08
2713	XYC6560251	P167290010	CardioWise	药物反应	他汀引起肌病	可能	genotype_lookup	\N	GWV0000263	SLCO1B1	C:T	C/T	2016-09-08 10:35:49.710054+08
2714	XYC6560238	P168220014	CardioWise	药物反应	他汀引起肌病	不太可能	genotype_lookup	\N	GWV0000263	SLCO1B1	T:T	C/T	2016-09-08 10:35:49.714787+08
2715	XYC6560237	P168190032	CardioWise	药物反应	他汀引起肌病	不太可能	genotype_lookup	\N	GWV0000263	SLCO1B1	T:T	C/T	2016-09-08 10:35:49.719405+08
2716	XYC6560281	P167230072	CardioWise	药物反应	他汀引起肌病	不太可能	genotype_lookup	\N	GWV0000263	SLCO1B1	T:T	C/T	2016-09-08 10:35:49.723981+08
2717	XYC6560233	P168160792	CardioWise	药物反应	他汀引起肌病	不太可能	genotype_lookup	\N	GWV0000263	SLCO1B1	T:T	C/T	2016-09-08 10:35:49.728597+08
2718	XYC6560234	P168160788	CardioWise	药物反应	他汀引起肌病	可能	genotype_lookup	\N	GWV0000263	SLCO1B1	C:T	C/T	2016-09-08 10:35:49.733018+08
2719	XYC6560235	P168170068	CardioWise	药物反应	他汀引起肌病	不太可能	genotype_lookup	\N	GWV0000263	SLCO1B1	T:T	C/T	2016-09-08 10:35:49.737667+08
2720	XYC6560251	P167290010	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000130	CYP4F2	C:C	C/T	2016-09-08 10:35:49.742418+08
2721	XYC6560251	P167290010	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.747061+08
2722	XYC6560251	P167290010	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000265	VKORC1	T:T	C/T	2016-09-08 10:35:49.751703+08
2723	XYC6560238	P168220014	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000130	CYP4F2	C:C	C/T	2016-09-08 10:35:49.756382+08
2724	XYC6560238	P168220014	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.761277+08
2725	XYC6560238	P168220014	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000265	VKORC1	T:T	C/T	2016-09-08 10:35:49.766025+08
2726	XYC6560237	P168190032	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000130	CYP4F2	C:C	C/T	2016-09-08 10:35:49.770767+08
2727	XYC6560237	P168190032	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.7755+08
2728	XYC6560237	P168190032	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000265	VKORC1	T:T	C/T	2016-09-08 10:35:49.780044+08
2729	XYC6560281	P167230072	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000130	CYP4F2	C:C	C/T	2016-09-08 10:35:49.784743+08
2730	XYC6560281	P167230072	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.789426+08
2731	XYC6560281	P167230072	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000265	VKORC1	T:T	C/T	2016-09-08 10:35:49.794054+08
2732	XYC6560233	P168160792	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000130	CYP4F2	C:C	C/T	2016-09-08 10:35:49.798797+08
2733	XYC6560233	P168160792	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000264	CYP2C9	A:C	A/C	2016-09-08 10:35:49.803422+08
2734	XYC6560233	P168160792	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000265	VKORC1	C:T	C/T	2016-09-08 10:35:49.808041+08
2735	XYC6560234	P168160788	CardioWise	药物反应	华法林敏感性	较高	genotype_lookup	\N	GWV0000130	CYP4F2	C:C	C/T	2016-09-08 10:35:49.812709+08
2736	XYC6560234	P168160788	CardioWise	药物反应	华法林敏感性	较高	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.817471+08
2737	XYC6560234	P168160788	CardioWise	药物反应	华法林敏感性	较高	genotype_lookup	\N	GWV0000265	VKORC1	C:T	C/T	2016-09-08 10:35:49.822257+08
2738	XYC6560235	P168170068	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000130	CYP4F2	C:C	C/T	2016-09-08 10:35:49.826914+08
2739	XYC6560235	P168170068	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.831519+08
2740	XYC6560235	P168170068	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000265	VKORC1	T:T	C/T	2016-09-08 10:35:49.835977+08
2741	XYC6560251	P167290010	CardioWise	药物反应	氯沙坦代谢	快代谢	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.84103+08
2742	XYC6560238	P168220014	CardioWise	药物反应	氯沙坦代谢	快代谢	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.846005+08
2743	XYC6560237	P168190032	CardioWise	药物反应	氯沙坦代谢	快代谢	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.850712+08
2744	XYC6560281	P167230072	CardioWise	药物反应	氯沙坦代谢	快代谢	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.855308+08
2745	XYC6560233	P168160792	CardioWise	药物反应	氯沙坦代谢	中间代谢	genotype_lookup	\N	GWV0000264	CYP2C9	A:C	A/C	2016-09-08 10:35:49.859873+08
2746	XYC6560234	P168160788	CardioWise	药物反应	氯沙坦代谢	快代谢	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.864466+08
2747	XYC6560235	P168170068	CardioWise	药物反应	氯沙坦代谢	快代谢	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-09-08 10:35:49.869161+08
2748	XYC6560251	P167290010	CardioWise	药物反应	硝酸甘油缓解心绞痛效果	高效	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:49.873787+08
2749	XYC6560238	P168220014	CardioWise	药物反应	硝酸甘油缓解心绞痛效果	低效	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-09-08 10:35:49.878299+08
2750	XYC6560237	P168190032	CardioWise	药物反应	硝酸甘油缓解心绞痛效果	高效	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:49.882896+08
2751	XYC6560281	P167230072	CardioWise	药物反应	硝酸甘油缓解心绞痛效果	高效	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:49.887535+08
2752	XYC6560233	P168160792	CardioWise	药物反应	硝酸甘油缓解心绞痛效果	高效	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:49.892045+08
2753	XYC6560234	P168160788	CardioWise	药物反应	硝酸甘油缓解心绞痛效果	高效	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:49.896627+08
2754	XYC6560235	P168170068	CardioWise	药物反应	硝酸甘油缓解心绞痛效果	高效	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-08 10:35:49.901038+08
2755	XYC6560251	P167290010	CardioWise	药物反应	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-08 10:35:49.905629+08
2756	XYC6560238	P168220014	CardioWise	药物反应	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-08 10:35:49.91025+08
2757	XYC6560237	P168190032	CardioWise	药物反应	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-08 10:35:49.914921+08
2758	XYC6560281	P167230072	CardioWise	药物反应	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-08 10:35:49.919529+08
2759	XYC6560233	P168160792	CardioWise	药物反应	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-08 10:35:49.924024+08
2760	XYC6560234	P168160788	CardioWise	药物反应	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-08 10:35:49.928898+08
2761	XYC6560235	P168170068	CardioWise	药物反应	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-08 10:35:49.933733+08
2762	XYC6560251	P167290010	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果差	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-08 10:35:49.938222+08
2763	XYC6560251	P167290010	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果差	genotype_lookup	\N	GWV0000173	MTHFR	G:T	G/T	2016-09-08 10:35:49.942811+08
2764	XYC6560251	P167290010	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果差	genotype_lookup	\N	GWV0000360	MTRR	A:G	A/G	2016-09-08 10:35:49.94743+08
2765	XYC6560238	P168220014	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果较差	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:35:49.952087+08
2766	XYC6560238	P168220014	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果较差	genotype_lookup	\N	GWV0000173	MTHFR	G:T	G/T	2016-09-08 10:35:49.956693+08
2767	XYC6560238	P168220014	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果较差	genotype_lookup	\N	GWV0000360	MTRR	A:A	A/G	2016-09-08 10:35:49.961347+08
2768	XYC6560237	P168190032	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果差	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:35:49.965882+08
2769	XYC6560237	P168190032	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果差	genotype_lookup	\N	GWV0000173	MTHFR	T:T	G/T	2016-09-08 10:35:49.970415+08
2770	XYC6560237	P168190032	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果差	genotype_lookup	\N	GWV0000360	MTRR	A:G	A/G	2016-09-08 10:35:49.975012+08
2771	XYC6560281	P167230072	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果差	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:35:49.979565+08
2772	XYC6560281	P167230072	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果差	genotype_lookup	\N	GWV0000173	MTHFR	T:T	G/T	2016-09-08 10:35:49.984055+08
2773	XYC6560281	P167230072	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果差	genotype_lookup	\N	GWV0000360	MTRR	A:G	A/G	2016-09-08 10:35:49.988708+08
2774	XYC6560233	P168160792	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果较差	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-08 10:35:49.993618+08
2775	XYC6560233	P168160792	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果较差	genotype_lookup	\N	GWV0000173	MTHFR	G:T	G/T	2016-09-08 10:35:49.998056+08
2776	XYC6560233	P168160792	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果较差	genotype_lookup	\N	GWV0000360	MTRR	A:A	A/G	2016-09-08 10:35:50.002808+08
2777	XYC6560234	P168160788	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-08 10:35:50.007403+08
2778	XYC6560234	P168160788	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果正常	genotype_lookup	\N	GWV0000173	MTHFR	T:T	G/T	2016-09-08 10:35:50.011967+08
2779	XYC6560234	P168160788	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果正常	genotype_lookup	\N	GWV0000360	MTRR	A:A	A/G	2016-09-08 10:35:50.016654+08
2780	XYC6560235	P168170068	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果极差	genotype_lookup	\N	GWV0000199	MTHFR	A:A	A/G	2016-09-08 10:35:50.02114+08
2781	XYC6560235	P168170068	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果极差	genotype_lookup	\N	GWV0000173	MTHFR	T:T	G/T	2016-09-08 10:35:50.025731+08
2782	XYC6560235	P168170068	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果极差	genotype_lookup	\N	GWV0000360	MTRR	G:G	A/G	2016-09-08 10:35:50.030404+08
2783	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:02.127109+08
2784	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-26 11:52:02.134016+08
2785	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:C	C/T	2016-09-26 11:52:02.138861+08
2786	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-26 11:52:02.143443+08
2787	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:52:02.147998+08
2788	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-26 11:52:02.152629+08
2789	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-26 11:52:02.157428+08
2790	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-09-26 11:52:02.162052+08
2791	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:02.16673+08
2793	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	A:C	A/C	2016-09-26 11:52:02.175954+08
2795	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:52:02.185605+08
2799	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:02.204451+08
2800	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-26 11:52:02.209141+08
2802	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-26 11:52:02.218567+08
2803	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:02.223027+08
2804	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:02.227708+08
2805	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:02.232443+08
2806	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:C	A/C	2016-09-26 11:52:02.237081+08
2807	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:02.24186+08
2808	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:52:02.246981+08
2809	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:02.251971+08
2794	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:02.180764+08
2801	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	T:T	C/T	2016-09-26 11:52:02.213918+08
2798	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:52:02.19974+08
2797	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:02.194988+08
2796	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:02.190259+08
2810	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:02.256867+08
2811	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:02.262061+08
2812	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	T:T	C/T	2016-09-26 11:52:02.26698+08
2813	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-26 11:52:02.271945+08
2792	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:G	C/G	2016-09-26 11:52:02.171329+08
2814	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	T:T	A/T	2016-09-26 11:52:02.289082+08
2815	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-09-26 11:52:02.309981+08
2816	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	C:T	C/T	2016-09-26 11:52:02.315137+08
2819	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	C:G	C/G	2016-09-26 11:52:02.329838+08
2820	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-26 11:52:02.334829+08
2821	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-26 11:52:02.345148+08
2822	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	A:T	A/T	2016-09-26 11:52:02.349995+08
2818	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:02.324872+08
2817	XYC6640387	P169120450	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:02.320009+08
2823	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:T	G/T	2016-09-26 11:52:02.365661+08
2824	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:G	C/G	2016-09-26 11:52:02.370491+08
2825	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-26 11:52:02.375091+08
2826	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	T:T	A/T	2016-09-26 11:52:02.379747+08
2827	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:52:02.384348+08
2828	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	A:A	A/G	2016-09-26 11:52:02.388947+08
2829	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-09-26 11:52:02.393455+08
2830	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-09-26 11:52:02.398035+08
2831	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:02.402642+08
2833	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-26 11:52:02.412075+08
2835	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	A:G	A/G	2016-09-26 11:52:02.421622+08
2839	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:02.440984+08
2840	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-26 11:52:02.445851+08
2842	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:C	C/G	2016-09-26 11:52:02.455934+08
2843	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:02.46122+08
2844	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:02.466123+08
2845	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:02.47106+08
2846	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-26 11:52:02.475855+08
2847	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:02.480817+08
2848	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	C:C	A/C	2016-09-26 11:52:02.485629+08
2849	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:02.490339+08
2850	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:02.495158+08
2851	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:02.50006+08
2852	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-09-26 11:52:02.505018+08
2853	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:C	A/C	2016-09-26 11:52:02.509927+08
2832	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:02.407343+08
2834	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:02.41685+08
2854	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-09-26 11:52:02.525449+08
2841	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:02.450942+08
2838	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:T	C/T	2016-09-26 11:52:02.435952+08
2837	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:G	C/G	2016-09-26 11:52:02.431142+08
2855	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-09-26 11:52:02.546504+08
2836	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:T	C/T	2016-09-26 11:52:02.426415+08
2856	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	C:T	C/T	2016-09-26 11:52:02.551077+08
2859	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-26 11:52:02.565546+08
2860	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-09-26 11:52:02.570322+08
2861	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:G	A/G	2016-09-26 11:52:02.580857+08
2862	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:02.585613+08
2858	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:02.560824+08
2857	XYC6640384	P169120133	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:02.556042+08
2863	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:02.60059+08
2864	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:G	C/G	2016-09-26 11:52:02.604974+08
2865	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:C	C/T	2016-09-26 11:52:02.609557+08
2866	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:A	A/T	2016-09-26 11:52:02.614006+08
2867	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:G	A/G	2016-09-26 11:52:02.619172+08
2868	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	A:G	A/G	2016-09-26 11:52:02.623771+08
2869	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-09-26 11:52:02.628238+08
2870	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:G	A/G	2016-09-26 11:52:02.632697+08
2871	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:02.637303+08
2873	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	A:C	A/C	2016-09-26 11:52:02.646639+08
2875	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:52:02.656258+08
2879	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:02.675462+08
2880	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-26 11:52:02.680138+08
2882	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:C	C/G	2016-09-26 11:52:02.689931+08
2883	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:02.694789+08
2884	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:02.69953+08
2885	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:02.70424+08
2886	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:C	A/C	2016-09-26 11:52:02.709009+08
2887	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:02.713794+08
2888	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	C:C	A/C	2016-09-26 11:52:02.718577+08
2889	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:02.723405+08
2890	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	T:T	C/T	2016-09-26 11:52:02.728065+08
2891	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:02.73287+08
2892	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-09-26 11:52:02.737608+08
2893	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-26 11:52:02.742788+08
2872	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:02.641962+08
2874	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:02.651497+08
2894	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:A	A/T	2016-09-26 11:52:02.758663+08
2881	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:02.684948+08
2878	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:T	C/T	2016-09-26 11:52:02.670271+08
2877	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:02.665692+08
2895	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	C:C	C/T	2016-09-26 11:52:02.780817+08
2896	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-26 11:52:02.785688+08
2899	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	C:G	C/G	2016-09-26 11:52:02.800448+08
2900	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-26 11:52:02.805443+08
2876	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:02.660968+08
2901	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:G	A/G	2016-09-26 11:52:02.81583+08
2902	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	A:T	A/T	2016-09-26 11:52:02.820874+08
2898	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:02.795471+08
2897	XYC6640394	P168290068	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:02.790509+08
2903	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:02.836861+08
2904	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000136	Intergenic	G:G	C/G	2016-09-26 11:52:02.84189+08
2905	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-26 11:52:02.846478+08
2906	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-26 11:52:02.851023+08
2907	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:52:02.855616+08
2908	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-26 11:52:02.860149+08
2909	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-09-26 11:52:02.865247+08
2910	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000211	LDLR	A:G	A/G	2016-09-26 11:52:02.870065+08
2911	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000167	ABCA1	T:T	C/T	2016-09-26 11:52:02.874952+08
2913	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-26 11:52:02.88458+08
2915	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000170	GALNT2	A:G	A/G	2016-09-26 11:52:02.894249+08
2919	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:02.913662+08
2920	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000157	GCK	A:A	A/G	2016-09-26 11:52:02.918506+08
2922	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000061	MTNR1B	G:G	C/G	2016-09-26 11:52:02.928105+08
2923	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:02.932804+08
2924	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:02.937632+08
2925	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:02.942472+08
2926	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-26 11:52:02.94734+08
2927	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:02.952177+08
2928	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:52:02.957017+08
2929	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:02.962455+08
2930	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:02.96743+08
2931	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:02.972372+08
2932	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000149	GCKR	C:T	C/T	2016-09-26 11:52:02.977437+08
2933	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:C	A/C	2016-09-26 11:52:02.982426+08
2912	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:02.879791+08
2914	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:02.88949+08
2934	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000154	TRIB1	T:T	A/T	2016-09-26 11:52:02.99795+08
2921	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:02.923433+08
2918	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:52:02.908752+08
2917	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:02.903916+08
2935	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-09-26 11:52:03.018709+08
2936	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-26 11:52:03.023562+08
2939	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-26 11:52:03.038309+08
2940	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-26 11:52:03.043079+08
2916	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:02.899057+08
2941	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-26 11:52:03.053439+08
2942	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:03.058247+08
2938	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:03.033474+08
2937	XYC6640389	P167270184	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.028387+08
2943	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:03.073524+08
2944	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-26 11:52:03.078172+08
2945	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	T:T	C/T	2016-09-26 11:52:03.082952+08
2946	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-26 11:52:03.087622+08
2947	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:G	A/G	2016-09-26 11:52:03.092153+08
2948	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	A:G	A/G	2016-09-26 11:52:03.096898+08
2949	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-26 11:52:03.101493+08
2950	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:G	A/G	2016-09-26 11:52:03.106046+08
2951	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:03.110788+08
2953	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-26 11:52:03.120923+08
2955	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:52:03.130363+08
2959	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:03.149468+08
2960	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	A:G	A/G	2016-09-26 11:52:03.154175+08
2962	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	G:G	C/G	2016-09-26 11:52:03.163713+08
2963	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:03.16855+08
2964	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:03.173331+08
2965	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:03.178241+08
2966	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-26 11:52:03.183246+08
2967	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:03.188055+08
2968	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:52:03.192886+08
2969	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:03.198051+08
2970	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:03.20297+08
2971	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:03.20783+08
2972	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	T:T	C/T	2016-09-26 11:52:03.212585+08
2973	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:C	A/C	2016-09-26 11:52:03.217416+08
2952	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:G	C/G	2016-09-26 11:52:03.116002+08
2954	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:03.125666+08
2974	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:A	A/T	2016-09-26 11:52:03.232661+08
2961	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:03.158985+08
2958	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:T	C/T	2016-09-26 11:52:03.144614+08
2957	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:03.139871+08
2975	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-09-26 11:52:03.253072+08
2976	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	C:T	C/T	2016-09-26 11:52:03.257804+08
2979	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-26 11:52:03.272252+08
2980	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:G	C/G	2016-09-26 11:52:03.277049+08
2956	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:03.135059+08
2981	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-26 11:52:03.287138+08
2982	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:03.291937+08
2978	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:03.267473+08
2977	XYC6640393	P168310044	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.262499+08
2983	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:03.306924+08
2984	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-26 11:52:03.3114+08
2985	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000137	MAFB	C:C	C/T	2016-09-26 11:52:03.315986+08
2986	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000207	HMGCR	A:T	A/T	2016-09-26 11:52:03.320561+08
2987	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:52:03.325057+08
2988	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-26 11:52:03.329823+08
2989	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:T	C/T	2016-09-26 11:52:03.334428+08
2990	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000211	LDLR	A:G	A/G	2016-09-26 11:52:03.339027+08
2991	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:03.343678+08
2993	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000204	CETP	C:C	A/C	2016-09-26 11:52:03.353034+08
2995	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:52:03.362498+08
2999	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:03.382393+08
3000	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-26 11:52:03.387126+08
3002	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:G	C/G	2016-09-26 11:52:03.396661+08
3003	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:T	C/T	2016-09-26 11:52:03.401436+08
3004	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:T	G/T	2016-09-26 11:52:03.406681+08
3005	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:03.411487+08
3006	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000161	CRY2	A:A	A/C	2016-09-26 11:52:03.416125+08
3007	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:03.420929+08
3008	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:52:03.425692+08
3009	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:03.430359+08
3010	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:03.435058+08
3011	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:03.439898+08
3012	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000149	GCKR	T:T	C/T	2016-09-26 11:52:03.444646+08
3013	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:A	A/C	2016-09-26 11:52:03.449436+08
2992	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:03.348387+08
2994	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:03.35772+08
3014	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000154	TRIB1	A:T	A/T	2016-09-26 11:52:03.464849+08
3001	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000158	GCKR	T:T	C/T	2016-09-26 11:52:03.391916+08
2998	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:52:03.377235+08
2997	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:03.372517+08
3015	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000212	APOE	C:T	C/T	2016-09-26 11:52:03.485251+08
3016	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000213	APOA5	T:T	C/T	2016-09-26 11:52:03.489923+08
3019	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000177	KCTD10	G:G	C/G	2016-09-26 11:52:03.504293+08
3020	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-26 11:52:03.509114+08
2996	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:03.367722+08
3021	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-26 11:52:03.519449+08
3022	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:03.524161+08
3018	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:03.499465+08
3017	XYC6640386	P169120449	HealthWise	饮食类型	匹配饮食	低碳水饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.49465+08
3023	XYC6640387	P169120450	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:03.539694+08
3024	XYC6640384	P169120133	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:03.544279+08
3025	XYC6640394	P168290068	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:03.54897+08
3026	XYC6640389	P167270184	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:03.553807+08
3027	XYC6640393	P168310044	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:03.558376+08
3028	XYC6640386	P169120449	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:03.562978+08
3029	XYC6640387	P169120450	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.567655+08
3030	XYC6640387	P169120450	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:03.572439+08
3031	XYC6640384	P169120133	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.576989+08
3032	XYC6640384	P169120133	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:03.581924+08
3033	XYC6640394	P168290068	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.586932+08
3034	XYC6640394	P168290068	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:03.591812+08
3035	XYC6640389	P167270184	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.59653+08
3036	XYC6640389	P167270184	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:03.601263+08
3037	XYC6640393	P168310044	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.606069+08
3038	XYC6640393	P168310044	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:03.610788+08
3039	XYC6640386	P169120449	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.615868+08
3040	XYC6640386	P169120449	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:03.62061+08
3041	XYC6640387	P169120450	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.625309+08
3042	XYC6640384	P169120133	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.629956+08
3043	XYC6640394	P168290068	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.634673+08
3044	XYC6640389	P167270184	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.639385+08
3045	XYC6640393	P168310044	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.643975+08
3046	XYC6640386	P169120449	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:52:03.648568+08
3047	XYC6640387	P169120450	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000182	C3	G:G	A/G	2016-09-26 11:52:03.653415+08
3048	XYC6640387	P169120450	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000183	ARMS2	G:T	G/T	2016-09-26 11:52:03.658239+08
3049	XYC6640387	P169120450	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000184	CFH	A:G	A/G	2016-09-26 11:52:03.663002+08
3050	XYC6640387	P169120450	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000185	C2	G:G	G/T	2016-09-26 11:52:03.667801+08
3051	XYC6640384	P169120133	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000182	C3	G:G	A/G	2016-09-26 11:52:03.672559+08
3052	XYC6640384	P169120133	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000183	ARMS2	G:T	G/T	2016-09-26 11:52:03.677307+08
3053	XYC6640384	P169120133	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000184	CFH	A:G	A/G	2016-09-26 11:52:03.682086+08
3054	XYC6640384	P169120133	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.709999979	GWV0000185	C2	G:G	G/T	2016-09-26 11:52:03.686951+08
3055	XYC6640394	P168290068	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000182	C3	G:G	A/G	2016-09-26 11:52:03.692051+08
3056	XYC6640394	P168290068	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000183	ARMS2	G:G	G/T	2016-09-26 11:52:03.696943+08
3057	XYC6640394	P168290068	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000184	CFH	G:G	A/G	2016-09-26 11:52:03.701957+08
3058	XYC6640394	P168290068	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.579999983	GWV0000185	C2	G:G	G/T	2016-09-26 11:52:03.706893+08
3059	XYC6640389	P167270184	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.53999996	GWV0000182	C3	G:G	A/G	2016-09-26 11:52:03.711727+08
3060	XYC6640389	P167270184	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.53999996	GWV0000183	ARMS2	T:T	G/T	2016-09-26 11:52:03.716603+08
3061	XYC6640389	P167270184	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.53999996	GWV0000184	CFH	A:A	A/G	2016-09-26 11:52:03.721466+08
3062	XYC6640389	P167270184	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	1.53999996	GWV0000185	C2	G:G	G/T	2016-09-26 11:52:03.726247+08
3063	XYC6640393	P168310044	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	2.18000007	GWV0000182	C3	G:G	A/G	2016-09-26 11:52:03.731057+08
3064	XYC6640393	P168310044	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	2.18000007	GWV0000183	ARMS2	T:T	G/T	2016-09-26 11:52:03.735883+08
3065	XYC6640393	P168310044	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	2.18000007	GWV0000184	CFH	A:G	A/G	2016-09-26 11:52:03.740692+08
3066	XYC6640393	P168310044	HealthWise	抗病能力	老年黄斑变性	高于平均风险	risk_estimation_bin	2.18000007	GWV0000185	C2	G:G	G/T	2016-09-26 11:52:03.745524+08
3067	XYC6640386	P169120449	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000182	C3	G:G	A/G	2016-09-26 11:52:03.750264+08
3068	XYC6640386	P169120449	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000183	ARMS2	G:G	G/T	2016-09-26 11:52:03.755043+08
3069	XYC6640386	P169120449	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000184	CFH	A:G	A/G	2016-09-26 11:52:03.75994+08
3070	XYC6640386	P169120449	HealthWise	抗病能力	老年黄斑变性	平均风险	risk_estimation_bin	0.270000011	GWV0000185	C2	G:G	G/T	2016-09-26 11:52:03.764822+08
3071	XYC6640387	P169120450	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000186	BCAT1	C:C	A/C	2016-09-26 11:52:03.769659+08
3072	XYC6640387	P169120450	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000187	FGF5	A:A	A/T	2016-09-26 11:52:03.774462+08
3073	XYC6640387	P169120450	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000188	PLEKHA7	C:C	C/T	2016-09-26 11:52:03.779591+08
3074	XYC6640387	P169120450	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000189	ATP2B1	G:G	A/G	2016-09-26 11:52:03.784405+08
3075	XYC6640387	P169120450	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000190	CSK	C:C	A/C	2016-09-26 11:52:03.789099+08
3076	XYC6640387	P169120450	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000191	CAPZA1	A:A	A/C	2016-09-26 11:52:03.793914+08
3077	XYC6640387	P169120450	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000192	CYP17A1	C:T	C/T	2016-09-26 11:52:03.798913+08
3078	XYC6640384	P169120133	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.839999974	GWV0000186	BCAT1	C:C	A/C	2016-09-26 11:52:03.803708+08
3079	XYC6640384	P169120133	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.839999974	GWV0000187	FGF5	A:T	A/T	2016-09-26 11:52:03.808394+08
3080	XYC6640384	P169120133	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.839999974	GWV0000188	PLEKHA7	C:C	C/T	2016-09-26 11:52:03.813104+08
3081	XYC6640384	P169120133	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.839999974	GWV0000189	ATP2B1	A:G	A/G	2016-09-26 11:52:03.817837+08
3082	XYC6640384	P169120133	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.839999974	GWV0000190	CSK	A:C	A/C	2016-09-26 11:52:03.822523+08
3083	XYC6640384	P169120133	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.839999974	GWV0000191	CAPZA1	A:C	A/C	2016-09-26 11:52:03.827233+08
3084	XYC6640384	P169120133	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.839999974	GWV0000192	CYP17A1	C:T	C/T	2016-09-26 11:52:03.831971+08
3085	XYC6640394	P168290068	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.6400001	GWV0000186	BCAT1	C:C	A/C	2016-09-26 11:52:03.836727+08
3086	XYC6640394	P168290068	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.6400001	GWV0000187	FGF5	A:T	A/T	2016-09-26 11:52:03.84146+08
3087	XYC6640394	P168290068	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.6400001	GWV0000188	PLEKHA7	T:T	C/T	2016-09-26 11:52:03.846165+08
3088	XYC6640394	P168290068	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.6400001	GWV0000189	ATP2B1	A:G	A/G	2016-09-26 11:52:03.851031+08
3089	XYC6640394	P168290068	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.6400001	GWV0000190	CSK	A:C	A/C	2016-09-26 11:52:03.855827+08
3090	XYC6640394	P168290068	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.6400001	GWV0000191	CAPZA1	C:C	A/C	2016-09-26 11:52:03.86051+08
3091	XYC6640394	P168290068	HealthWise	抗病能力	高血压	高风险	risk_estimation_bin	2.6400001	GWV0000192	CYP17A1	C:T	C/T	2016-09-26 11:52:03.865551+08
3092	XYC6640389	P167270184	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.74000001	GWV0000186	BCAT1	C:C	A/C	2016-09-26 11:52:03.870642+08
3093	XYC6640389	P167270184	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.74000001	GWV0000187	FGF5	A:T	A/T	2016-09-26 11:52:03.875457+08
3094	XYC6640389	P167270184	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.74000001	GWV0000188	PLEKHA7	C:C	C/T	2016-09-26 11:52:03.88026+08
3095	XYC6640389	P167270184	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.74000001	GWV0000189	ATP2B1	A:A	A/G	2016-09-26 11:52:03.885062+08
3096	XYC6640389	P167270184	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.74000001	GWV0000190	CSK	A:C	A/C	2016-09-26 11:52:03.889975+08
3097	XYC6640389	P167270184	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.74000001	GWV0000191	CAPZA1	C:C	A/C	2016-09-26 11:52:03.894841+08
3098	XYC6640389	P167270184	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	1.74000001	GWV0000192	CYP17A1	T:T	C/T	2016-09-26 11:52:03.899636+08
3099	XYC6640393	P168310044	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.790000021	GWV0000186	BCAT1	A:A	A/C	2016-09-26 11:52:03.904487+08
3100	XYC6640393	P168310044	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.790000021	GWV0000187	FGF5	A:T	A/T	2016-09-26 11:52:03.909103+08
3101	XYC6640393	P168310044	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.790000021	GWV0000188	PLEKHA7	C:C	C/T	2016-09-26 11:52:03.913895+08
3102	XYC6640393	P168310044	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.790000021	GWV0000189	ATP2B1	A:A	A/G	2016-09-26 11:52:03.918674+08
3103	XYC6640393	P168310044	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.790000021	GWV0000190	CSK	A:C	A/C	2016-09-26 11:52:03.923441+08
3104	XYC6640393	P168310044	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.790000021	GWV0000191	CAPZA1	A:A	A/C	2016-09-26 11:52:03.928114+08
3105	XYC6640393	P168310044	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.790000021	GWV0000192	CYP17A1	C:T	C/T	2016-09-26 11:52:03.932838+08
3106	XYC6640386	P169120449	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	0.970000029	GWV0000186	BCAT1	C:C	A/C	2016-09-26 11:52:03.937487+08
3107	XYC6640386	P169120449	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	0.970000029	GWV0000187	FGF5	A:T	A/T	2016-09-26 11:52:03.942235+08
3108	XYC6640386	P169120449	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	0.970000029	GWV0000188	PLEKHA7	T:T	C/T	2016-09-26 11:52:03.946988+08
3109	XYC6640386	P169120449	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	0.970000029	GWV0000189	ATP2B1	G:G	A/G	2016-09-26 11:52:03.951908+08
3110	XYC6640386	P169120449	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	0.970000029	GWV0000190	CSK	C:C	A/C	2016-09-26 11:52:03.956763+08
3111	XYC6640386	P169120449	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	0.970000029	GWV0000191	CAPZA1	A:C	A/C	2016-09-26 11:52:03.961708+08
3112	XYC6640386	P169120449	HealthWise	抗病能力	高血压	高于平均风险	risk_estimation_bin	0.970000029	GWV0000192	CYP17A1	T:T	C/T	2016-09-26 11:52:03.966441+08
3113	XYC6640387	P169120450	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-26 11:52:03.971137+08
3114	XYC6640384	P169120133	HealthWise	遗传特质	酒精代谢能力	弱	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-09-26 11:52:03.975851+08
3115	XYC6640394	P168290068	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-26 11:52:03.980662+08
3116	XYC6640389	P167270184	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-26 11:52:03.985465+08
3117	XYC6640393	P168310044	HealthWise	遗传特质	酒精代谢能力	弱	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-09-26 11:52:03.990128+08
3118	XYC6640386	P169120449	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-26 11:52:03.994859+08
3119	XYC6640387	P169120450	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-26 11:52:03.999571+08
3120	XYC6640387	P169120450	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-26 11:52:04.004396+08
3121	XYC6640384	P169120133	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-09-26 11:52:04.009076+08
3122	XYC6640384	P169120133	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-26 11:52:04.013868+08
3123	XYC6640394	P168290068	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-09-26 11:52:04.01859+08
3124	XYC6640394	P168290068	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-26 11:52:04.023399+08
3125	XYC6640389	P167270184	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-26 11:52:04.028064+08
3126	XYC6640389	P167270184	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-26 11:52:04.032853+08
3127	XYC6640393	P168310044	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	C:G	C/G	2016-09-26 11:52:04.037567+08
3128	XYC6640393	P168310044	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-26 11:52:04.042238+08
3129	XYC6640386	P169120449	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000194	TAS2R38	G:G	C/G	2016-09-26 11:52:04.047244+08
3130	XYC6640386	P169120449	HealthWise	遗传特质	苦味敏感度	强	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-26 11:52:04.052057+08
3131	XYC6640387	P169120450	HealthWise	遗传特质	甜味敏感度	低	genotype_lookup	\N	GWV0000196	TAS1R3	C:T	C/T	2016-09-26 11:52:04.056842+08
3132	XYC6640384	P169120133	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-26 11:52:04.061465+08
3133	XYC6640394	P168290068	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-26 11:52:04.065957+08
3134	XYC6640389	P167270184	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-26 11:52:04.070547+08
3135	XYC6640393	P168310044	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-26 11:52:04.075239+08
3136	XYC6640386	P169120449	HealthWise	遗传特质	甜味敏感度	低	genotype_lookup	\N	GWV0000196	TAS1R3	C:T	C/T	2016-09-26 11:52:04.079925+08
3137	XYC6640387	P169120450	HealthWise	遗传特质	肌肉爆发力	强	genotype_lookup	\N	GWV0000197	ACTN3	C:C	C/T	2016-09-26 11:52:04.084675+08
3138	XYC6640384	P169120133	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-26 11:52:04.089423+08
3139	XYC6640394	P168290068	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-26 11:52:04.094119+08
3140	XYC6640389	P167270184	HealthWise	遗传特质	肌肉爆发力	弱	genotype_lookup	\N	GWV0000197	ACTN3	T:T	C/T	2016-09-26 11:52:04.098916+08
3141	XYC6640393	P168310044	HealthWise	遗传特质	肌肉爆发力	适中	genotype_lookup	\N	GWV0000197	ACTN3	C:T	C/T	2016-09-26 11:52:04.103834+08
3142	XYC6640386	P169120449	HealthWise	遗传特质	肌肉爆发力	弱	genotype_lookup	\N	GWV0000197	ACTN3	T:T	C/T	2016-09-26 11:52:04.108561+08
3143	XYC6640387	P169120450	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-26 11:52:04.113392+08
3144	XYC6640384	P169120133	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-26 11:52:04.11942+08
3145	XYC6640394	P168290068	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-26 11:52:04.124075+08
3146	XYC6640389	P167270184	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-26 11:52:04.128818+08
3147	XYC6640393	P168310044	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-26 11:52:04.133519+08
3148	XYC6640386	P169120449	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-26 11:52:04.138104+08
3149	XYC6640387	P169120450	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-26 11:52:04.142735+08
3150	XYC6640384	P169120133	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-26 11:52:04.147311+08
3151	XYC6640394	P168290068	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-26 11:52:04.151925+08
3152	XYC6640389	P167270184	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-26 11:52:04.156591+08
3153	XYC6640393	P168310044	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-26 11:52:04.161083+08
3154	XYC6640386	P169120449	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-26 11:52:04.165716+08
3155	XYC6640387	P169120450	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-26 11:52:04.17038+08
3156	XYC6640384	P169120133	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-26 11:52:04.175255+08
3157	XYC6640394	P168290068	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-26 11:52:04.180166+08
3158	XYC6640389	P167270184	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-26 11:52:04.18507+08
3159	XYC6640393	P168310044	HealthWise	遗传特质	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-09-26 11:52:04.189868+08
3160	XYC6640386	P169120449	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	C:C	A/C	2016-09-26 11:52:04.194667+08
3161	XYC6640387	P169120450	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-09-26 11:52:04.199413+08
3162	XYC6640387	P169120450	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-26 11:52:04.20402+08
3163	XYC6640384	P169120133	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-26 11:52:04.208792+08
3164	XYC6640384	P169120133	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-26 11:52:04.213439+08
3165	XYC6640394	P168290068	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-09-26 11:52:04.218048+08
3166	XYC6640394	P168290068	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-26 11:52:04.222618+08
3167	XYC6640389	P167270184	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	C:T	C/T	2016-09-26 11:52:04.227239+08
3168	XYC6640389	P167270184	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-26 11:52:04.23193+08
3169	XYC6640393	P168310044	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000124	BCMO1	T:T	C/T	2016-09-26 11:52:04.236594+08
3170	XYC6640393	P168310044	HealthWise	营养需求	维生素A水平	偏低	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-26 11:52:04.241172+08
3171	XYC6640386	P169120449	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-26 11:52:04.245872+08
3172	XYC6640386	P169120449	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-26 11:52:04.250569+08
3173	XYC6640387	P169120450	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.255163+08
3174	XYC6640384	P169120133	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.259837+08
3175	XYC6640394	P168290068	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.264672+08
3176	XYC6640389	P167270184	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.269253+08
3177	XYC6640393	P168310044	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-26 11:52:04.273882+08
3178	XYC6640386	P169120449	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.278453+08
3179	XYC6640387	P169120450	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-26 11:52:04.283017+08
3180	XYC6640384	P169120133	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:C	C/T	2016-09-26 11:52:04.287631+08
3181	XYC6640394	P168290068	HealthWise	营养需求	维生素B$_{6}$水平	正常	genotype_lookup	\N	GWV0000125	NBPF3	T:T	C/T	2016-09-26 11:52:04.292229+08
3182	XYC6640389	P167270184	HealthWise	营养需求	维生素B$_{6}$水平	正常	genotype_lookup	\N	GWV0000125	NBPF3	T:T	C/T	2016-09-26 11:52:04.296842+08
3183	XYC6640393	P168310044	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:C	C/T	2016-09-26 11:52:04.301419+08
3184	XYC6640386	P169120449	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:C	C/T	2016-09-26 11:52:04.305982+08
3185	XYC6640387	P169120450	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-26 11:52:04.310994+08
3186	XYC6640387	P169120450	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000126	FUT2	A:A	A/T	2016-09-26 11:52:04.315668+08
3187	XYC6640384	P169120133	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-26 11:52:04.320307+08
3188	XYC6640384	P169120133	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	T:T	A/T	2016-09-26 11:52:04.324969+08
3189	XYC6640394	P168290068	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-26 11:52:04.32968+08
3190	XYC6640394	P168290068	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-09-26 11:52:04.334362+08
3191	XYC6640389	P167270184	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-26 11:52:04.339046+08
3192	XYC6640389	P167270184	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	T:T	A/T	2016-09-26 11:52:04.34373+08
3193	XYC6640393	P168310044	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-26 11:52:04.348568+08
3194	XYC6640393	P168310044	HealthWise	营养需求	维生素B$_{12}$水平	偏低	genotype_lookup	\N	GWV0000126	FUT2	A:A	A/T	2016-09-26 11:52:04.353285+08
3195	XYC6640386	P169120449	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-26 11:52:04.358004+08
3196	XYC6640386	P169120449	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-09-26 11:52:04.362671+08
3197	XYC6640387	P169120450	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-26 11:52:04.36794+08
3198	XYC6640384	P169120133	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-26 11:52:04.372619+08
3199	XYC6640394	P168290068	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-26 11:52:04.377157+08
3200	XYC6640389	P167270184	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-26 11:52:04.38202+08
3201	XYC6640393	P168310044	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-26 11:52:04.386709+08
3202	XYC6640386	P169120449	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-26 11:52:04.391371+08
3203	XYC6640387	P169120450	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-26 11:52:04.396026+08
3204	XYC6640384	P169120133	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-26 11:52:04.400684+08
3205	XYC6640394	P168290068	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-26 11:52:04.405288+08
3206	XYC6640389	P167270184	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-26 11:52:04.409927+08
3207	XYC6640393	P168310044	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-26 11:52:04.414565+08
3208	XYC6640386	P169120449	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-26 11:52:04.41918+08
3209	XYC6640387	P169120450	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.423862+08
3210	XYC6640384	P169120133	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.428443+08
3211	XYC6640394	P168290068	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.433137+08
3212	XYC6640389	P167270184	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.437786+08
3213	XYC6640393	P168310044	HealthWise	营养需求	叶酸水平	偏低	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-09-26 11:52:04.442373+08
3214	XYC6640386	P169120449	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:52:04.447219+08
3215	XYC6640387	P169120450	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-26 11:52:04.45186+08
3216	XYC6640384	P169120133	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-26 11:52:04.456508+08
3217	XYC6640394	P168290068	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-26 11:52:04.461061+08
3218	XYC6640389	P167270184	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-26 11:52:04.465725+08
3219	XYC6640393	P168310044	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-26 11:52:04.470332+08
3220	XYC6640386	P169120449	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-26 11:52:04.475085+08
3221	XYC6640387	P169120450	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.28999996	GWV0000051	MC4R	C:T	C/T	2016-09-26 11:52:04.479881+08
3222	XYC6640387	P169120450	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.28999996	GWV0000050	FTO	A:T	A/T	2016-09-26 11:52:04.48471+08
3223	XYC6640384	P169120133	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000051	MC4R	C:T	C/T	2016-09-26 11:52:04.489711+08
3224	XYC6640384	P169120133	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:04.494528+08
3225	XYC6640394	P168290068	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.28999996	GWV0000051	MC4R	C:T	C/T	2016-09-26 11:52:04.499449+08
3226	XYC6640394	P168290068	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.28999996	GWV0000050	FTO	A:T	A/T	2016-09-26 11:52:04.504238+08
3227	XYC6640389	P167270184	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000051	MC4R	T:T	C/T	2016-09-26 11:52:04.509061+08
3228	XYC6640389	P167270184	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.879999995	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:04.514005+08
3229	XYC6640393	P168310044	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000051	MC4R	C:T	C/T	2016-09-26 11:52:04.518842+08
3230	XYC6640393	P168310044	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:04.523625+08
3231	XYC6640386	P169120449	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000051	MC4R	C:T	C/T	2016-09-26 11:52:04.52846+08
3232	XYC6640386	P169120449	HealthWise	体重管理	肥胖症	平均风险	risk_estimation_bin	0.99000001	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:04.533503+08
3233	XYC6640387	P169120450	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.538261+08
3234	XYC6640384	P169120133	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.542851+08
3235	XYC6640394	P168290068	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.547419+08
3236	XYC6640389	P167270184	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.551922+08
3237	XYC6640393	P168310044	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.556597+08
3238	XYC6640386	P169120449	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.56123+08
3239	XYC6640387	P169120450	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-26 11:52:04.565884+08
3240	XYC6640384	P169120133	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-26 11:52:04.570491+08
3241	XYC6640394	P168290068	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-26 11:52:04.575163+08
3242	XYC6640389	P167270184	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	C:G	C/G	2016-09-26 11:52:04.580013+08
3243	XYC6640393	P168310044	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-26 11:52:04.584859+08
3244	XYC6640386	P169120449	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-26 11:52:04.589544+08
3245	XYC6640387	P169120450	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.594287+08
3246	XYC6640384	P169120133	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.599063+08
3247	XYC6640394	P168290068	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.604054+08
3248	XYC6640389	P167270184	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.608813+08
3249	XYC6640393	P168310044	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.613566+08
3250	XYC6640386	P169120449	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:52:04.618872+08
3251	XYC6640387	P169120450	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-26 11:52:04.623577+08
3252	XYC6640384	P169120133	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-26 11:52:04.628045+08
3253	XYC6640394	P168290068	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-26 11:52:04.632593+08
3254	XYC6640389	P167270184	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-26 11:52:04.637068+08
3255	XYC6640393	P168310044	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:G	A/G	2016-09-26 11:52:04.641741+08
3256	XYC6640386	P169120449	HealthWise	饮食习惯	饮食失控	不太可能	genotype_lookup	\N	GWV0000195	TAS2R38	G:G	A/G	2016-09-26 11:52:04.646354+08
3257	XYC6640387	P169120450	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:A	A/G	2016-09-26 11:52:04.65126+08
3258	XYC6640384	P169120133	HealthWise	饮食习惯	饮食偏好	正常	genotype_lookup	\N	GWV0000121	ANKK1	G:G	A/G	2016-09-26 11:52:04.655972+08
3259	XYC6640394	P168290068	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:A	A/G	2016-09-26 11:52:04.66067+08
3260	XYC6640389	P167270184	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-09-26 11:52:04.665406+08
3261	XYC6640393	P168310044	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-09-26 11:52:04.67007+08
3262	XYC6640386	P169120449	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:G	A/G	2016-09-26 11:52:04.674808+08
3263	XYC6640387	P169120450	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	A:T	A/T	2016-09-26 11:52:04.679462+08
3264	XYC6640384	P169120133	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:04.684043+08
3265	XYC6640394	P168290068	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	A:T	A/T	2016-09-26 11:52:04.688883+08
3266	XYC6640389	P167270184	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:04.69367+08
3267	XYC6640393	P168310044	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:04.69837+08
3268	XYC6640386	P169120449	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	T:T	A/T	2016-09-26 11:52:04.703218+08
3269	XYC6640387	P169120450	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-26 11:52:04.707942+08
3270	XYC6640384	P169120133	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-26 11:52:04.71357+08
3271	XYC6640394	P168290068	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-26 11:52:04.718368+08
3272	XYC6640389	P167270184	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-26 11:52:04.723023+08
3273	XYC6640393	P168310044	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:T	G/T	2016-09-26 11:52:04.727804+08
3274	XYC6640386	P169120449	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-26 11:52:04.732585+08
3275	XYC6640387	P169120450	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-09-26 11:52:04.737388+08
3276	XYC6640384	P169120133	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-26 11:52:04.74223+08
3277	XYC6640394	P168290068	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-26 11:52:04.746877+08
3278	XYC6640389	P167270184	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-09-26 11:52:04.751745+08
3279	XYC6640393	P168310044	HealthWise	饮食习惯	爱吃零食	增强	genotype_lookup	\N	GWV0000202	LEPR	G:G	A/G	2016-09-26 11:52:04.756454+08
3280	XYC6640386	P169120449	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-09-26 11:52:04.761067+08
3281	XYC6640387	P169120450	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-26 11:52:04.765866+08
3282	XYC6640384	P169120133	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-26 11:52:04.770584+08
3283	XYC6640394	P168290068	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-26 11:52:04.775249+08
3284	XYC6640389	P167270184	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-26 11:52:04.779925+08
3285	XYC6640393	P168310044	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-26 11:52:04.784581+08
3286	XYC6640386	P169120449	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-26 11:52:04.789276+08
3287	XYC6640387	P169120450	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:04.793998+08
3288	XYC6640387	P169120450	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000146	ZNF259	C:G	C/G	2016-09-26 11:52:04.798833+08
3289	XYC6640387	P169120450	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000204	CETP	A:C	A/C	2016-09-26 11:52:04.803781+08
3290	XYC6640387	P169120450	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:04.808638+08
3291	XYC6640387	P169120450	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:52:04.813615+08
3292	XYC6640387	P169120450	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:04.818972+08
3293	XYC6640387	P169120450	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:04.824067+08
3294	XYC6640387	P169120450	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	57.6899986	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:52:04.829358+08
3295	XYC6640384	P169120133	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	34.6199989	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:04.834329+08
3296	XYC6640384	P169120133	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	34.6199989	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:04.839297+08
3297	XYC6640384	P169120133	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	34.6199989	GWV0000204	CETP	C:C	A/C	2016-09-26 11:52:04.844263+08
3298	XYC6640384	P169120133	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	34.6199989	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:04.849414+08
3299	XYC6640384	P169120133	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	34.6199989	GWV0000170	GALNT2	A:G	A/G	2016-09-26 11:52:04.854637+08
3300	XYC6640384	P169120133	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	34.6199989	GWV0000179	LIPC	C:T	C/T	2016-09-26 11:52:04.859807+08
3301	XYC6640384	P169120133	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	34.6199989	GWV0000205	LPL	C:G	C/G	2016-09-26 11:52:04.86526+08
3302	XYC6640384	P169120133	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低风险	metabolic_disease	34.6199989	GWV0000206	MLXIPL	C:T	C/T	2016-09-26 11:52:04.870421+08
3303	XYC6640394	P168290068	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:04.87539+08
3304	XYC6640394	P168290068	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:04.880242+08
3305	XYC6640394	P168290068	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000204	CETP	A:C	A/C	2016-09-26 11:52:04.885156+08
3306	XYC6640394	P168290068	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:04.890257+08
3307	XYC6640394	P168290068	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:52:04.895248+08
3308	XYC6640394	P168290068	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:04.901123+08
3309	XYC6640394	P168290068	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:04.907917+08
3310	XYC6640394	P168290068	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	低于平均风险	metabolic_disease	37.5	GWV0000206	MLXIPL	C:T	C/T	2016-09-26 11:52:04.913047+08
3311	XYC6640389	P167270184	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000167	ABCA1	T:T	C/T	2016-09-26 11:52:04.917926+08
3312	XYC6640389	P167270184	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:04.922707+08
3313	XYC6640389	P167270184	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000204	CETP	C:C	A/C	2016-09-26 11:52:04.927646+08
3314	XYC6640389	P167270184	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:04.932585+08
3315	XYC6640389	P167270184	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000170	GALNT2	A:G	A/G	2016-09-26 11:52:04.93763+08
3316	XYC6640389	P167270184	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:04.942699+08
3317	XYC6640389	P167270184	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:04.94766+08
3318	XYC6640389	P167270184	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	60.5800018	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:52:04.952618+08
3319	XYC6640393	P168310044	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	62.5	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:04.957421+08
3320	XYC6640393	P168310044	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	62.5	GWV0000146	ZNF259	C:G	C/G	2016-09-26 11:52:04.962262+08
3321	XYC6640393	P168310044	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	62.5	GWV0000204	CETP	C:C	A/C	2016-09-26 11:52:04.967256+08
3322	XYC6640393	P168310044	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	62.5	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:04.972163+08
3323	XYC6640393	P168310044	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	62.5	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:52:04.977081+08
3324	XYC6640393	P168310044	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	62.5	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:04.982067+08
3325	XYC6640393	P168310044	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	62.5	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:04.987222+08
3326	XYC6640393	P168310044	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	62.5	GWV0000206	MLXIPL	C:T	C/T	2016-09-26 11:52:04.99222+08
3327	XYC6640386	P169120449	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:52:04.9971+08
3328	XYC6640386	P169120449	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:05.002031+08
3329	XYC6640386	P169120449	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000204	CETP	C:C	A/C	2016-09-26 11:52:05.00701+08
3330	XYC6640386	P169120449	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:05.011993+08
3331	XYC6640386	P169120449	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:52:05.017109+08
3332	XYC6640386	P169120449	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:05.022114+08
3333	XYC6640386	P169120449	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:05.027178+08
3334	XYC6640386	P169120449	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	50	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:52:05.032154+08
3335	XYC6640387	P169120450	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3800011	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:05.037417+08
3336	XYC6640387	P169120450	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3800011	GWV0000136	Intergenic	C:C	C/G	2016-09-26 11:52:05.042263+08
3337	XYC6640387	P169120450	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3800011	GWV0000137	MAFB	C:C	C/T	2016-09-26 11:52:05.047239+08
3338	XYC6640387	P169120450	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3800011	GWV0000207	HMGCR	A:T	A/T	2016-09-26 11:52:05.05223+08
3339	XYC6640387	P169120450	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3800011	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:52:05.057069+08
3340	XYC6640387	P169120450	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3800011	GWV0000209	ABO	G:G	A/G	2016-09-26 11:52:05.062143+08
3341	XYC6640387	P169120450	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3800011	GWV0000210	TOMM40	C:C	C/T	2016-09-26 11:52:05.067089+08
3342	XYC6640387	P169120450	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3800011	GWV0000211	LDLR	A:A	A/G	2016-09-26 11:52:05.072049+08
3343	XYC6640384	P169120133	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	52.3499985	GWV0000139	CELSR2	G:T	G/T	2016-09-26 11:52:05.07689+08
3344	XYC6640384	P169120133	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	52.3499985	GWV0000136	Intergenic	C:G	C/G	2016-09-26 11:52:05.08166+08
3345	XYC6640384	P169120133	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	52.3499985	GWV0000137	MAFB	C:T	C/T	2016-09-26 11:52:05.086499+08
3346	XYC6640384	P169120133	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	52.3499985	GWV0000207	HMGCR	T:T	A/T	2016-09-26 11:52:05.091425+08
3347	XYC6640384	P169120133	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	52.3499985	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:52:05.096227+08
3348	XYC6640384	P169120133	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	52.3499985	GWV0000209	ABO	A:A	A/G	2016-09-26 11:52:05.101103+08
3349	XYC6640384	P169120133	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	52.3499985	GWV0000210	TOMM40	C:T	C/T	2016-09-26 11:52:05.106028+08
3350	XYC6640384	P169120133	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	52.3499985	GWV0000211	LDLR	A:A	A/G	2016-09-26 11:52:05.110966+08
3351	XYC6640394	P168290068	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	55.3600006	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:05.116111+08
3352	XYC6640394	P168290068	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	55.3600006	GWV0000136	Intergenic	C:G	C/G	2016-09-26 11:52:05.120906+08
3353	XYC6640394	P168290068	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	55.3600006	GWV0000137	MAFB	C:C	C/T	2016-09-26 11:52:05.12575+08
3354	XYC6640394	P168290068	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	55.3600006	GWV0000207	HMGCR	A:A	A/T	2016-09-26 11:52:05.13057+08
3355	XYC6640394	P168290068	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	55.3600006	GWV0000208	APOC1	A:G	A/G	2016-09-26 11:52:05.135639+08
3356	XYC6640394	P168290068	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	55.3600006	GWV0000209	ABO	A:G	A/G	2016-09-26 11:52:05.140593+08
3357	XYC6640394	P168290068	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	55.3600006	GWV0000210	TOMM40	C:T	C/T	2016-09-26 11:52:05.145579+08
3530	XYC6640389	P167270184	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:C	C/T	2016-09-26 11:52:05.99498+08
3358	XYC6640394	P168290068	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	55.3600006	GWV0000211	LDLR	A:G	A/G	2016-09-26 11:52:05.150504+08
3359	XYC6640389	P167270184	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	37.5999985	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:05.155469+08
3360	XYC6640389	P167270184	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	37.5999985	GWV0000136	Intergenic	G:G	C/G	2016-09-26 11:52:05.160235+08
3361	XYC6640389	P167270184	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	37.5999985	GWV0000137	MAFB	C:T	C/T	2016-09-26 11:52:05.16515+08
3362	XYC6640389	P167270184	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	37.5999985	GWV0000207	HMGCR	A:T	A/T	2016-09-26 11:52:05.170147+08
3363	XYC6640389	P167270184	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	37.5999985	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:52:05.17515+08
3364	XYC6640389	P167270184	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	37.5999985	GWV0000209	ABO	G:G	A/G	2016-09-26 11:52:05.180077+08
3365	XYC6640389	P167270184	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	37.5999985	GWV0000210	TOMM40	C:T	C/T	2016-09-26 11:52:05.185074+08
3366	XYC6640389	P167270184	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	低于平均风险	metabolic_disease	37.5999985	GWV0000211	LDLR	A:G	A/G	2016-09-26 11:52:05.19008+08
3367	XYC6640393	P168310044	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	66.8199997	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:05.194966+08
3368	XYC6640393	P168310044	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	66.8199997	GWV0000136	Intergenic	C:C	C/G	2016-09-26 11:52:05.199859+08
3369	XYC6640393	P168310044	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	66.8199997	GWV0000137	MAFB	T:T	C/T	2016-09-26 11:52:05.204817+08
3370	XYC6640393	P168310044	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	66.8199997	GWV0000207	HMGCR	A:T	A/T	2016-09-26 11:52:05.209881+08
3371	XYC6640393	P168310044	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	66.8199997	GWV0000208	APOC1	A:G	A/G	2016-09-26 11:52:05.214905+08
3372	XYC6640393	P168310044	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	66.8199997	GWV0000209	ABO	A:G	A/G	2016-09-26 11:52:05.219822+08
3373	XYC6640393	P168310044	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	66.8199997	GWV0000210	TOMM40	C:C	C/T	2016-09-26 11:52:05.224675+08
3374	XYC6640393	P168310044	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高风险	metabolic_disease	66.8199997	GWV0000211	LDLR	A:G	A/G	2016-09-26 11:52:05.22958+08
3375	XYC6640386	P169120449	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3100014	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:52:05.234412+08
3376	XYC6640386	P169120449	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3100014	GWV0000136	Intergenic	C:C	C/G	2016-09-26 11:52:05.239109+08
3377	XYC6640386	P169120449	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3100014	GWV0000137	MAFB	C:C	C/T	2016-09-26 11:52:05.244009+08
3378	XYC6640386	P169120449	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3100014	GWV0000207	HMGCR	A:T	A/T	2016-09-26 11:52:05.24894+08
3379	XYC6640386	P169120449	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3100014	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:52:05.253836+08
3380	XYC6640386	P169120449	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3100014	GWV0000209	ABO	G:G	A/G	2016-09-26 11:52:05.258657+08
3381	XYC6640386	P169120449	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3100014	GWV0000210	TOMM40	C:T	C/T	2016-09-26 11:52:05.263464+08
3382	XYC6640386	P169120449	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	46.3100014	GWV0000211	LDLR	A:G	A/G	2016-09-26 11:52:05.268239+08
3383	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:05.272994+08
3384	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000157	GCK	G:G	A/G	2016-09-26 11:52:05.277711+08
3385	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000158	GCKR	T:T	C/T	2016-09-26 11:52:05.282497+08
3386	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000061	MTNR1B	C:G	C/G	2016-09-26 11:52:05.287171+08
3387	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:05.29206+08
3388	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:05.296931+08
3389	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:05.301877+08
3390	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000161	CRY2	A:C	A/C	2016-09-26 11:52:05.306753+08
3391	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:05.311769+08
3392	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:52:05.316755+08
3393	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:05.321623+08
3394	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:05.326432+08
3395	XYC6640387	P169120450	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	56.2299995	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:05.331253+08
3396	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:05.336028+08
3397	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000157	GCK	G:G	A/G	2016-09-26 11:52:05.340796+08
3398	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:05.345589+08
3399	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000061	MTNR1B	C:C	C/G	2016-09-26 11:52:05.350464+08
3400	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:05.355467+08
3401	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:05.360253+08
3402	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:05.365487+08
3403	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000161	CRY2	A:A	A/C	2016-09-26 11:52:05.37047+08
3404	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:05.375418+08
3405	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000163	GLIS3	C:C	A/C	2016-09-26 11:52:05.380376+08
3406	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:05.385068+08
3407	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:05.389946+08
3408	XYC6640384	P169120133	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	51.2200012	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:05.394824+08
3409	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:05.399601+08
3410	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000157	GCK	G:G	A/G	2016-09-26 11:52:05.404289+08
3411	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:05.408971+08
3412	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000061	MTNR1B	C:C	C/G	2016-09-26 11:52:05.413789+08
3413	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:05.418584+08
3414	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:05.423392+08
3415	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:05.428075+08
3416	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000161	CRY2	A:C	A/C	2016-09-26 11:52:05.432775+08
3417	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:05.437491+08
3418	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000163	GLIS3	C:C	A/C	2016-09-26 11:52:05.442254+08
3419	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:05.447011+08
3420	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000165	PROX1	T:T	C/T	2016-09-26 11:52:05.451856+08
3421	XYC6640394	P168290068	HealthWise	代谢因子	血糖水平升高遗传风险	低风险	metabolic_disease	47.7999992	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:05.456887+08
3422	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:05.461746+08
3423	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000157	GCK	A:A	A/G	2016-09-26 11:52:05.466583+08
3424	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:05.471429+08
3425	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000061	MTNR1B	G:G	C/G	2016-09-26 11:52:05.476402+08
3426	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:05.481337+08
3427	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:05.486078+08
3428	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:05.490868+08
3429	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000161	CRY2	A:A	A/C	2016-09-26 11:52:05.495644+08
3430	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:05.500474+08
3431	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:52:05.505238+08
3432	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:05.510133+08
3433	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:05.515052+08
3434	XYC6640389	P167270184	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	84.9599991	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:05.519931+08
3435	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:05.524721+08
3436	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000157	GCK	A:G	A/G	2016-09-26 11:52:05.529456+08
3437	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:05.534262+08
3438	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000061	MTNR1B	G:G	C/G	2016-09-26 11:52:05.539032+08
3439	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:52:05.544054+08
3440	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:52:05.548874+08
3441	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:05.553934+08
3442	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000161	CRY2	A:A	A/C	2016-09-26 11:52:05.558782+08
3531	XYC6640393	P168310044	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-09-26 11:52:05.999699+08
3443	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:05.563602+08
3444	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:52:05.568614+08
3445	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:05.573437+08
3446	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:05.578095+08
3447	XYC6640393	P168310044	HealthWise	代谢因子	血糖水平升高遗传风险	高风险	metabolic_disease	77.3799973	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:05.582777+08
3448	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:52:05.587449+08
3449	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000157	GCK	G:G	A/G	2016-09-26 11:52:05.592036+08
3450	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000158	GCKR	T:T	C/T	2016-09-26 11:52:05.596748+08
3451	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000061	MTNR1B	C:G	C/G	2016-09-26 11:52:05.601561+08
3452	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000057	TCF7L2	C:T	C/T	2016-09-26 11:52:05.606418+08
3453	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000159	ADRA2A	G:T	G/T	2016-09-26 11:52:05.6111+08
3454	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:52:05.616238+08
3455	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000161	CRY2	A:A	A/C	2016-09-26 11:52:05.621142+08
3456	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000162	FADS1	C:T	C/T	2016-09-26 11:52:05.62622+08
3457	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:52:05.631066+08
3458	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000164	MADD	A:A	A/T	2016-09-26 11:52:05.636073+08
3459	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:52:05.640943+08
3460	XYC6640386	P169120449	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	58.1899986	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:52:05.645752+08
3461	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000149	GCKR	T:T	C/T	2016-09-26 11:52:05.65062+08
3462	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000145	ANGPTL3	A:A	A/C	2016-09-26 11:52:05.655505+08
3463	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000146	ZNF259	C:G	C/G	2016-09-26 11:52:05.660498+08
3464	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:05.665673+08
3465	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000154	TRIB1	T:T	A/T	2016-09-26 11:52:05.670624+08
3466	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000158	GCKR	T:T	C/T	2016-09-26 11:52:05.675482+08
3467	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:52:05.680237+08
3468	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:05.68508+08
3469	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000212	APOE	T:T	C/T	2016-09-26 11:52:05.6901+08
3470	XYC6640387	P169120450	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	68.6200027	GWV0000213	APOA5	C:T	C/T	2016-09-26 11:52:05.695062+08
3471	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000149	GCKR	C:T	C/T	2016-09-26 11:52:05.700039+08
3472	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000145	ANGPTL3	A:C	A/C	2016-09-26 11:52:05.705005+08
3473	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:05.709932+08
3474	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:05.714904+08
3475	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000154	TRIB1	A:T	A/T	2016-09-26 11:52:05.719861+08
3476	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:05.724709+08
3477	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000206	MLXIPL	C:T	C/T	2016-09-26 11:52:05.730264+08
3478	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000205	LPL	C:G	C/G	2016-09-26 11:52:05.735237+08
3479	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000212	APOE	C:T	C/T	2016-09-26 11:52:05.740257+08
3480	XYC6640384	P169120133	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	42.8199997	GWV0000213	APOA5	C:T	C/T	2016-09-26 11:52:05.745102+08
3481	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000149	GCKR	C:T	C/T	2016-09-26 11:52:05.750036+08
3482	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000145	ANGPTL3	A:A	A/C	2016-09-26 11:52:05.754948+08
3483	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:05.759927+08
3484	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:05.76492+08
3485	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000154	TRIB1	A:A	A/T	2016-09-26 11:52:05.770485+08
3486	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:05.775496+08
3487	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000206	MLXIPL	C:T	C/T	2016-09-26 11:52:05.780592+08
3488	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:05.785533+08
3489	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000212	APOE	C:C	C/T	2016-09-26 11:52:05.790593+08
3490	XYC6640394	P168290068	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	47.4900017	GWV0000213	APOA5	T:T	C/T	2016-09-26 11:52:05.795595+08
3491	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000149	GCKR	C:T	C/T	2016-09-26 11:52:05.800477+08
3492	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000145	ANGPTL3	A:C	A/C	2016-09-26 11:52:05.805219+08
3493	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:05.810075+08
3494	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:05.815031+08
3495	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000154	TRIB1	T:T	A/T	2016-09-26 11:52:05.819991+08
3496	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:05.824825+08
3497	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:52:05.830161+08
3498	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:05.83509+08
3499	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000212	APOE	C:T	C/T	2016-09-26 11:52:05.840136+08
3500	XYC6640389	P167270184	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	44.4099998	GWV0000213	APOA5	T:T	C/T	2016-09-26 11:52:05.845172+08
3501	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000149	GCKR	T:T	C/T	2016-09-26 11:52:05.850086+08
3502	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000145	ANGPTL3	A:C	A/C	2016-09-26 11:52:05.854964+08
3503	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000146	ZNF259	C:G	C/G	2016-09-26 11:52:05.859993+08
3504	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:05.865385+08
3505	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000154	TRIB1	A:A	A/T	2016-09-26 11:52:05.870578+08
3506	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000158	GCKR	C:T	C/T	2016-09-26 11:52:05.875495+08
3507	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000206	MLXIPL	C:T	C/T	2016-09-26 11:52:05.880487+08
3508	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:05.885456+08
3509	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000212	APOE	C:T	C/T	2016-09-26 11:52:05.890464+08
3510	XYC6640393	P168310044	HealthWise	代谢因子	甘油三酯水平升高遗传风险	平均风险	metabolic_disease	58.3600006	GWV0000213	APOA5	C:T	C/T	2016-09-26 11:52:05.895251+08
3511	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000149	GCKR	T:T	C/T	2016-09-26 11:52:05.900467+08
3512	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000145	ANGPTL3	A:A	A/C	2016-09-26 11:52:05.90643+08
3513	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000146	ZNF259	C:C	C/G	2016-09-26 11:52:05.911627+08
3514	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000148	FADS1	C:T	C/T	2016-09-26 11:52:05.9167+08
3515	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000154	TRIB1	A:T	A/T	2016-09-26 11:52:05.92183+08
3516	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000158	GCKR	T:T	C/T	2016-09-26 11:52:05.926806+08
3517	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:52:05.931753+08
3518	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:05.936721+08
3519	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000212	APOE	C:T	C/T	2016-09-26 11:52:05.941785+08
3520	XYC6640386	P169120449	HealthWise	代谢因子	甘油三酯水平升高遗传风险	高于平均风险	metabolic_disease	60.3100014	GWV0000213	APOA5	T:T	C/T	2016-09-26 11:52:05.946753+08
3521	XYC6640387	P169120450	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-26 11:52:05.951747+08
3522	XYC6640384	P169120133	HealthWise	运动效果	跟腱受伤	容易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:C	C/T	2016-09-26 11:52:05.956528+08
3523	XYC6640394	P168290068	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	T:T	C/T	2016-09-26 11:52:05.96149+08
3524	XYC6640389	P167270184	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-26 11:52:05.966283+08
3525	XYC6640393	P168310044	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-26 11:52:05.971064+08
3526	XYC6640386	P169120449	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-26 11:52:05.975868+08
3527	XYC6640387	P169120450	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-09-26 11:52:05.980566+08
3528	XYC6640384	P169120133	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:C	C/T	2016-09-26 11:52:05.985251+08
3529	XYC6640394	P168290068	HealthWise	运动效果	最大吸氧量	较低	genotype_lookup	\N	GWV0000215	PPARGC1A	T:T	C/T	2016-09-26 11:52:05.989934+08
3532	XYC6640386	P169120449	HealthWise	运动效果	最大吸氧量	正常	genotype_lookup	\N	GWV0000215	PPARGC1A	C:T	C/T	2016-09-26 11:52:06.004308+08
3533	XYC6640387	P169120450	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.009067+08
3534	XYC6640387	P169120450	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-26 11:52:06.013926+08
3535	XYC6640387	P169120450	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.018758+08
3536	XYC6640384	P169120133	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-26 11:52:06.023562+08
3537	XYC6640384	P169120133	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-26 11:52:06.028354+08
3538	XYC6640384	P169120133	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-26 11:52:06.033304+08
3539	XYC6640394	P168290068	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.038251+08
3540	XYC6640394	P168290068	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-26 11:52:06.043372+08
3541	XYC6640394	P168290068	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.048234+08
3542	XYC6640389	P167270184	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.053053+08
3543	XYC6640389	P167270184	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-26 11:52:06.057918+08
3544	XYC6640389	P167270184	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.062791+08
3545	XYC6640393	P168310044	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.06769+08
3546	XYC6640393	P168310044	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-26 11:52:06.072564+08
3547	XYC6640393	P168310044	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.077463+08
3548	XYC6640386	P169120449	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.082303+08
3549	XYC6640386	P169120449	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-26 11:52:06.087092+08
3550	XYC6640386	P169120449	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.092006+08
3551	XYC6640387	P169120450	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.096849+08
3552	XYC6640384	P169120133	HealthWise	运动效果	运动减脂效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:G	C/G	2016-09-26 11:52:06.101598+08
3553	XYC6640394	P168290068	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.106343+08
3554	XYC6640389	P167270184	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.111002+08
3555	XYC6640393	P168310044	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.116247+08
3556	XYC6640386	P169120449	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:52:06.121003+08
3557	XYC6640387	P169120450	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-26 11:52:06.125866+08
3558	XYC6640384	P169120133	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-26 11:52:06.130685+08
3559	XYC6640394	P168290068	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-26 11:52:06.135396+08
3560	XYC6640389	P167270184	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-26 11:52:06.140051+08
3561	XYC6640393	P168310044	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-26 11:52:06.144743+08
3562	XYC6640386	P169120449	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	一般	genotype_lookup	\N	GWV0000216	PPARD	T:T	C/T	2016-09-26 11:52:06.149607+08
3563	XYC6640387	P169120450	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	T:T	G/T	2016-09-26 11:52:06.15438+08
3564	XYC6640384	P169120133	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-26 11:52:06.159042+08
3565	XYC6640394	P168290068	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-09-26 11:52:06.163752+08
3566	XYC6640389	P167270184	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-09-26 11:52:06.168415+08
3567	XYC6640393	P168310044	HealthWise	运动效果	运动降压效果	一般	genotype_lookup	\N	GWV0000217	EDN1	G:G	G/T	2016-09-26 11:52:06.173022+08
3568	XYC6640386	P169120449	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-26 11:52:06.177887+08
3569	XYC6640387	P169120450	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.182648+08
3570	XYC6640384	P169120133	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:T	C/T	2016-09-26 11:52:06.187385+08
3571	XYC6640394	P168290068	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.192016+08
3572	XYC6640389	P167270184	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.196696+08
3573	XYC6640393	P168310044	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.201436+08
3574	XYC6640386	P169120449	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:52:06.206042+08
3575	XYC6640387	P169120450	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:G	A/G	2016-09-26 11:52:06.21066+08
3576	XYC6640384	P169120133	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-26 11:52:06.215583+08
3577	XYC6640394	P168290068	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:A	A/G	2016-09-26 11:52:06.220388+08
3578	XYC6640389	P167270184	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-26 11:52:06.225053+08
3579	XYC6640393	P168310044	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:G	A/G	2016-09-26 11:52:06.229872+08
3580	XYC6640386	P169120449	HealthWise	运动效果	运动减肥效果	一般	genotype_lookup	\N	GWV0000218	FTO	G:G	A/G	2016-09-26 11:52:06.234684+08
3581	XYC6640387	P169120450	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-09-26 11:52:06.239603+08
3582	XYC6640384	P169120133	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-09-26 11:52:06.244444+08
3583	XYC6640394	P168290068	HealthWise	运动效果	力量训练效果	一般	genotype_lookup	\N	GWV0000219	INSIG2	C:G	C/G	2016-09-26 11:52:06.249256+08
3584	XYC6640389	P167270184	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-09-26 11:52:06.254069+08
3585	XYC6640393	P168310044	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-09-26 11:52:06.258905+08
3586	XYC6640386	P169120449	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-09-26 11:52:06.263768+08
3587	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:55:43.033727+08
3588	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000136	Intergenic	C:C	C/G	2016-09-26 11:55:43.04048+08
3589	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000137	MAFB	C:T	C/T	2016-09-26 11:55:43.045255+08
3590	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000207	HMGCR	T:T	A/T	2016-09-26 11:55:43.049992+08
3591	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:55:43.054748+08
3592	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000209	ABO	G:G	A/G	2016-09-26 11:55:43.05939+08
3593	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000210	TOMM40	C:C	C/T	2016-09-26 11:55:43.063982+08
3594	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000211	LDLR	A:A	A/G	2016-09-26 11:55:43.068719+08
3595	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:55:43.073445+08
3597	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000204	CETP	A:C	A/C	2016-09-26 11:55:43.083023+08
3599	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:55:43.092446+08
3603	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:55:43.111119+08
3604	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000157	GCK	G:G	A/G	2016-09-26 11:55:43.115876+08
3606	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000061	MTNR1B	C:C	C/G	2016-09-26 11:55:43.125341+08
3607	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:55:43.131847+08
3608	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:55:43.136588+08
3609	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:55:43.141373+08
3610	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000161	CRY2	A:C	A/C	2016-09-26 11:55:43.14607+08
3611	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000162	FADS1	C:C	C/T	2016-09-26 11:55:43.150998+08
3612	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:55:43.15584+08
3613	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000164	MADD	A:A	A/T	2016-09-26 11:55:43.160634+08
3614	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:55:43.165444+08
3615	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:55:43.170427+08
3616	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000149	GCKR	C:C	C/T	2016-09-26 11:55:43.175342+08
3617	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000145	ANGPTL3	A:C	A/C	2016-09-26 11:55:43.180181+08
3596	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000146	ZNF259	C:G	C/G	2016-09-26 11:55:43.078363+08
3598	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000148	FADS1	C:C	C/T	2016-09-26 11:55:43.087798+08
3618	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000154	TRIB1	T:T	A/T	2016-09-26 11:55:43.196463+08
3605	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000158	GCKR	C:C	C/T	2016-09-26 11:55:43.12068+08
3602	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:55:43.106503+08
3601	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:55:43.101821+08
3619	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000212	APOE	T:T	C/T	2016-09-26 11:55:43.217078+08
3620	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000213	APOA5	C:T	C/T	2016-09-26 11:55:43.221979+08
3600	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:55:43.097094+08
3622	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:55:43.231782+08
3621	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:55:43.226982+08
3623	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000177	KCTD10	C:G	C/G	2016-09-26 11:55:43.23657+08
3624	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000178	MMAB	C:C	C/G	2016-09-26 11:55:43.241682+08
3625	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000180	APOA2	A:A	A/G	2016-09-26 11:55:43.252112+08
3626	XYC6640385	P169120451	HealthWise	饮食类型	匹配饮食	均衡饮食	diet_recommendation	\N	GWV0000050	FTO	A:T	A/T	2016-09-26 11:55:43.256922+08
3627	XYC6640385	P169120451	HealthWise	饮食类型	Omega-6和Omega-3水平降低遗传风险	高于平均风险	genotype_lookup	\N	GWV0000148	FADS1	C:C	C/T	2016-09-26 11:55:43.272232+08
3628	XYC6640385	P169120451	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:55:43.276834+08
3629	XYC6640385	P169120451	HealthWise	饮食类型	单不饱和脂肪	保持平衡	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:55:43.281603+08
3630	XYC6640385	P169120451	HealthWise	饮食类型	多不饱和脂肪	适量摄入	genotype_lookup	\N	GWV0000059	PPARG	C:C	C/G	2016-09-26 11:55:43.28637+08
3631	XYC6640385	P169120451	HealthWise	抗病能力	老年黄斑变性	高风险	risk_estimation_bin	4.78999996	GWV0000182	C3	G:G	A/G	2016-09-26 11:55:43.291061+08
3632	XYC6640385	P169120451	HealthWise	抗病能力	老年黄斑变性	高风险	risk_estimation_bin	4.78999996	GWV0000183	ARMS2	T:T	G/T	2016-09-26 11:55:43.295994+08
3633	XYC6640385	P169120451	HealthWise	抗病能力	老年黄斑变性	高风险	risk_estimation_bin	4.78999996	GWV0000184	CFH	G:G	A/G	2016-09-26 11:55:43.300772+08
3634	XYC6640385	P169120451	HealthWise	抗病能力	老年黄斑变性	高风险	risk_estimation_bin	4.78999996	GWV0000185	C2	G:G	G/T	2016-09-26 11:55:43.305603+08
3635	XYC6640385	P169120451	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000186	BCAT1	C:C	A/C	2016-09-26 11:55:43.310344+08
3636	XYC6640385	P169120451	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000187	FGF5	A:A	A/T	2016-09-26 11:55:43.317346+08
3637	XYC6640385	P169120451	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000188	PLEKHA7	C:C	C/T	2016-09-26 11:55:43.322142+08
3638	XYC6640385	P169120451	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000189	ATP2B1	G:G	A/G	2016-09-26 11:55:43.327097+08
3639	XYC6640385	P169120451	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000190	CSK	C:C	A/C	2016-09-26 11:55:43.331901+08
3640	XYC6640385	P169120451	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000191	CAPZA1	A:A	A/C	2016-09-26 11:55:43.33681+08
3641	XYC6640385	P169120451	HealthWise	抗病能力	高血压	平均风险	risk_estimation_bin	0.319999993	GWV0000192	CYP17A1	C:T	C/T	2016-09-26 11:55:43.341606+08
3642	XYC6640385	P169120451	HealthWise	遗传特质	酒精代谢能力	强	genotype_lookup	\N	GWV0000193	ALDH2	G:G	A/G	2016-09-26 11:55:43.349683+08
3643	XYC6640385	P169120451	HealthWise	遗传特质	苦味敏感度	正常	genotype_lookup	\N	GWV0000194	TAS2R38	C:C	C/G	2016-09-26 11:55:43.354566+08
3644	XYC6640385	P169120451	HealthWise	遗传特质	苦味敏感度	正常	genotype_lookup	\N	GWV0000195	TAS2R38	A:A	A/G	2016-09-26 11:55:43.35942+08
3645	XYC6640385	P169120451	HealthWise	遗传特质	甜味敏感度	正常	genotype_lookup	\N	GWV0000196	TAS1R3	C:C	C/T	2016-09-26 11:55:43.364154+08
3646	XYC6640385	P169120451	HealthWise	遗传特质	肌肉爆发力	强	genotype_lookup	\N	GWV0000197	ACTN3	C:C	C/T	2016-09-26 11:55:43.369067+08
3647	XYC6640385	P169120451	HealthWise	遗传特质	尼古丁依赖性	正常	genotype_lookup	\N	GWV0000198	CHRNA3	G:G	A/G	2016-09-26 11:55:43.37387+08
3648	XYC6640385	P169120451	HealthWise	遗传特质	乳糖不耐症	不耐受	genotype_lookup	\N	GWV0000105	MCM6	G:G	A/G	2016-09-26 11:55:43.379014+08
3649	XYC6640385	P169120451	HealthWise	遗传特质	咖啡因代谢	慢	genotype_lookup	\N	GWV0000222	CYP1A2	A:C	A/C	2016-09-26 11:55:43.383898+08
3650	XYC6640385	P169120451	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000124	BCMO1	C:C	C/T	2016-09-26 11:55:43.388621+08
3651	XYC6640385	P169120451	HealthWise	营养需求	维生素A水平	正常	genotype_lookup	\N	GWV0000123	BCMO1	A:A	A/T	2016-09-26 11:55:43.393424+08
3652	XYC6640385	P169120451	HealthWise	营养需求	维生素B$_{2}$水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:55:43.398097+08
3653	XYC6640385	P169120451	HealthWise	营养需求	维生素B$_{6}$水平	偏低	genotype_lookup	\N	GWV0000125	NBPF3	C:T	C/T	2016-09-26 11:55:43.402804+08
3654	XYC6640385	P169120451	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000127	FUT2	G:G	A/G	2016-09-26 11:55:43.407574+08
3655	XYC6640385	P169120451	HealthWise	营养需求	维生素B$_{12}$水平	正常	genotype_lookup	\N	GWV0000126	FUT2	A:T	A/T	2016-09-26 11:55:43.412303+08
3656	XYC6640385	P169120451	HealthWise	营养需求	维生素D水平	偏低	genotype_lookup	\N	GWV0000129	GC	G:T	G/T	2016-09-26 11:55:43.417017+08
3657	XYC6640385	P169120451	HealthWise	营养需求	维生素E水平	偏低	genotype_lookup	\N	GWV0000131	Intergenic	C:C	A/C	2016-09-26 11:55:43.421916+08
3658	XYC6640385	P169120451	HealthWise	营养需求	叶酸水平	正常	genotype_lookup	\N	GWV0000199	MTHFR	G:G	A/G	2016-09-26 11:55:43.42644+08
3659	XYC6640385	P169120451	HealthWise	营养需求	维生素C水平	正常	genotype_lookup	\N	GWV0000128	SLC23A1	C:C	C/T	2016-09-26 11:55:43.431023+08
3660	XYC6640385	P169120451	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.28999996	GWV0000051	MC4R	C:T	C/T	2016-09-26 11:55:43.435704+08
3661	XYC6640385	P169120451	HealthWise	体重管理	肥胖症	高于平均风险	risk_estimation_bin	1.28999996	GWV0000050	FTO	A:T	A/T	2016-09-26 11:55:43.440428+08
3662	XYC6640385	P169120451	HealthWise	体重管理	脂联素水平降低风险	平均风险	genotype_lookup	\N	GWV0000200	ADIPOQ	G:G	A/G	2016-09-26 11:55:43.445148+08
3663	XYC6640385	P169120451	HealthWise	体重管理	基础代谢率	正常	genotype_lookup	\N	GWV0000201	LEPR	G:G	C/G	2016-09-26 11:55:43.450338+08
3664	XYC6640385	P169120451	HealthWise	体重管理	减肥反弹	易反弹	genotype_lookup	\N	GWV0000181	ADIPOQ	G:G	A/G	2016-09-26 11:55:43.455378+08
3665	XYC6640385	P169120451	HealthWise	饮食习惯	饮食失控	可能	genotype_lookup	\N	GWV0000195	TAS2R38	A:A	A/G	2016-09-26 11:55:43.460042+08
3666	XYC6640385	P169120451	HealthWise	饮食习惯	饮食偏好	增强	genotype_lookup	\N	GWV0000121	ANKK1	A:A	A/G	2016-09-26 11:55:43.46479+08
3667	XYC6640385	P169120451	HealthWise	饮食习惯	饱腹感	易感知	genotype_lookup	\N	GWV0000050	FTO	A:T	A/T	2016-09-26 11:55:43.469497+08
3668	XYC6640385	P169120451	HealthWise	饮食习惯	饥饿感	正常	genotype_lookup	\N	GWV0000203	NMB	G:G	G/T	2016-09-26 11:55:43.474311+08
3669	XYC6640385	P169120451	HealthWise	饮食习惯	爱吃零食	正常	genotype_lookup	\N	GWV0000202	LEPR	A:G	A/G	2016-09-26 11:55:43.479179+08
3670	XYC6640385	P169120451	HealthWise	饮食习惯	爱吃甜食	正常	genotype_lookup	\N	GWV0000122	SLC2A2	G:G	A/G	2016-09-26 11:55:43.483914+08
3671	XYC6640385	P169120451	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	59.6199989	GWV0000167	ABCA1	C:C	C/T	2016-09-26 11:55:43.488768+08
3672	XYC6640385	P169120451	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	59.6199989	GWV0000146	ZNF259	C:G	C/G	2016-09-26 11:55:43.49374+08
3673	XYC6640385	P169120451	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	59.6199989	GWV0000204	CETP	A:C	A/C	2016-09-26 11:55:43.49887+08
3674	XYC6640385	P169120451	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	59.6199989	GWV0000148	FADS1	C:C	C/T	2016-09-26 11:55:43.503771+08
3675	XYC6640385	P169120451	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	59.6199989	GWV0000170	GALNT2	G:G	A/G	2016-09-26 11:55:43.508877+08
3676	XYC6640385	P169120451	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	59.6199989	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:55:43.514338+08
3677	XYC6640385	P169120451	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	59.6199989	GWV0000205	LPL	C:C	C/G	2016-09-26 11:55:43.519361+08
3678	XYC6640385	P169120451	HealthWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	平均风险	metabolic_disease	59.6199989	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:55:43.524246+08
3679	XYC6640385	P169120451	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000139	CELSR2	G:G	G/T	2016-09-26 11:55:43.52888+08
3680	XYC6640385	P169120451	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000136	Intergenic	C:C	C/G	2016-09-26 11:55:43.533666+08
3681	XYC6640385	P169120451	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000137	MAFB	C:T	C/T	2016-09-26 11:55:43.538654+08
3682	XYC6640385	P169120451	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000207	HMGCR	T:T	A/T	2016-09-26 11:55:43.543549+08
3683	XYC6640385	P169120451	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000208	APOC1	A:A	A/G	2016-09-26 11:55:43.548533+08
3684	XYC6640385	P169120451	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000209	ABO	G:G	A/G	2016-09-26 11:55:43.553441+08
3685	XYC6640385	P169120451	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000210	TOMM40	C:C	C/T	2016-09-26 11:55:43.55838+08
3686	XYC6640385	P169120451	HealthWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	平均风险	metabolic_disease	49.0600014	GWV0000211	LDLR	A:A	A/G	2016-09-26 11:55:43.563252+08
3687	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000156	G6PC2	C:C	C/T	2016-09-26 11:55:43.568036+08
3688	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000157	GCK	G:G	A/G	2016-09-26 11:55:43.572986+08
3689	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000158	GCKR	C:C	C/T	2016-09-26 11:55:43.577908+08
3690	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000061	MTNR1B	C:C	C/G	2016-09-26 11:55:43.582676+08
3691	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000057	TCF7L2	C:C	C/T	2016-09-26 11:55:43.587492+08
3692	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000159	ADRA2A	G:G	G/T	2016-09-26 11:55:43.592218+08
3693	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000160	ADCY5	A:A	A/G	2016-09-26 11:55:43.596937+08
3694	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000161	CRY2	A:C	A/C	2016-09-26 11:55:43.601648+08
3695	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000162	FADS1	C:C	C/T	2016-09-26 11:55:43.606463+08
3696	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000163	GLIS3	A:C	A/C	2016-09-26 11:55:43.611163+08
3697	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000164	MADD	A:A	A/T	2016-09-26 11:55:43.616003+08
3698	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000165	PROX1	C:T	C/T	2016-09-26 11:55:43.620937+08
3699	XYC6640385	P169120451	HealthWise	代谢因子	血糖水平升高遗传风险	低于平均风险	metabolic_disease	53.0600014	GWV0000166	SLC2A2	T:T	A/T	2016-09-26 11:55:43.625832+08
3700	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000149	GCKR	C:C	C/T	2016-09-26 11:55:43.631102+08
3701	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000145	ANGPTL3	A:C	A/C	2016-09-26 11:55:43.63626+08
3702	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000146	ZNF259	C:G	C/G	2016-09-26 11:55:43.641079+08
3703	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000148	FADS1	C:C	C/T	2016-09-26 11:55:43.646042+08
3704	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000154	TRIB1	T:T	A/T	2016-09-26 11:55:43.651155+08
3705	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000158	GCKR	C:C	C/T	2016-09-26 11:55:43.656021+08
3706	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000206	MLXIPL	C:C	C/T	2016-09-26 11:55:43.660862+08
3707	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000205	LPL	C:C	C/G	2016-09-26 11:55:43.665722+08
3708	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000212	APOE	T:T	C/T	2016-09-26 11:55:43.670679+08
3709	XYC6640385	P169120451	HealthWise	代谢因子	甘油三酯水平升高遗传风险	低于平均风险	metabolic_disease	45.0299988	GWV0000213	APOA5	C:T	C/T	2016-09-26 11:55:43.675493+08
3710	XYC6640385	P169120451	HealthWise	运动效果	跟腱受伤	不易受伤	genotype_lookup	\N	GWV0000214	MMP3	C:T	C/T	2016-09-26 11:55:43.680252+08
3711	XYC6640385	P169120451	HealthWise	运动效果	最大吸氧量	较低	genotype_lookup	\N	GWV0000215	PPARGC1A	T:T	C/T	2016-09-26 11:55:43.684891+08
3712	XYC6640385	P169120451	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:55:43.689452+08
3713	XYC6640385	P169120451	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-26 11:55:43.694092+08
3714	XYC6640385	P169120451	HealthWise	运动效果	耐力训练效果	显著	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:55:43.698844+08
3715	XYC6640385	P169120451	HealthWise	运动效果	运动减脂效果	一般	genotype_lookup	\N	GWV0000205	LPL	C:C	C/G	2016-09-26 11:55:43.703677+08
3716	XYC6640385	P169120451	HealthWise	运动效果	运动提高高密度脂蛋白胆固醇水平	显著	genotype_lookup	\N	GWV0000216	PPARD	C:T	C/T	2016-09-26 11:55:43.708236+08
3717	XYC6640385	P169120451	HealthWise	运动效果	运动降压效果	显著	genotype_lookup	\N	GWV0000217	EDN1	G:T	G/T	2016-09-26 11:55:43.712834+08
3718	XYC6640385	P169120451	HealthWise	运动效果	运动提升胰岛素敏感性效果	显著	genotype_lookup	\N	GWV0000179	LIPC	C:C	C/T	2016-09-26 11:55:43.717402+08
3719	XYC6640385	P169120451	HealthWise	运动效果	运动减肥效果	显著	genotype_lookup	\N	GWV0000218	FTO	A:G	A/G	2016-09-26 11:55:43.722057+08
3720	XYC6640385	P169120451	HealthWise	运动效果	力量训练效果	显著	genotype_lookup	\N	GWV0000219	INSIG2	G:G	C/G	2016-09-26 11:55:43.726728+08
3721	XYC6560236	P168170329	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000167	ABCA1	C:C	C/T	2016-10-09 11:46:24.708957+08
3722	XYC6560236	P168170329	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000146	ZNF259	C:G	C/G	2016-10-09 11:46:24.716429+08
3723	XYC6560236	P168170329	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000204	CETP	C:C	A/C	2016-10-09 11:46:24.721408+08
3724	XYC6560236	P168170329	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000148	FADS1	C:C	C/T	2016-10-09 11:46:24.726365+08
3725	XYC6560236	P168170329	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000170	GALNT2	G:G	A/G	2016-10-09 11:46:24.731384+08
3726	XYC6560236	P168170329	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000179	LIPC	C:C	C/T	2016-10-09 11:46:24.736953+08
3727	XYC6560236	P168170329	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000205	LPL	C:C	C/G	2016-10-09 11:46:24.741965+08
3728	XYC6560236	P168170329	CardioWise	代谢因子	高密度脂蛋白胆固醇水平降低遗传风险	高于平均风险	metabolic_disease	64.4199982	GWV0000206	MLXIPL	C:T	C/T	2016-10-09 11:46:24.746863+08
3729	XYC6560236	P168170329	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000139	CELSR2	G:G	G/T	2016-10-09 11:46:24.751902+08
3730	XYC6560236	P168170329	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000136	Intergenic	C:G	C/G	2016-10-09 11:46:24.756652+08
3731	XYC6560236	P168170329	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000137	MAFB	T:T	C/T	2016-10-09 11:46:24.761474+08
3732	XYC6560236	P168170329	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000207	HMGCR	A:T	A/T	2016-10-09 11:46:24.766395+08
3733	XYC6560236	P168170329	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000208	APOC1	A:A	A/G	2016-10-09 11:46:24.771107+08
3734	XYC6560236	P168170329	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000209	ABO	A:G	A/G	2016-10-09 11:46:24.775876+08
3735	XYC6560236	P168170329	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000210	TOMM40	C:C	C/T	2016-10-09 11:46:24.780673+08
3736	XYC6560236	P168170329	CardioWise	代谢因子	低密度脂蛋白胆固醇水平升高遗传风险	高于平均风险	metabolic_disease	64.8099976	GWV0000211	LDLR	G:G	A/G	2016-10-09 11:46:24.785511+08
3737	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000149	GCKR	T:T	C/T	2016-10-09 11:46:24.790048+08
3738	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000145	ANGPTL3	A:A	A/C	2016-10-09 11:46:24.794925+08
3739	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000146	ZNF259	C:G	C/G	2016-10-09 11:46:24.799828+08
3740	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000148	FADS1	C:C	C/T	2016-10-09 11:46:24.804679+08
3741	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000154	TRIB1	A:A	A/T	2016-10-09 11:46:24.809476+08
3742	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000158	GCKR	T:T	C/T	2016-10-09 11:46:24.814217+08
3743	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000206	MLXIPL	C:T	C/T	2016-10-09 11:46:24.818987+08
3744	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000205	LPL	C:C	C/G	2016-10-09 11:46:24.825246+08
3745	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000212	APOE	T:T	C/T	2016-10-09 11:46:24.830074+08
3746	XYC6560236	P168170329	CardioWise	代谢因子	甘油三酯水平升高遗传风险	高风险	metabolic_disease	73.8499985	GWV0000213	APOA5	C:C	C/T	2016-10-09 11:46:24.834908+08
3747	XYC6560236	P168170329	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.839999974	GWV0000223	PITX2	C:T	C/T	2016-10-09 11:46:24.839659+08
3748	XYC6560236	P168170329	CardioWise	风险评估	心房颤动	平均风险	risk_estimation_bin	0.839999974	GWV0000224	IL6R	C:T	C/T	2016-10-09 11:46:24.844432+08
3749	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000226	CXCL12	T:T	C/T	2016-10-09 11:46:24.849178+08
3750	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000193	ALDH2	A:G	A/G	2016-10-09 11:46:24.853925+08
3751	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000227	BRAP	C:T	C/T	2016-10-09 11:46:24.858839+08
3752	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000228	WDR35	T:T	C/T	2016-10-09 11:46:24.863969+08
3753	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000229	GUCY1A3	G:T	G/T	2016-10-09 11:46:24.868902+08
3754	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000230	C6orf10	A:G	A/G	2016-10-09 11:46:24.873586+08
3755	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000231	ATP2B1	C:T	C/T	2016-10-09 11:46:24.878247+08
3756	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000232	HLA,DRB-DQB	C:C	C/T	2016-10-09 11:46:24.882996+08
3757	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000233	ADTRP	G:G	A/G	2016-10-09 11:46:24.887786+08
3758	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000234	CDKN2B-AS1	A:A	A/C	2016-10-09 11:46:24.892741+08
3759	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000235	PDGFD	C:C	C/T	2016-10-09 11:46:24.897604+08
3760	XYC6560236	P168170329	CardioWise	风险评估	冠心病	平均风险	risk_estimation_bin	1.17999995	GWV0000236	HNF1A	G:T	G/T	2016-10-09 11:46:24.902813+08
3761	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000237	LIPA	T:T	C/T	2016-10-09 11:46:24.907488+08
3762	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000238	TCF21	C:C	C/G	2016-10-09 11:46:24.912102+08
3763	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000239	LTA	C:C	A/C	2016-10-09 11:46:24.916862+08
3764	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000240	PSMA6	C:G	C/G	2016-10-09 11:46:24.921488+08
3765	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000241	MIAT	C:C	C/T	2016-10-09 11:46:24.926069+08
3766	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000242	LGALS2	G:G	A/G	2016-10-09 11:46:24.930816+08
3767	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000243	CDKN2B-AS1	A:A	A/G	2016-10-09 11:46:24.935591+08
3768	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000244	CXCL12	C:C	C/T	2016-10-09 11:46:24.940333+08
3769	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000245	MIA3	A:C	A/C	2016-10-09 11:46:24.945092+08
3770	XYC6560236	P168170329	CardioWise	风险评估	心肌梗死	平均风险	risk_estimation_bin	0.879999995	GWV0000246	IRX1	C:C	C/T	2016-10-09 11:46:24.950091+08
3771	XYC6560236	P168170329	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000199	MTHFR	A:G	A/G	2016-10-09 11:46:24.954827+08
3772	XYC6560236	P168170329	CardioWise	风险评估	静脉血栓	平均风险	risk_estimation	0.949999988	GWV0000247	PROC	C:C	C/T	2016-10-09 11:46:24.959477+08
3773	XYC6560236	P168170329	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.409999996	GWV0000052	CLEC16A	T:T	G/T	2016-10-09 11:46:24.964042+08
3774	XYC6560236	P168170329	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.409999996	GWV0000053	PTPN22	G:G	C/G	2016-10-09 11:46:24.968704+08
3775	XYC6560236	P168170329	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.409999996	GWV0000054	IL2RA	T:T	C/T	2016-10-09 11:46:24.97325+08
3776	XYC6560236	P168170329	CardioWise	风险评估	I型糖尿病	平均风险	risk_estimation_bin	0.409999996	GWV0000055	IFIH1	T:T	C/T	2016-10-09 11:46:24.977831+08
3777	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000056	SLC30A8	T:T	C/T	2016-10-09 11:46:24.982434+08
3778	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000057	TCF7L2	C:C	C/T	2016-10-09 11:46:24.987024+08
3779	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000058	KCNJ11	C:T	C/T	2016-10-09 11:46:24.99206+08
3780	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000059	PPARG	C:C	C/G	2016-10-09 11:46:24.996776+08
3781	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000060	CDKN2B	T:T	C/T	2016-10-09 11:46:25.001457+08
3782	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000061	MTNR1B	G:G	C/G	2016-10-09 11:46:25.006046+08
3783	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000062	CDKAL1	A:C	A/C	2016-10-09 11:46:25.010872+08
3784	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000063	HHEX	C:T	C/T	2016-10-09 11:46:25.015785+08
3785	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000064	IGF2BP2	A:A	A/C	2016-10-09 11:46:25.020528+08
3786	XYC6560236	P168170329	CardioWise	风险评估	II型糖尿病	高于平均风险	risk_estimation_bin	1.45000005	GWV0000065	KCNQ1	C:C	C/T	2016-10-09 11:46:25.025241+08
3787	XYC6560236	P168170329	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000186	BCAT1	C:C	A/C	2016-10-09 11:46:25.029885+08
3788	XYC6560236	P168170329	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000187	FGF5	A:T	A/T	2016-10-09 11:46:25.034662+08
3789	XYC6560236	P168170329	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000188	PLEKHA7	C:C	C/T	2016-10-09 11:46:25.039388+08
3790	XYC6560236	P168170329	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000189	ATP2B1	A:G	A/G	2016-10-09 11:46:25.044034+08
3791	XYC6560236	P168170329	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000190	CSK	A:A	A/C	2016-10-09 11:46:25.048909+08
3792	XYC6560236	P168170329	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000191	CAPZA1	A:C	A/C	2016-10-09 11:46:25.053613+08
3793	XYC6560236	P168170329	CardioWise	风险评估	高血压	平均风险	risk_estimation_bin	0.620000005	GWV0000192	CYP17A1	C:T	C/T	2016-10-09 11:46:25.058403+08
3794	XYC6560236	P168170329	CardioWise	药物反应	$\\beta$受体阻滞剂对心力衰竭患者生存益处	正常	genotype_lookup	\N	GWV0000248	GRK5	A:A	A/T	2016-10-09 11:46:25.063002+08
3795	XYC6560236	P168170329	CardioWise	药物反应	氯吡格雷代谢	慢代谢	genotype_lookup	\N	GWV0000249	CYP2C19	A:A	A/G	2016-10-09 11:46:25.067612+08
3796	XYC6560236	P168170329	CardioWise	药物反应	氯吡格雷代谢	慢代谢	genotype_lookup	\N	GWV0000250	CYP2C19	G:G	A/G	2016-10-09 11:46:25.07234+08
3797	XYC6560236	P168170329	CardioWise	药物反应	氯吡格雷代谢	慢代谢	genotype_lookup	\N	GWV0000251	CYP2C19	A:A	A/G	2016-10-09 11:46:25.077016+08
3798	XYC6560236	P168170329	CardioWise	药物反应	氯吡格雷代谢	慢代谢	genotype_lookup	\N	GWV0000252	CYP2C19	C:C	C/T	2016-10-09 11:46:25.081692+08
3799	XYC6560236	P168170329	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000260	AGTR1	T:T	A/T	2016-10-09 11:46:25.086453+08
3800	XYC6560236	P168170329	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000261	AGTR1	T:T	C/T	2016-10-09 11:46:25.091219+08
3801	XYC6560236	P168170329	CardioWise	药物反应	培哚普利对稳定性冠心病的治疗效果	有效	allele_count_new	\N	GWV0000262	BDKRB1	G:G	A/G	2016-10-09 11:46:25.095945+08
3802	XYC6560236	P168170329	CardioWise	药物反应	他汀引起肌病	不太可能	genotype_lookup	\N	GWV0000263	SLCO1B1	T:T	C/T	2016-10-09 11:46:25.100692+08
3803	XYC6560236	P168170329	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000130	CYP4F2	C:C	C/T	2016-10-09 11:46:25.105856+08
3804	XYC6560236	P168170329	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-10-09 11:46:25.110611+08
3805	XYC6560236	P168170329	CardioWise	药物反应	华法林敏感性	高	genotype_lookup	\N	GWV0000265	VKORC1	T:T	C/T	2016-10-09 11:46:25.115851+08
3806	XYC6560236	P168170329	CardioWise	药物反应	氯沙坦代谢	快代谢	genotype_lookup	\N	GWV0000264	CYP2C9	A:A	A/C	2016-10-09 11:46:25.121065+08
3807	XYC6560236	P168170329	CardioWise	药物反应	硝酸甘油缓解心绞痛效果	低效	genotype_lookup	\N	GWV0000193	ALDH2	A:G	A/G	2016-10-09 11:46:25.125743+08
3808	XYC6560236	P168170329	CardioWise	药物反应	咖啡因代谢	快	genotype_lookup	\N	GWV0000222	CYP1A2	A:A	A/C	2016-10-09 11:46:25.130398+08
3809	XYC6560236	P168170329	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果较差	genotype_lookup	\N	GWV0000199	MTHFR	A:G	A/G	2016-10-09 11:46:25.135039+08
3810	XYC6560236	P168170329	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果较差	genotype_lookup	\N	GWV0000173	MTHFR	T:T	G/T	2016-10-09 11:46:25.139667+08
3811	XYC6560236	P168170329	CardioWise	药物反应	叶酸治疗高同型半胱氨酸	效果较差	genotype_lookup	\N	GWV0000360	MTRR	A:A	A/G	2016-10-09 11:46:25.14447+08
\.


--
-- Name: gene_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: genopipe
--

SELECT pg_catalog.setval('gene_results_id_seq', 3811, true);


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY reports (id, accession, barcode, pdf_path, test_product, plate_id, state, params, created_at) FROM stdin;
29	XYC6640393	P168310044	\N	HealthWise	1802049239	Pending	\N	2016-09-26 11:52:06.286907+08
30	XYC6640386	P169120449	\N	HealthWise	1802049239	Pending	\N	2016-09-26 11:52:06.290873+08
31	XYC6640385	P169120451	\N	HealthWise	1802049239	Pending	\N	2016-09-26 11:55:43.732921+08
19	XYC6560238	P168220014	/var/www/xy3/storage/reports/P168220014_CardioWise.pdf	CardioWise	1802049238	Completed	\N	2016-09-08 10:35:50.040725+08
9	XYC6560250	P167270187	/var/www/xy3/storage/reports/P167270187_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.174545+08
2	XYC6400204	P167130172	\N	HealthWise	1802049231	Pending	\N	2016-08-26 15:03:13.515662+08
22	XYC6560233	P168160792	\N	CardioWise	1802049238	Pending	\N	2016-09-08 10:35:50.052277+08
23	XYC6560234	P168160788	\N	CardioWise	1802049238	Pending	\N	2016-09-08 10:35:50.055895+08
12	XYC6560236	P168170329	/var/www/xy3/storage/reports/P168170329_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.186222+08
7	XYC6560244	P168020117	/var/www/xy3/storage/reports/P168020117_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.166711+08
6	XYC6560248	P167270186	/var/www/xy3/storage/reports/P167270186_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.162954+08
5	XYC6560239	P168230028	/var/www/xy3/storage/reports/P168230028_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.157848+08
13	XYC6560245	P168020113	/var/www/xy3/storage/reports/P168020113_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.190055+08
3	XYC6560281	P167230072	/var/www/xy3/storage/reports/P167230072_HealthWise.pdf	HealthWise	1802049231	Updated	\N	2016-08-26 15:03:13.520562+08
20	XYC6560237	P168190032	/var/www/xy3/storage/reports/P168190032_CardioWise.pdf	CardioWise	1802049238	Completed	\N	2016-09-08 10:35:50.04439+08
10	XYC6560246	P168020116	/var/www/xy3/storage/reports/P168020116_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.178445+08
8	XYC6640293	P168250037	/var/www/xy3/storage/reports/P168250037_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.170454+08
14	XYC6560229	P15C280643	/var/www/xy3/storage/reports/P15C280643_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.193864+08
11	XYC6560249	P167270185	/var/www/xy3/storage/reports/P167270185_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-02 14:47:57.182154+08
4	XYC6400201	P167150159	/var/www/xy3/storage/reports/P167150159_HealthWise.pdf	HealthWise	1802049231	Updated	\N	2016-08-26 15:03:13.524396+08
21	XYC6560281	P167230072	/var/www/xy3/storage/reports/P167230072_CardioWise.pdf	CardioWise	1802049238	Updated	\N	2016-09-08 10:35:50.047967+08
24	XYC6560235	P168170068	/var/www/xy3/storage/reports/P168170068_CardioWise.pdf	CardioWise	1802049238	Updated	\N	2016-09-08 10:35:50.059566+08
15	XYC6560232	P167291284	/var/www/xy3/storage/reports/P167291284_HealthWise.pdf	HealthWise	1802049234	Updated	\N	2016-09-08 10:34:59.368357+08
32	XYC6560236	P168170329	/var/www/xy3/storage/reports/P168170329_CardioWise.pdf	CardioWise	1802049238	Updated	\N	2016-10-09 11:46:25.150253+08
25	XYC6640387	P169120450	\N	HealthWise	1802049239	Pending	\N	2016-09-26 11:52:06.270797+08
26	XYC6640384	P169120133	\N	HealthWise	1802049239	Pending	\N	2016-09-26 11:52:06.275484+08
27	XYC6640394	P168290068	\N	HealthWise	1802049239	Pending	\N	2016-09-26 11:52:06.279379+08
28	XYC6640389	P167270184	\N	HealthWise	1802049239	Pending	\N	2016-09-26 11:52:06.283212+08
16	XYC6560231	P168120026	/var/www/xy3/storage/reports/P168120026_HealthWise.pdf	HealthWise	1802049234	Completed	\N	2016-09-08 10:34:59.372893+08
17	XYC6560247	P168020114	/var/www/xy3/storage/reports/P168020114_HealthWise.pdf	HealthWise	1802049234	Completed	\N	2016-09-08 10:34:59.376768+08
18	XYC6560251	P167290010	/var/www/xy3/storage/reports/P167290010_CardioWise.pdf	CardioWise	1802049238	Completed	\N	2016-09-08 10:35:50.036739+08
\.


--
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: genopipe
--

SELECT pg_catalog.setval('reports_id_seq', 32, true);


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY roles (role_id, name, descr, created_at, updated_at) FROM stdin;
1	admin	Administrator	2016-08-11 13:43:03.956161+08	2016-08-11 13:43:03.956161+08
2	common_user	Common	2016-08-11 13:43:03.959023+08	2016-08-11 13:43:03.959023+08
3	specimen_viewer	查看样本	2016-08-11 13:43:03.975175+08	2016-08-11 13:43:03.975175+08
4	report_viewer	查看报告	2016-08-11 13:43:03.976952+08	2016-08-11 13:43:03.976952+08
5	report_operator	编辑报告结果及建议	2016-08-11 13:43:03.978704+08	2016-08-11 13:43:03.978704+08
\.


--
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: genopipe
--

SELECT pg_catalog.setval('roles_role_id_seq', 5, true);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: genopipe
--

SELECT pg_catalog.setval('user_id_seq', 4, true);


--
-- Data for Name: user_log; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY user_log (id, user_id, from_ip, log_level, log_event, descr, created_at) FROM stdin;
1	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":null,"label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":null,"created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-11T13:43:03.965018+08:00","deleted_at":null}	2016-08-11 13:43:03.965018+08
2	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":null,"created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-11T14:29:40.757312+08:00","deleted_at":null}	2016-08-11 14:29:40.757312+08
3	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDcwOTgzOTc4","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-11T14:39:38.293886+08:00","deleted_at":null}	2016-08-11 14:39:38.293886+08
4	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDcxMDUyOTE0","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-12T09:48:34.637363+08:00","deleted_at":null}	2016-08-12 09:48:34.637363+08
5	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDcxMDUzNTYy","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-12T09:59:22.904041+08:00","deleted_at":null}	2016-08-12 09:59:22.904041+08
6	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxNzIuMzAuMi40OTsxNDcxMDU0MDQ1","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-08-12T10:07:25.531181+08:00","deleted_at":null}	2016-08-12 10:07:25.531181+08
7	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":"$2y$10$cVDLV9FnwUAQp1F/sPQ/ouwNnvYr6vjz4evuanDgHnJsviD3cQH2G","label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxNzIuMzAuMi40OTsxNDcxMDU0MDQ1","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-08-12T10:07:38.823003+08:00","deleted_at":null}	2016-08-12 10:07:38.823003+08
8	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDcxMDU0MjU2","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-12T10:10:56.207855+08:00","deleted_at":null}	2016-08-12 10:10:56.207855+08
9	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDcxMzk3MTE4","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-16T09:25:18.189992+08:00","deleted_at":null}	2016-08-16 09:25:18.189992+08
10	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMy4xMDM7MTQ3MTQ4ODE4NQ==","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-17T10:43:05.4835+08:00","deleted_at":null}	2016-08-17 10:43:05.4835+08
11	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDcxNTc5NTQ4","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-18T12:05:48.760302+08:00","deleted_at":null}	2016-08-18 12:05:48.760302+08
12	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxODMuMTY5LjM5LjE2NzsxNDcxNjYwMDQ5","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-19T10:27:29.960407+08:00","deleted_at":null}	2016-08-19 10:27:29.960407+08
13	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxODMuMTY5LjM5LjE2NzsxNDcxNjYxMjU5","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-19T10:47:39.229534+08:00","deleted_at":null}	2016-08-19 10:47:39.229534+08
14	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":"$2y$10$cVDLV9FnwUAQp1F/sPQ/ouwNnvYr6vjz4evuanDgHnJsviD3cQH2G","label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2NjsxNDcyMjAzNDg5","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-08-25T17:24:49.632769+08:00","deleted_at":null}	2016-08-25 17:24:49.632769+08
15	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDcyMjcwMjkx","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-08-26T11:58:11.411041+08:00","deleted_at":null}	2016-08-26 11:58:11.411041+08
16	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDcyNzg4NTA5","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-09-01T11:55:09.657325+08:00","deleted_at":null}	2016-09-01 11:55:09.657325+08
17	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDcyOTU5Mzg3","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-09-03T11:23:07.674771+08:00","deleted_at":null}	2016-09-03 11:23:07.674771+08
18	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxODMuMTY5LjM5LjE2MjsxNDczMzg2MDQx","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-09-08T09:54:01.046926+08:00","deleted_at":null}	2016-09-08 09:54:01.046926+08
19	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDczMzg2MDg0","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-09-08T09:54:44.216526+08:00","deleted_at":null}	2016-09-08 09:54:44.216526+08
20	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2NjsxNDcyMjAzNDg5","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-09-08T09:56:06.933803+08:00","deleted_at":null}	2016-09-08 09:56:06.933803+08
21	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxNzIuMzAuMi40OTsxNDczMzg2Mjkw","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-09-08T09:58:10.483424+08:00","deleted_at":null}	2016-09-08 09:58:10.483424+08
22	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2NjsxNDczMzg3NTg3","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-09-08T10:19:47.892468+08:00","deleted_at":null}	2016-09-08 10:19:47.892468+08
23	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2MjsxNDczNDcwOTE5","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-09-09T09:28:39.498481+08:00","deleted_at":null}	2016-09-09 09:28:39.498481+08
24	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2MjsxNDczODEzOTg3","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-09-13T08:46:27.331873+08:00","deleted_at":null}	2016-09-13 08:46:27.331873+08
25	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDczODE4NTk5","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-09-13T10:03:19.660582+08:00","deleted_at":null}	2016-09-13 10:03:19.660582+08
26	U000004	\N	INFO	update	{"user_id":"U000004","name":"liying","password":null,"label":"李莹","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwNDsxNzIuMzAuMi40OTsxNDczODE4NzMy","created_at":"2016-09-13T10:05:12.478179+08:00","updated_at":"2016-09-13T10:05:32.195979+08:00","deleted_at":null}	2016-09-13 10:05:32.195979+08
27	U000003	\N	INFO	update	{"user_id":"U000003","name":"zhaolingling","password":null,"label":"赵玲玲","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMzsxODMuMTY5LjM5LjE2NjsxNDczODIzMzU5","created_at":"2016-09-13T10:04:47.695937+08:00","updated_at":"2016-09-13T11:22:39.642454+08:00","deleted_at":null}	2016-09-13 11:22:39.642454+08
28	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2MjsxNDczODk5Nzc2","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-09-14T08:36:16.307407+08:00","deleted_at":null}	2016-09-14 08:36:16.307407+08
29	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2NjsxNDczOTA1Njgy","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-09-14T10:14:42.326929+08:00","deleted_at":null}	2016-09-14 10:14:42.326929+08
30	U000003	\N	INFO	update	{"user_id":"U000003","name":"zhaolingling","password":null,"label":"赵玲玲","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMzsxODMuMTY5LjM5LjE2NjsxNDczOTA4OTAw","created_at":"2016-09-13T10:04:47.695937+08:00","updated_at":"2016-09-14T11:08:20.504721+08:00","deleted_at":null}	2016-09-14 11:08:20.504721+08
31	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2NjsxNDc0OTQ3NTY5","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-09-26T11:39:29.006745+08:00","deleted_at":null}	2016-09-26 11:39:29.006745+08
32	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2NjsxNDc2MDY3MzA5","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-10-09T10:41:49.570988+08:00","deleted_at":null}	2016-10-09 10:41:49.570988+08
33	U000001	\N	INFO	update	{"user_id":"U000001","name":"admin","password":"$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e","label":"admin","email":null,"descr":"Administrator","department_id":"XY","superuser":true,"remember_token":"VTAwMDAwMTsxNzIuMzAuMi40OTsxNDc2MDY3ODg3","created_at":"2016-08-11T13:43:03.960734+08:00","updated_at":"2016-10-09T10:51:27.380428+08:00","deleted_at":null}	2016-10-09 10:51:27.380428+08
34	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2MjsxNDc2MTQ1MTU4","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-10-10T08:19:18.526923+08:00","deleted_at":null}	2016-10-10 08:19:18.526923+08
35	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2NjsxNDc2MTY3NzEx","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-10-10T14:35:11.720433+08:00","deleted_at":null}	2016-10-10 14:35:11.720433+08
36	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2MjsxNDc2MjQ0OTEz","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-10-11T12:01:53.181232+08:00","deleted_at":null}	2016-10-11 12:01:53.181232+08
37	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2NjsxNDc2MzQxNTg0","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-10-12T14:53:04.376005+08:00","deleted_at":null}	2016-10-12 14:53:04.376005+08
38	U000002	\N	INFO	update	{"user_id":"U000002","name":"wangyaqin","password":null,"label":"王雅琴","email":"","descr":"","department_id":"XY","superuser":false,"remember_token":"VTAwMDAwMjsxODMuMTY5LjM5LjE2MjsxNDc2NDkwNTE2","created_at":"2016-08-12T09:58:44.895684+08:00","updated_at":"2016-10-14T08:15:16.980247+08:00","deleted_at":null}	2016-10-14 08:15:16.980247+08
\.


--
-- Name: user_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: genopipe
--

SELECT pg_catalog.setval('user_log_id_seq', 38, true);


--
-- Data for Name: user_role; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY user_role (user_id, role_id) FROM stdin;
U000001	1
U000002	2
U000002	3
U000002	5
U000002	4
U000003	2
U000003	3
U000003	5
U000003	4
U000004	2
U000004	3
U000004	5
U000004	4
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY users (user_id, name, password, label, email, descr, department_id, superuser, remember_token, created_at, updated_at, deleted_at) FROM stdin;
U000004	liying	\N	李莹			XY	f	VTAwMDAwNDsxNzIuMzAuMi40OTsxNDczODE4NzMy	2016-09-13 10:05:12.478179+08	2016-09-13 10:05:32.195979+08	\N
U000003	zhaolingling	\N	赵玲玲			XY	f	VTAwMDAwMzsxODMuMTY5LjM5LjE2NjsxNDczOTA4OTAw	2016-09-13 10:04:47.695937+08	2016-09-14 11:08:20.504721+08	\N
U000001	admin	$2y$10$U2W8MtJRNIDiaAGCHWNCW.RX/5QauymIN.5rIkiHzkopdV0XZbI5e	admin	\N	Administrator	XY	t	VTAwMDAwMTsxNzIuMzAuMi40OTsxNDc2MDY3ODg3	2016-08-11 13:43:03.960734+08	2016-10-09 10:51:27.380428+08	\N
U000002	wangyaqin	\N	王雅琴			XY	f	VTAwMDAwMjsxODMuMTY5LjM5LjE2MjsxNDc2NDkwNTE2	2016-08-12 09:58:44.895684+08	2016-10-14 08:15:16.980247+08	\N
\.


--
-- Data for Name: xy_conclusions; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY xy_conclusions (report_id, genetic, environment, conclusion, recommendation, signature) FROM stdin;
3	•抗病能力（疾病易感基因位点）——高血压、老年黄斑变性和肥胖症的风险为平均风险；\r\n•代谢相关基因位点信息——血脂异常为平均或低于平均风险\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的酒精代谢能力强，但咖啡代谢慢，苦味敏感度强、乳糖不耐受；\r\n•饮食相关基因位点信息—饮食类型推荐低碳饮食，易感知饱腹感，饮食偏好增高；\r\n• 维生素水平相关基因位点信息——维生素B12和B6水平降低遗传风险增高，维生素E和叶酸水平降低水平风险增高；\r\n•运动相关基因位点信息——运动容易导致跟腱受伤，运动对提高耐量及减肥减脂效果显著\r\n，且对降压和提高高密度脂蛋白效果较好；	• 抗病能力——您目前血压水平升高（135/93mmHg）；\r\n• 饮食——喜爱熏制、腌制类，甜点，辛辣食物；水果和蔬菜摄入不足；                                      \r\n• 体重——您目前体型正常；\r\n• 运动——您基本不参加运动；\r\n• 遗传特质方面——您吸烟、饮酒，偶尔喝咖啡；\r\n• 代谢方面（血糖和血脂）——血脂和血糖水平正常，同型半胱氨酸正常高值；	1.您的基因检测提示您高血压、肥胖、血脂异常风险较低，目前体检这些指标水平亦处于正常。但慢性病是遗传和环境因素共同作用的结果，因此请您继续保持良好的生活方式，以持续维持低风险的理想状态。\r\n2.运动对您有诸多益处，请您适量增加运动，但需要注意跟腱保护；您的酒精代谢能力强，提示酒量较好，大量饮酒同样对健康有害，请保持适度状态；您的咖啡代谢较慢，请您注意避免过量引用；苦味敏感度强，且您日常饮食口味较重，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳； \r\n3.你长期吸烟，但基因检测提示你尼古丁依赖正常，建议您从健康出发，逐渐戒烟；\r\n4.维生素营养方面，请您适度增加维生素B12和B6、维生素E和叶酸的摄入，目前您体检同型半胱氨酸为正常高值，也提示您需要补充维生素B族和叶酸。	\N	王雅琴
12	•抗病能力（疾病易感基因位点）——高血压病和老年黄斑变性发病风险为平均风险； \r\n•代谢相关基因位点信息——血脂异常发病风险增高，而血糖增高风险低于平均风险；\r\n•体重管理相关基因位点信息——肥胖症的遗传风险为平均风险，减肥易反弹；\r\n•遗传特质基因位点信息——您的酒精代谢能力弱、咖啡因代谢快、苦味敏感度强、乳糖不耐症；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，适合低脂水饮食，爱吃零食，易感知饱腹感，饮食偏好增强；\r\n•维生素水平相关基因位点信息——维生素B6、维生素E和叶酸水平降低遗传风险增高；\r\n•运动相关基因位点信息——运动对提高耐力效果显著，且对提高胰岛素敏感性效果较好；但对减肥减脂效果一般。	您本次体检结果显示：  \r\n• 抗病能力——您目前已患高血压病；\r\n• 饮食——细粮为主，水果和蔬菜摄入量可；                                       \r\n• 运动——运动适量；\r\n• 遗传特质方面——饮食偏咸，熏制、腌制类、辛辣；饮酒；不吸烟；不喝咖啡；\r\n• 代谢方面（血糖和血脂）——血脂异常（高密度脂蛋白降低、甘油三酯增高）。	1. 您的基因检测提示您高血压病发病为平均风险，但当前您已患高血压病；遗传风险为不可改变危险因素，请您加强遗传因素以外风险的管理，请规律服药，同时改善生活方式，控制血压于理想水平；\r\n2. 您的基因检测提示您的血脂异常发病风险增高，本次体检存在相关的血脂异常。遗传风险不能改变，但除去遗传因素外，血脂水平还与其他因素密切相关，如生活行为习惯、药物因素等均可影响血脂水平。因此建议您重点从生活方式入手，做到健康合理饮食、坚持运动、戒烟限酒，必要时在医生的指导下使用调脂药物；每3-6个月复查血脂水平。\r\n3. 您基因检测提示肥胖症、老年黄斑变性和血糖增高风险为平均风险，以上慢性病是遗传和环境因素共同作用的结果，如遗传风险较低，请重点关注生活方式，持续保持低风险状态；\r\n4. 您的酒精代谢能力弱，您饮酒时可能出现心率加快，外周血管扩张，心排血量增加，面部潮红等现象，建议您适时控制饮酒量；苦味敏感度强可能会习惯性增加其他添加剂的摄入，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢快，因此因咖啡因过量导致的疾病风险较少。\r\n5. 您的基因检测提示运动对您有诸多益处（提高体质和维持血糖平衡），但对您降压和升高高密度脂蛋白效果一般，您目前每周保持合适的运动量，很好，请继续坚持；\r\n6. 维生素营养方面，请您适度增加鱼油，维生素B6、维生素E和叶酸的摄入。	\N	王雅琴
18	•心血管病患病风险基因位点信息--Ⅰ型糖尿病风险增高，其他高血压病、Ⅱ型糖尿病、冠心病、静脉血栓、心房颤动、心肌梗死发生风险为平均风险； \r\n•代谢因子相关基因位点信息——甘油三酯增高和高密度脂蛋白降低遗传风险增高；低密度脂蛋白水平升高的风险较低；\r\n•心血管用药基因位点信息——华法林的敏感性增强，氯吡格雷为中间代谢型，氯沙坦为快代谢型；存在他汀类药物引起肌病的风险；硝酸甘油缓解心绞痛效果显著；叶酸水平降低风险较高；	•血压——已患高血压病，本次体检血压水平升高（156/100mmHg）；\r\n•血脂——甘油三酯水平增高，其他血脂水平基本正常；\r\n•血糖——血糖水平正常\r\n•同型半胱氨酸——同型半胱氨酸正常高值；	•您本次遗传位点检测结果高血压发病风险为平均风险，提示您患高血压病的遗传风险较低。\r\n但临床资料提示您患高血压病。高血压的发生不仅仅与遗传因素相关，性别、年龄、吸烟、饮酒、饮食、体重指数、血脂水平、社会心理因素以及精神应激等都是高血压的危险因素。因此，请您更应注意遗传外危险因素的管理，继续定期复查，接受专业医师诊治，控制血压于理想水平。\r\n•您本次遗传位点检测结果Ⅱ型糖尿病、冠心病、房颤等发生风险为平均风险。体检提示您血糖水平正常，亦无相关心血管病的临床证据。心血管病是遗传因素和环境因素共同作用的结果，您的遗传风险不高，请重点关注环境因素，持续保持低风险状态。\r\n•您本次基因检测结果提示甘油三酯水平升高和高密度脂蛋白降低遗传风险增高，本次体检检测您的甘油三酯水平亦高于正常，但高密度脂蛋白水平正常。遗传风险不能改变，但除去遗传因素外，血脂水平还与其他因素密切相关，如生活行为习惯、药物因素等均可影响血脂水平。因此建议您重点从生活方式入手，做到健康合理饮食、坚持运动、戒烟限酒，每6-12个月复查血脂水平。\r\n•您本次基因检测结果提示您叶酸水平降低风险较高，体检同型半胱氨酸水平正常高值，建议日常生活中适量补充叶酸；\r\n•您本次基因检测结果提示心血管用药方面：华法林敏感性增高，使用时需注意出血风险；\r\n氯吡格雷为中间代谢型，抗凝效果一般，使用时监测凝血四项，必要时增加剂量；降压方面，可使用氯沙坦和培哚普利；使用他汀类降脂时，需留意肌病副作用。	\N	王雅琴
5	•抗病能力（疾病易感基因位点）——老年黄斑变性为高于平均风险；高血压和肥胖症的发病风险为平均风险； \r\n•代谢相关基因位点信息——血脂异常风险为平均或低于平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的酒精代谢能力快、咖啡因代谢快、苦味敏感度强、乳糖不耐症；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，爱吃零食、易感知饱腹感，饮食偏好增强；\r\n•维生素水平相关基因位点信息——维生素B6、维生素D、维生素E降低遗传风险增高；\r\n•运动相关基因位点信息——运动容易导致跟腱受伤，运动对提高耐量及运动减脂效果显著\r\n，且对降压和提高胰岛素敏感性效果较好；	• 抗病能力——您目前血压水平正常（113/72mmHg）；\r\n• 饮食——水果和蔬菜摄入不足；                                       \r\n• 体重——您目前体型偏瘦；\r\n• 运动——运动量不足；\r\n• 遗传特质方面——偶尔喝咖啡；不吸烟、不饮酒；口味清淡\r\n• 代谢方面（血糖和血脂）——血脂和血糖水平正常；	1.您的基因检测提示高血压、肥胖症和血脂异常的发病风险为平均风险或低于平均风险，且本次体检您的血压、血脂和体重均处于正常水平；但高血压病、血脂异常和肥胖均属于慢性病，是由遗传和环境因素共同作用的结果，且随着年龄增加，发病风险亦会增加，因此请您继续保持良好的生活方式，以持续维持低风险的理想状态。此外，您的老年黄斑变性风险增高，请日常生活中可佩带深色眼镜，避免紫外线损害，可口服维生素C、维生素E、Zn、叶黄素、玉米黄质可防止自由基对细胞的损害，保护视细胞；同时继续保持不吸烟和饮酒。 \r\n2.运动对您有诸多益处，请您适量增加运动，但需要注意跟腱保护；您的酒精代谢能力强，提示酒量较好，大量饮酒同样对健康有害，您目前不饮酒，请继续保持；苦味敏感度强，可能会习惯性增加其他添加剂的摄入，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢快，因此因咖啡因过量导致的疾病风险较少。\r\n3.维生素营养方面，请您适度增加鱼油、维生素B6、维生素D、维生素E的摄入。	\N	王雅琴
8	•抗病能力（疾病易感基因位点）——高血压、老年黄斑变性和肥胖症的发病风险均高于平均风险；\r\n•代谢相关基因位点信息——甘油三酯增高和高密度脂蛋白降低风险高于平均风险，其他为平均风险或低于平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的肌肉爆发力强、酒精代谢能力快、咖啡因代谢快、苦味敏感度强、乳糖不耐症；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，爱吃零食、易感知饱腹感，\r\n•维生素水平相关基因位点信息——维生素A、维生素B12、维生素B6、维生素D、维生素E降低遗传风险增高；\r\n•运动相关基因位点信息——运动容易导致跟腱受伤，运动对提高耐量及减肥减脂效果显著\r\n，且对降压和提高胰岛素敏感性效果较好；	• 抗病能力——您目前血压水平正常（113/72mmHg）；\r\n• 饮食——水果和蔬菜摄入不足；                                       \r\n• 体重——您目前体型偏瘦；\r\n• 运动——运动量不足；\r\n• 遗传特质方面——偶尔喝咖啡；\r\n• 代谢方面（血糖和血脂）——血脂和血糖水平正常；	1.您的基因检测提示您老年黄斑变性、高血压、肥胖症、血脂异常（甘油三酯和高密度脂蛋白异常）发病的遗传风险增高，但目前体检这些指标水平处于正常。以上慢性病是遗传和环境因素共同作用的结果，且随着年龄增加，发病风险亦会增加，因此请您继续保持良好的生活方式，以持续维持低风险的理想状态。\r\n2.运动对您有诸多益处，请您适量增加运动，但需要注意跟腱保护；您的酒精代谢能力强，提示酒量较好，大量饮酒同样对健康有害，请保持适度状态；苦味敏感度强，且您日常饮食口味较重，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳； \r\n3.维生素营养方面，请您适度增加维生素A、维生素B12、维生素B6、维生素D、维生素E的摄入，维生素A也有利于降低保护眼睛，降低老年黄斑变性风险。	\N	\N
6	•抗病能力（疾病易感基因位点）——高血压、肥胖症、老年黄斑变性为高于平均风险或高风险； \r\n•代谢相关基因位点信息——血脂异常风险为平均或低于平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的酒精代谢能力快、咖啡因代谢慢、苦味敏感度强、乳糖不耐症；甜味敏感度低；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，爱吃零食、易感知饱腹感，饮食偏好增强；\r\n•维生素水平相关基因位点信息——维生素A、维生素B12、维生素B6、维生素E降低遗传风险增高；\r\n•运动相关基因位点信息——运动容易导致跟腱受伤，运动对提高力量、耐量及运动减脂效果显著，且对降压和提高胰岛素敏感性效果较好；	• 家族史——母亲有高血压病；                                                                          \r\n• 抗病能力——您目前血压水平正常（123/73mmHg）；\r\n• 饮食——水果和蔬菜摄入达标；                                       \r\n• 体重——您目前体型正常；\r\n• 运动——运动量适当；\r\n• 遗传特质方面——不喝咖啡；不吸烟、偶尔饮酒；口味清淡；\r\n• 代谢方面（血糖和血脂）——血脂和血糖水平正常；	1.您的基因检测提示您高血压、肥胖症和老年黄斑变性的风险高于平均风险，但本次体检这些指标水平处于正常。以上疾病属于慢性病，是遗传和环境因素共同作用的结果，且随着年龄增加，发病风险亦会增加，因此请您继续保持良好的生活方式，以持续维持低风险的理想状态。\r\n2.运动对您有诸多益处，但需要注意跟腱保护；\r\n3.您的酒精代谢能力强，提示酒量较好，大量饮酒同样对健康有害；苦味敏感度强和甜味敏感度低，可能会习惯性增加其他添加剂的摄入，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢慢，目前没有饮咖啡的习惯，如饮请留意避免过量。\r\n4.维生素营养方面，请您适度增加鱼油，维生素A、维生素B12、维生素B6、维生素E的摄入；维生素A也有利于降低保护眼睛，降低老年黄斑变性风险。	\N	王雅琴
19	•心血管病患病风险基因位点信息--Ⅰ型糖尿病、高血压病和冠心病的遗传风险增高，其他Ⅱ型糖尿病、静脉血栓、心房颤动、心肌梗死发生风险为平均风险； \r\n•代谢因子相关基因位点信息——甘油三酯增高和高密度脂蛋白降低遗传风险增高；低密度脂蛋白水平升高的风险较低；\r\n•心血管用药基因位点信息——华法林的敏感性增强，氯吡格雷为快代谢型，氯沙坦为快代谢型；他汀类药物引起肌病的风险较低；硝酸甘油缓解心绞痛效果欠佳；叶酸水平降低风险较高；	您本次体检结果显示：                                                                 \r\n•血压——本次体检血压水平正常（129/82mmHg）；\r\n•血脂——总胆固醇和低密度脂蛋白水平增高，高密度脂蛋白水平降低；\r\n•血糖——血糖水平正常；\r\n•同型半胱氨酸——同型半胱氨酸水平正常；	•您本次遗传位点检测结果Ⅰ型糖尿病、高血压病和冠心病的遗传风险增高，但临床体检资料未提示相关临床证据。除遗传因素外，以上慢病还与年龄、性别、不良生活方式、血脂、体重等因素相关。遗传风险不能更改，请您更应重点关注环境因素，如吸烟、饮酒、运动、饮食、精神应激等，尽量降低环境因素，以降低Ⅰ型糖尿病、高血压病和冠心病的发病风险。\r\n•您本次遗传位点检测结果Ⅱ型糖尿病、静脉血栓、心房颤动、心肌梗死等发生风险为平均风险。体检提示您血糖水平正常，亦无相关心血管病的临床证据。心血管病是遗传因素和环境因素共同作用的结果，您的遗传风险不高，请重点关注环境因素，持续保持低风险状态。\r\n•您本次基因检测结果提示甘油三酯水平增高和高密度脂蛋白降低遗传风险增高，本次体检检测您的高密度脂蛋白水平降低，但甘油三酯水平正常。遗传风险不能改变，但除去遗传因素外，血脂水平还与其他因素密切相关，如生活行为习惯、药物因素等均可影响血脂水平。因此建议您重点从生活方式入手，做到健康合理饮食、坚持运动、戒烟限酒，每3-6个月复查血脂水平，必要时使用调脂药物。\r\n•您本次基因检测结果提示您叶酸水平降低风险较高，但体检同型半胱氨酸水平正常，请您动态监测同型半胱氨酸水平，必要时适量补充叶酸；\r\n•您本次基因检测结果提示心血管用药方面：抗凝方面华法林和氯吡格雷的效果均较好，使用时需注意剂量，留意出血风险；降压方面，可使用氯沙坦和培哚普利；硝酸甘油缓解心绞痛效果欠佳，不推荐使用。	\N	王雅琴
9	•抗病能力（疾病易感基因位点）——高血压和肥胖症患病风险高于平均风险；老年黄斑变性为平均风险； \r\n•代谢相关基因位点信息——血脂异常风险为平均或低于平均风险；血糖水平升高遗传风险增高；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的肌肉爆发力较弱，酒精代谢能力弱、咖啡因代谢快、苦味敏感度强、乳糖不耐症；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，爱吃零食、易感知饱腹感；\r\n•维生素水平相关基因位点信息——维生素B6和维生素E降低遗传风险增高；\r\n•运动相关基因位点信息——运动容易导致跟腱受伤，运动对提高耐量及运动减肥效果显著，且对提高高密度脂蛋白胆固醇水平和胰岛素敏感性效果较好；	您本次体检结果显示： \r\n• 抗病能力——您血压水平正常（102/63mmHg）；\r\n• 饮食——水果和蔬菜摄入达标；                                       \r\n• 体重——您目前体型基本正常；\r\n• 运动——运动量适量；\r\n• 遗传特质方面——口味清淡，细粮为主，经常吃鱼和海鲜，不喝咖啡，吸烟但已戒，常饮酒； \r\n• 代谢方面（血糖和血脂）——血脂和血糖水平正常；	1.您的基因检测提示您高血压病、血糖和肥胖症发病高于平均风险，本次体检您的血压、血糖和体型基本正常，但高血压、糖尿病和肥胖属于慢性病，是遗传和环境因素共同作用的结果，且随着年龄增加，发病风险亦会增加，因此请您继续保持良好的生活方式，以持续维持低风险的理想状态。\r\n2.您的基因检测提示运动对您有诸多益处，运动时需注意跟腱保护；\r\n3.您的酒精代谢能力弱，提示您饮酒时可能出现心率加快，外周血管扩张，心排血量增加，面部潮红等现象，建议您适时控制饮酒量；苦味敏感度强可能会习惯性增加其他添加剂的摄入，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢快，因此因咖啡因过量导致的疾病风险较少。\r\n4.维生素营养方面，请您适度增加鱼油，维生素B6和维生素E的摄入。	\N	王雅琴
7	•抗病能力（疾病易感基因位点）——高血压患病风险高于平均风险；肥胖症和老年黄斑变性为平均风险； \r\n•代谢相关基因位点信息——血脂异常风险为平均或低于平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的肌肉爆发力较弱，酒精代谢能力强、咖啡因代谢快、苦味敏感度强、乳糖不耐症、甜味敏感度低；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，适合地中海饮食，爱吃零食、易感知饱腹感，饮食偏好增强；\r\n•维生素水平相关基因位点信息——维生素A、维生素B12、维生素B6、维生素D、维生素E降低遗传风险增高；\r\n•运动相关基因位点信息——运动容易导致跟腱受伤，运动对提高耐量及运动减脂效果显著，且对提高高密度脂蛋白胆固醇水平和胰岛素敏感性效果较好；	• 家族史——父亲有高血压病；                                                                            • 抗病能力——您目前已患高血压病，血压水平正常（140/88mmHg）；\r\n• 饮食——水果和蔬菜摄入达标；                                       \r\n• 体重——您目前体型正常；\r\n• 运动——运动量少；\r\n• 遗传特质方面——偶尔喝咖啡；吸烟；口味偏咸，喜熏制、腌制类、甜点、辛辣类食物；饮酒；\r\n• 代谢方面（血糖和血脂）——血脂增高，血糖水平正常；	1.您的基因检测提示您高血压病发病高于平均风险，且您有高血压病家族史，当前您已患高血压病，请规律服药，控制血压于理想水平；\r\n2.您的基因检测虽提示您的血脂异常风险较低，但本次体检您存在血脂增高；请您重点关注生活方式改善；\r\n3.肥胖症和老年黄斑变性的遗传风险为平均风险，但您体型正常且无眼科相关疾病征象，但血脂异常、肥胖和老年黄斑变性属于慢性病，是遗传和环境因素共同作用的结果，且随着年龄增加，发病风险亦会增加，因此请您改善生活方式，以持续维持低风险的理想状态。\r\n4.您的基因检测提示虽运动对降压效果一般，但还有诸多益处，请适量增加运动量，运动时需注意跟腱保护；\r\n5.您的酒精代谢能力强，提示酒量较好，大量饮酒同样对健康有害；苦味敏感度强和甜味敏感度低，可能会习惯性增加其他添加剂的摄入，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢快，因此因咖啡因过量导致的疾病风险较少。\r\n6.维生素营养方面，请您适度增加鱼油，维生素A、维生素B12、维生素B6、维生素D、维生素E的摄入。	\N	王雅琴
10	•抗病能力（疾病易感基因位点）——肥胖症风险高于平均风险；高血压和老年黄斑变性为平均风险； \r\n•代谢相关基因位点信息——血脂异常风险高于平均风险，血糖增高风险低于平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的肌肉爆发力较弱，酒精代谢能力弱、咖啡因代谢快、苦味敏感度强、乳糖不耐症、甜味敏感度低；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，适合均衡饮食，易感知饱腹感，饮食偏好增强；\r\n•维生素水平相关基因位点信息——维生素A、维生素B6、维生素D、维生素E降低遗传风险增高；\r\n•运动相关基因位点信息——运动容易导致跟腱受伤，运动对提高耐量及运动减肥减脂效果显著，且对提高胰岛素敏感性效果较好；	您本次体检结果显示：  \r\n• 抗病能力——您目前血压水平正常（121/73mmHg）；\r\n• 饮食——水果和蔬菜摄入不足；                                       \r\n• 体重——您目前体型正常；\r\n• 运动——运动适量；\r\n• 遗传特质方面——不饮酒；吸烟；口味偏咸，喜辛辣类食物；偶尔喝咖啡；\r\n• 代谢方面（血糖和血脂）——血脂异常（高密度脂蛋白降低、甘油三酯增高），血糖水平正常；	1.您的基因检测提示您肥胖症发病高于平均风险，本次体检体型正常；血脂异常风险高于平均风险，本次体检提示血脂异常；血糖和血压发病遗传风险为平均风险，本次体检血糖血压水平症状。以上慢性病是遗传和环境因素共同作用的结果，且随着年龄增加，发病风险亦会增加，如遗传风险较低，请关注生活方式，重点干预；如遗传风险较高，更应该重点改善生活方式，必要时药物辅助干预；因此请您继续保持良好的生活方式，以持续维持低风险的理想状态。\r\n2.您的基因检测提示运动对您有诸多益处（减脂、提高体质和维持血糖平衡），您每周保持良好的运动量，很好，请继续保持，运动时需注意跟腱保护；\r\n3.您的酒精代谢能力弱，您饮酒时可能出现心率加快，外周血管扩张，心排血量增加，面部潮红等现象，建议您适时控制饮酒量；苦味敏感度强可能会习惯性增加其他添加剂的摄入，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢快，因此因咖啡因过量导致的疾病风险较少。\r\n4.维生素营养方面，请您适度增加鱼油，维生素A、维生素B6、维生素D、维生素E的摄入。	\N	王雅琴
11	•抗病能力（疾病易感基因位点）——高血压风险高于平均风险；肥胖症和老年黄斑变性为平均风险； \r\n•代谢相关基因位点信息——血脂异常和血糖增高风险为平均风险或低于平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；脂联素水平降低风险增高；\r\n•遗传特质基因位点信息——您的酒精代谢能力强、咖啡因代谢慢、苦味敏感度强、乳糖不耐症；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，适合低碳水饮食，易感知饱腹感；\r\n•维生素水平相关基因位点信息——维生素A、维生素B12、维生素E降低遗传风险增高；\r\n•运动相关基因位点信息——运动容易导致跟腱受伤，运动对提高耐力效果显著，但对减肥减脂效果一般，且对降压效果和提高胰岛素敏感性效果较好；	您本次体检结果显示：  \r\n• 家族史——母亲有高血压病和冠心病；\r\n• 抗病能力——您目前已患高血压病，血压水平正常（121/77mmHg）；\r\n• 饮食——细粮为主，水果和蔬菜摄入量可；                                       \r\n• 体重——您目前体型超重；\r\n• 运动——运动适量；\r\n• 遗传特质方面——饮食清淡，偶尔饮酒；不吸烟；不喝咖啡；\r\n• 代谢方面（血糖和血脂）——血脂异常（高密度脂蛋白降低、低密度脂蛋白增高），空腹血糖增高（6.71mmol/l）；	1. 您的基因检测提示您高血压病发病高于平均风险，且您有高血压病家族史，当前您已患高血压病，请规律服药，同时改善生活方式，控制血压于理想水平；\r\n2. 您的基因检测提示肥胖症、血脂异常和血糖增高风险为平均风险或低于平均风险，但本次体检血糖、血脂、体重均超标；以上慢性病是遗传和环境因素共同作用的结果，如遗传风险较低，请重点关注生活方式； \r\n2.您的基因检测提示运动对您有诸多益处（降压和维持血糖平衡），您每周保持良好的运动量，很好，请继续保持，运动时需注意跟腱保护；\r\n3.您的酒精代谢能力强，提示酒量较好，大量饮酒同样对健康有害；苦味敏感度强可能会习惯性增加其他添加剂的摄入，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢慢，目前没有经常饮咖啡的习惯，如饮请留意避免过量。\r\n4.维生素营养方面，请您适度增加鱼油，维生素A、维生素B12、维生素E的摄入。	\N	王雅琴
24	•代谢因子相关基因位点信息——血脂异常风险为平均风险或低于平均风险\r\n•风险评估——Ⅰ型和Ⅱ型糖尿病、房颤、冠心病、静脉血栓、心肌梗死发病风险为平均风险，高血压发病风险增高；\r\n•心血管个体化用药——华法林敏感性增高，氯吡格雷代谢和氯沙坦代谢为快代谢型；培哚普利对稳定性冠心病的治疗效果差；叶酸治疗高同型半胱氨酸效果极差；	•血压——血压水平升高（135/94mmHg）；\r\n•血脂——甘油三酯水平增高，其他血脂水平基本正常；\r\n•血糖——血糖水平正常\r\n•同型半胱氨酸——同型半胱氨酸正常高值；	•您本次遗传位点检测结果高血压发病风险高于平均风险，提示您患高血压病的遗传风险较高。且目前临床检查提示您血压水平增高，遗传风险为不可改变危险因素，请您加强遗传因素以外风险的管理，血压水平的调控，完善24小时动态血压监测，明确诊断，心血管内科科就诊。高血压药物治疗方面，推荐氯沙坦，不推荐培哚普利；\r\n•您本次基因检测结果提示甘油三酯水平升高遗传风险为平均风险，此结果仅表明从您的遗传角度提示您患高甘油三脂血症的风险偏低。但除去遗传因素外，血脂水平还与其他因素密切相关，如生活行为习惯、药物因素等均可影响血脂水平。您本次血生化检查提示甘油三酯水平高于参考范围，考虑主要为不良生活习惯所致，因此建议您重点从调整生活方式入手，做到健康合理饮食、坚持运动、戒烟限酒，必要时在医生的指导下使用调脂药物。\r\n•Ⅰ型和Ⅱ型糖尿病、房颤、冠心病、静脉血栓、心肌梗死发病风险为平均风险，但心血管相关疾病为遗传因素和环境因素综合作用的结果，虽然遗传风险没有提示增高，但需要重点关注生活方式，保持良好的生活方式结合您的遗传背景，有利于降低心血管事件的总体风险。	\N	王雅琴
13	•抗病能力（疾病易感基因位点）——高血压发病风险高于平均风险；肥胖症和老年黄斑变性发病风险为平均风险； \r\n•代谢相关基因位点信息——血脂异常发病风险增高，而血糖增高风险为平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的酒精代谢能力弱、咖啡因代谢慢、苦味敏感度强、乳糖不耐症；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，爱吃零食，易感知饱腹感，可能出现饮食失控；\r\n•维生素水平相关基因位点信息——维生素A、维生素B12、维生素B2、维生素B6、叶酸和维生素D、维生素E水平降低遗传风险增高；\r\n•运动相关基因位点信息——运动对提高耐力效果显著，减肥效果一般，减脂效果显著，且运动对提高高密度脂蛋白水平和胰岛素敏感性效果较好；	•\t家族史 ——高血压病、糖尿病家族史；\r\n• 抗病能力——您本次体检测量血压增高，164/79mmHg；\r\n• 饮食——细粮为主，水果和蔬菜摄入量偏少；                                       \r\n• 运动——运动适量；\r\n• 遗传特质方面——饮食辛辣；饮酒；不吸烟；偶尔喝咖啡和含糖饮料；\r\n• 代谢方面（血糖和血脂）——血脂异常（甘油三酯和低密度脂蛋白胆固醇增高）	1. 您的基因检测提示您高血压病发病风险增高，本次体检您血压增高；请您连续三日测量血压或完善24小时动态血压测量，明确是否有高血压病；遗传风险为不可改变危险因素，请加强遗传因素以外的风险管理，改善生活方式，低盐饮食，控制饮酒量；\r\n2. 您的基因检测提示您的血脂异常发病风险增高，本次体检存在血脂异常。遗传风险不能改变，但除去遗传因素外，血脂水平还与其他因素密切相关，如生活行为习惯、药物因素等均可影响血脂水平。因此建议您重点从生活方式入手，做到健康合理饮食、坚持运动、限酒，每3-6个月复查血脂水平。\r\n3. 您基因检测提示肥胖症、老年黄斑变性为平均风险，以上慢性病是遗传和环境因素共同作用的结果，如遗传风险较低，请重点关注生活方式，持续保持低风险状态；\r\n4. 您的酒精代谢能力弱，您饮酒时可能出现心率加快，外周血管扩张，心排血量增加，面部潮红等现象，建议您适时控制饮酒量；苦味敏感度强可能会习惯性增加其他添加剂的摄入，请你清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢慢，目前没有经常饮咖啡的习惯，如饮请留意避免过量。\r\n5. 您的基因检测提示运动对您有诸多益处（提高体质和维持血糖平衡），您每周保持良好的运动量，很好，请继续保持，但运动对降压效果一般；\r\n6.维生素营养方面，鉴于您有多种维生素缺乏风险，请您日常生活中可适量补充多种维生素。	\N	王雅琴
14	• 抗病能力（疾病易感基因位点）——高血压、老年黄斑变性和肥胖症的风险为平均风险；\r\n• 饮食相关基因位点信息—饮食类型推荐低碳饮食，易感知饱腹感，饮食偏好增高；\r\n• 体重相关基因位点信息--减肥易反弹；\r\n• 运动相关基因位点信息——运动能显著提高耐量，同时对运动降压、降糖和提升高密度脂蛋白水平效果较好，但减肥减脂效果一般\r\n• 遗传特质基因位点信息——您的酒精代谢能力强，但存在苦味敏感度强、甜味敏感度低、乳糖不耐受\r\n• 维生素水平相关基因位点信息——Omega-6和Omega-3水平降低遗传风险增高，维生素E水平降低水平风险增高；\r\n• 代谢相关基因位点信息——血脂异常为平均或低于平均风险	• 抗病能力——您目前血压水平正常\r\n• 饮食——喜爱高油脂、油炸食品；甜点；吃零食；蔬菜摄入减少；                                                                          \r\n• 体重——您目前体型正常\r\n• 运动——您基本不参加运动\r\n• 遗传特质方面——您不吸烟、不饮酒，偶尔喝咖啡；\r\n• 代谢方面（血糖和血脂）——高密度脂蛋白降低，其他血脂和血糖水平正常	1.您的基因检测提示您高血压、肥胖、血脂异常风险较低，目前体检这些指标水平亦处于正常。但慢性病是遗传和环境因素共同作用的结果，因此请您继续保持良好的生活方式，以持续维持低风险的理想状态。\r\n2.您的高密度脂蛋白较低，建议您从饮食调节和运动两方面调节，核桃、大蒜、含亚油酸、杏仁、亚麻酸等食物和长期规律运动有助于提高高密度脂蛋白；且您的基因检测提示您运动有诸多益处，故请您增加运动锻炼；\r\n3.您的酒精代谢能力强，提示酒量较好，但大量饮酒同样对健康有害，请保持适度状态；同时注意适当限制甜食的摄入；  \r\n4.您的甜味敏感性强，且您喜甜食，请注意适当节制；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；\r\n5.维生素营养方面，请您适度增加鱼油（Omega-6和Omega-3）和维生素E的摄入。	\N	王雅琴
4	•抗病能力（疾病易感基因位点）——高血压、肥胖症的发病风险均高于平均风险；老年黄斑变性发病风险为平均风险；\r\n•代谢相关基因位点信息——血脂异常风险为平均或低于平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的酒精代谢能力快、苦味敏感度强、乳糖不耐症；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，爱吃零食、易感知饱腹感，\r\n•维生素水平相关基因位点信息——维生素A、维生素E和叶酸水平降低遗传风险增高；\r\n•运动相关基因位点信息——运动对力量和耐力训练效果显著，对减肥效果显著，对提高胰岛素敏感性效果显著；	您本次体检结果显示：                                                                  \r\n• 抗病能力——您目前血压水平正常（113/72mmHg）；\r\n• 饮食——水果和蔬菜摄入不足；                                       \r\n• 体重——您目前体型正常；\r\n• 运动——运动量不足；\r\n• 遗传特质方面——日常不喝咖啡和含糖饮料；\r\n• 代谢方面（血糖和血脂）——血糖水平正常，血脂水平增高；	1.您的基因检测提示您高血压和肥胖症的风险高于平均风险，但本次体检这些指标水平处于正常。血脂异常风险为平均风险或低于平均风险，但本次体检血脂水平增高；高血压、血脂异常和肥胖症属于慢性病，是遗传和环境因素共同作用的结果，且随着年龄增加，发病风险亦会增加，因此请您继续保持良好的生活方式，以持续维持低风险的理想状态。\r\n2.运动对您有诸多益处，请您适量增加运动；\r\n3.您的酒精代谢能力强，提示酒量较好，大量饮酒同样对健康有害，请保持适度状态；苦味敏感度强，且您日常饮食口味较重，请你留意，清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳； \r\n4.维生素营养方面，请您适度增加鱼油，维生素A、维生素E和叶酸的摄入。	\N	王雅琴
15	•抗病能力（疾病易感基因位点）——高血压病、肥胖症和老年黄斑变性发病风险为平均风险； \r\n•代谢相关基因位点信息——低密度脂蛋白胆固醇水平升高风险增加，其他血脂异常和血糖增高风险为平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的酒精代谢能力强、咖啡因代谢慢、苦味敏感度强、乳糖不耐症；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，适合低脂饮食，易感知饱腹感，可能出现饮食失控；\r\n•维生素水平相关基因位点信息——维生素B6和维生素E水平降低遗传风险增高；\r\n•运动相关基因位点信息——运动跟腱容易受伤，运动对提高耐力和力量训练效果显著，减肥效果一般，减脂效果显著，且运动对降压、维持血糖稳定和提高高密度脂蛋白水平效果较好；	•家族史 ——高血压病、冠心病、脑卒中家族史；\r\n•抗病能力——您本次体检测量血压正常，92/60mmHg；\r\n•饮食——饮食辛辣和热烫；水果和蔬菜摄入量适量；经常进食动物内脏；饮酒；不吸烟；                                      \r\n• 运动——运动量少；\r\n• 遗传特质方面——饮酒；不吸烟；偶尔喝咖啡和经常喝含糖饮料；\r\n• 代谢方面（血糖和血脂）——血脂正常、血糖正常；	1. 您的基因检测提示您高血压病、肥胖症和老年黄斑变性遗传发病风险为平均风险，本次体检血压、体重正常，亦未发现相关眼部病变；以上慢性病是遗传和环境因素共同作用的结果，如遗传风险较低，请重点关注生活方式，持续保持低风险状态；\r\n2. 您的基因检测提示您的低密度脂蛋白胆固醇水平升高风险增加，本次体检血脂和血糖代谢方面均正常，遗传风险不能改变，建议您继续保持良好的生活方式，降低环境因素风险；\r\n3. 您的酒精代谢能力强，提示酒量较好，但大量饮酒同样对健康有害，请保持适度状态；同时注意适当限制甜食的摄入；苦味敏感度强可能会习惯性增加其他添加剂的摄入，请你清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢慢，目前没有经常饮咖啡的习惯，如饮请留意避免过量。\r\n4. 您的基因检测提示运动对您有诸多益处（提高体质、降压、维持血糖血脂平衡），目前您每周的运动量偏少，请尽量保持一定的运动量；\r\n5. 维生素营养方面，请您适度增加维生素B6和维生素E的摄入；	\N	王雅琴
16	•抗病能力（疾病易感基因位点）——高血压病、肥胖症发病风险增高，老年黄斑变性发病风险为平均风险； \r\n•代谢相关基因位点信息——低密度脂蛋白胆固醇水平升高风险增加，其他血脂异常和血糖增高风险为平均风险或低于平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的酒精代谢能力弱、咖啡因代谢慢、苦味敏感度强、乳糖不耐症；\r\n•饮食相关基因位点信息—Omega-6和Omega-3水平降低遗传风险增高，适合低脂饮食，爱吃零食，不易感知饱腹，可能出现饮食失控；\r\n•维生素水平相关基因位点信息——维生素B6、维生素E和叶酸水平降低遗传风险增高；\r\n•运动相关基因位点信息——运动对提高耐力和减肥效果显著，运动减脂效果一般，且运动对降压、维持血糖稳定和提高高密度脂蛋白水平效果较好；	•\t抗病能力——您本次体检测量血压正常，108/60mmHg；肥胖体型，体重指数29.45；\r\n•\t饮食——喜欢口味和辛辣食物；水果和蔬菜摄入量适量； \r\n•\t运动——运动适量；\r\n•\t遗传特质方面——饮酒；吸烟已戒；不喝咖啡和含糖饮料；                                     \r\n•      代谢方面（血糖和血脂）——高密度脂蛋白降低、其他血脂水平和血糖水平正常；	1. 您的基因检测提示您高血压病、肥胖症发病风险增高，本次体检血压正常，但体重严重超标，以上慢性病是遗传和环境因素共同作用的结果，鉴于以上两种慢病遗传风险增高，请您更应该关注生活方式，尽量降低环境因素导致的风险增高；\r\n2. 您的基因检测提示您的低密度脂蛋白胆固醇水平升高风险增加，您本次体检高密度脂蛋白降低，其他血脂和血糖代谢方面均正常，遗传风险不能改变，请保持良好的生活方式，如增加运动帮助您提高高密度脂蛋白水平；\r\n3. 您的酒精代谢能力弱，您饮酒时可能出现心率加快，外周血管扩张，心排血量增加，面部潮红等现象，建议您适时控制饮酒量；苦味敏感度强可能会习惯性增加其他添加剂的摄入，请你清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢慢，目前没有经常饮咖啡的习惯，如饮请留意避免过量。\r\n4. 您的基因检测提示运动对您有诸多益处（提高体质、降压、维持血糖血脂平衡），目前您每周的运动量偏少，请尽量保持一定的运动量；\r\n5. 维生素营养方面，请您适度增加维生素B6、维生素E和叶酸的摄入；	\N	王雅琴
17	•抗病能力（疾病易感基因位点）——高血压病发病风险增高，肥胖症和老年黄斑变性发病风险为平均风险； \r\n•代谢相关基因位点信息——血脂异常和血糖增高风险为平均风险或低于平均风险；\r\n•体重管理相关基因位点信息--减肥易反弹；\r\n•遗传特质基因位点信息——您的酒精代谢能力弱、咖啡因代谢慢、苦味敏感度强、尼古丁依赖性强，乳糖不耐症；\r\n•饮食相关基因位点信息—适合均衡饮食，爱吃零食，易感知饱腹，饮食偏好增强；\r\n•维生素水平相关基因位点信息——维生素B6、维生素D和维生素E水平降低遗传风险增高；\r\n•运动相关基因位点信息——运动对提高耐力效果显著，运动减肥和减脂效果一般，且运动对降压和提高高密度脂蛋白水平效果较好；	•   代谢方面（血糖和血脂）——血脂水平正常，血糖代谢紊乱，存在糖耐量异常；\r\n•   抗病能力——血压正常 109/67mmHg；体重指数超标27.8为超体重；	1. 您的基因检测提示您高血压病、肥胖症发病风险增高，本次体检血压正常，但体重超标，以上慢性病是遗传和环境因素共同作用的结果，鉴于以上两种慢病遗传风险增高，请您更应该关注生活方式，尽量降低环境因素导致的风险增高；\r\n2. 您的基因检测提示您的血脂和血糖代谢异常风险较低，您本次体检血脂正常，糖耐量异常；遗传风险较低的情况下，请重点关注环境因素，保持良好的生活方式，持续保持低风险状态；\r\n3. 您的酒精代谢能力弱，您饮酒时可能出现心率加快，外周血管扩张，心排血量增加，面部潮红等现象，建议您适时控制饮酒量；苦味敏感度强可能会习惯性增加其他添加剂的摄入，请你清淡饮食；您有乳糖不耐受，您留意饮用奶制品的不适症状，必要时选择无乳糖配方乳；您的咖啡因代谢慢，目前没有经常饮咖啡的习惯，如饮请留意避免过量。\r\n4. 您的基因检测提示运动对您有诸多益处（提高体质、降压、维持血糖平衡），请您每周保持一定的运动量，有利于您控制血糖水平。\r\n5. 维生素营养方面，请您适度增加维生素B6、维生素D和维生素E的摄入。	\N	王雅琴
20	•心血管病患病风险基因位点信息——1型糖尿病、高血压、房颤的遗传风险增高，其他2型糖尿病、冠心病、静脉血栓、心肌梗死发生风险为平均风险； \r\n•代谢因子相关基因位点信息——甘油三酯增高、低密度脂蛋白增高和高密度脂蛋白降低遗传风险为平均风险/低于平均风险；\r\n•心血管用药基因位点信息——华法林的敏感性高，氯吡格雷为中间代谢型，氯沙坦为快代谢型；培哚普利对稳定性冠心病的治疗效果欠佳；他汀类药物引起肌病的风险低；硝酸甘油缓解心绞痛效果显著；叶酸水平降低风险较高；	您本次体检结果显示：                                                                  \r\n•血压——血压水平正常121/75mmHg；\r\n•血脂——甘油三酯水平增高2.63 mmol/l，高密度脂蛋白水平降低1.1 mmol/l；\r\n•血糖——血糖水平增高 6.7mmol/l；\r\n•同型半胱氨酸——同型半胱氨酸水平正常；	•您本次遗传位点检测结果显示，1型糖尿病、高血压、房颤的遗传风险高于平均风险，但临床体检资料未提示相关临床证据。除遗传因素外，以上慢病还与年龄、性别、不良生活方式、血脂、体重等因素相关。遗传风险不能更改，请您更应重点关注环境因素，如吸烟、饮酒、运动、饮食、精神应激等，尽量降低环境因素。\r\n•您本次遗传位点检测结果显示2型糖尿病、冠心病、静脉血栓、心肌梗死等发生风险为平均风险。体检提示您血糖水平正常，亦无相关心血管病的临床证据。心血管病是遗传因素和环境因素共同作用的结果，您的遗传风险不高，请重点关注环境因素，持续保持低风险状态。\r\n•您本次基因检测结果提示血脂异常的遗传风险较低，本次体检检测您的高密度脂蛋白水平降低，甘油三酯水平增高。遗传风险不能改变，但除去遗传因素外，血脂水平还与其他因素密切相关，如生活行为习惯、药物因素等均可影响血脂水平。因此建议您重点从生活方式入手，做到健康合理饮食、坚持运动、戒烟限酒，每3-6个月复查血脂水平，必要时使用调脂药物。\r\n•您本次基因检测结果提示您甲基化叶酸水平降低风险较高，易造成体内同型半胱氨酸水平增高，因此请您动态监测同型半胱氨酸水平，适量补充甲基化叶酸；\r\n•您本次基因检测结果提示心血管用药方面：降压方面，推荐使用氯沙坦，不建议使用培哚普利。抗凝方面华法林敏感性增高，如使用应留意出血风险；氯吡格雷抗凝效果差，不推荐使用。冠心病治疗方面，硝酸甘油缓解心绞痛效果好，推荐使用。	\N	王雅琴
21	•心血管病患病风险基因位点信息——房颤的遗传风险增高，其他1型糖尿病、2型糖尿病、高血压、冠心病、静脉血栓、心肌梗死发生风险为平均风险； \r\n•代谢因子相关基因位点信息——甘油三酯增高、低密度脂蛋白增高和高密度脂蛋白降低遗传风险为平均风险/低于平均风险；\r\n•心血管用药基因位点信息——华法林的敏感性高，氯吡格雷为慢代谢型，氯沙坦为快代谢型；培哚普利对稳定性冠心病的治疗有效；他汀类药物引起肌病的风险低；硝酸甘油缓解心绞痛效果显著；叶酸水平降低风险较高；	您本次体检结果显示：                                                                  \r\n•血压——血压增高135/93mmHg；\r\n•血脂——血脂水平正常；\r\n•血糖——血糖水平正常 4.3mmol/l；\r\n•同型半胱氨酸——同型半胱氨酸水平正常高值 13.5μmol/L；	•您本次遗传位点检测结果显示，房颤的遗传风险高于平均风险，但心电图资料未提示房颤。目前尚无心房颤动的临床证据，亦无家族史。房颤的发生不仅仅与遗传因素相关，与年龄的相关性也很高：60 岁以下的人群中，房颤的发病率小于1%；而80 岁以上的人群，其发病率高于6%；相同年龄段的人群中男性的发病率高于女性。请定期体检，如有心房颤动的临床表现（有心悸、心慌等）及时就诊，完善心电图检查。\r\n•您本次遗传位点检测结果显示血脂异常、1型糖尿病、2型糖尿病、高血压、冠心病、静脉血栓、心肌梗死等发生风险为平均风险。本次体检血压、血糖、血脂水平正常，亦无以上心血管病的阳性发现。心血管病是遗传因素和环境因素共同作用的结果，虽然您的遗传风险不高，但不要放松警惕，请重点关注环境因素，持续保持低风险状态。\r\n•您本次基因检测结果提示您甲基化叶酸水平降低风险较高，易造成体内同型半胱氨酸水平增高，因此请您动态监测同型半胱氨酸水平，适量补充甲基化叶酸；\r\n•您本次基因检测结果提示心血管用药方面：降压方面，推荐使用氯沙坦和培哚普利。抗凝方面华法林敏感性增高，如使用应留意出血风险；氯吡格雷抗凝效果差，不推荐使用。冠心病治疗方面，硝酸甘油缓解心绞痛效果好，推荐使用。	\N	王雅琴
32	心血管疾病及个性化用药基因检测合计分析84个SNP点：\r\n•心血管病患病风险基因位点信息——2型糖尿病的遗传风险增高，其他1型糖尿病、高血压病、冠心病、静脉血栓、心房颤动、心肌梗死发生风险为平均风险； \r\n•代谢因子相关基因位点信息——甘油三酯增高、低密度脂蛋白增高和高密度脂蛋白降低遗传风险增高；\r\n•心血管用药基因位点信息——华法林的敏感性高，氯吡格雷为慢代谢型，氯沙坦为快代谢型；他汀类药物引起肌病的风险低；硝酸甘油缓解心绞痛效果欠佳；叶酸水平降低风险较高；	您本次体检结果显示：                                                                  \r\n•血压——您目前已患高血压病；\r\n•血脂——甘油三酯水平增高，高密度脂蛋白水平降低；\r\n•血糖——血糖水平正常；	•您本次遗传位点检测结果显示，血糖增高的遗传风险低于平均风险（成人健康基因筛查），但2型糖尿病的遗传风险增高，但当前体检资料提示血糖水平正常，亦无2型糖尿病的临床证据。2型糖尿病的发生不仅仅只与血糖相关，还与胰岛素敏感性、胰岛素水平有关，此外环境因素，如年龄、肥胖、高热量饮食、体力活动不足、高脂血症、高血压等均为2型糖尿病的危险因素。血糖水平并不是一成不变，与饮食方式关联甚大，因此请您加强生活方式干预，尽量减少糖尿病的患病风险，同时定期监测血糖水平。\r\n•您本次遗传位点检测结果显示，冠心病、静脉血栓、心房颤动、心肌梗死发生风险为平均风险。当前亦无以上心血管疾病。心血管病是遗传因素和环境因素共同作用的结果，虽然您的心血管病患病遗传风险不高，请不要放松警惕，重点关注环境因素，持续保持低风险状态。 \r\n•您本次基因检测结果提示您甲基化叶酸水平降低风险较高，易造成体内同型半胱氨酸水平增高，因此请您动态监测同型半胱氨酸水平，适量补充甲基化叶酸；\r\n•您本次基因检测结果提示心血管用药：降压方面，推荐使用氯沙坦和培哚普利。抗凝方面华法林敏感性增高，如使用应留意出血风险；氯吡格雷抗凝效果差，不推荐使用。冠心病治疗方面，硝酸甘油缓解心绞痛效果欠佳，不推荐使用。	\N	王雅琴
\.


--
-- Data for Name: xy_specimen; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY xy_specimen (barcode, doc_id, name, gender, idc, dob, phone_no, company, collect_date, test_code, test_product, created_at) FROM stdin;
P167050081	P0045994	测试2	男	410803198205140546	1982-05-14	12345678	个人复查	2016-07-02	3812	HealthWise	2016-08-11 13:43:09.190119+08
P167270185	P0024686	程仲春	男	430122195602090311	1956-02-09	13607494788	望城公证处	2016-07-30	3814	HealthWise	2016-08-11 13:43:09.207361+08
P167270186	P0089825	王鸿	女	430122197212264928	1972-12-26	13974840939	望城公证处	2016-07-30	3814	HealthWise	2016-08-11 13:43:09.210453+08
P167270187	P0000769	谢启军	男	430122197310030359	1973-10-03	13975180333	望城公证处	2016-07-30	3814	HealthWise	2016-08-11 13:43:09.213453+08
P168020113	P0001594	佘正林	男	43010219551002301X	1955-10-02	13907482318	长沙市人力资源和社会保障局（市公务员）	2016-08-03	3814	HealthWise	2016-08-11 13:43:09.216452+08
P168020114	P0050126	喻其林	男	430103196308260530	1963-08-26	13508478501	长沙市人力资源和社会保障局（市公务员）	2016-08-03	3814	HealthWise	2016-08-11 13:43:09.219388+08
P168020116	P0003560	罗昶	男	430105196304280035	1963-04-28	13908468922	长沙市人力资源和社会保障局（市公务员）	2016-08-03	3814	HealthWise	2016-08-11 13:43:09.222849+08
P168020117	P0020042	周庆宪	男	430103195407131537	1954-07-13	13873163377	长沙市人力资源和社会保障局（市公务员）	2016-08-03	3814	HealthWise	2016-08-11 13:43:09.22573+08
P167230072	P2069934	王建林	男	430681196311245231	1963-11-24	13924649788	个人体检	2016-07-25	3813	HealthWise	2016-08-11 13:43:09.228791+08
P167130172	P0019988	陈金华	男	350321197305185254	1973-05-18	13707495738	个人复查	2016-07-13	3815	CardioWise	2016-08-11 13:43:09.197934+08
P167290010	P2033383	罗湘家	男	430419197008017477	1970-08-01	13907473610	个人体检网络订单	2016-07-29	3815	CardioWise	2016-08-11 13:43:09.204439+08
P167230072	P2069934	王建林	男	430681196311245231	1963-11-24	13924649788	个人体检	2016-07-25	3815	CardioWise	2016-08-11 13:43:09.231826+08
P15C280643	P0187185	樊宁	女	430104198311303541	1983-11-30	18900702059	湖南省宁乡县公安局	2016-08-11	3814	HealthWise	2016-08-15 01:00:02.257018+08
P168120026	PT302206	姚松柏	男	430102196210036016	1962-10-03	13508480018	省厅干复查	2016-08-12	3814	HealthWise	2016-08-16 01:00:01.782676+08
P167291284	P0123266	王坤	男	430181198305150035	1983-05-15	13755027146	湖南省电力公司浏阳市供电分公司	2016-08-16	3812	HealthWise	2016-08-20 01:00:02.208054+08
P168160788	P2026908	赵寿权	男	430521196712052615	1967-12-05	18285527777	个人体检	2016-08-17	3815	CardioWise	2016-08-21 01:00:01.965787+08
P168160792	P2070910	杨文会	女	500383198309102948	1983-09-10	15870282777	个人体检	2016-08-17	3815	CardioWise	2016-08-21 01:00:01.985155+08
P168170068	P2001199	李建雄	男	43062419621103005X	1962-11-03	13607408081	个人体检	2016-08-18	3816	CardioWise	2016-08-22 01:00:01.923626+08
P168220014	P2051133	唐桂玉	女	432624196308207925	1963-08-20	13807395461	个人体检	2016-08-22	3816	CardioWise	2016-08-25 18:09:12.432244+08
P168190032	P2039835	朱剑峰	男	432325197111160013	1971-11-16	13907378111	个人体检网络订单	2016-08-22	3816	CardioWise	2016-08-25 18:09:12.452522+08
P168230028	P2071114	王书如	女	432522198203014060	1982-03-01	17707486242	个人体检	2016-08-23	3812	HealthWise	2016-08-26 10:01:16.95274+08
P168250037	P2071214	李军	男	43092119960803851X	1996-08-03	15080783045	个人体检	2016-08-25	3812	HealthWise	2016-08-29 01:00:02.53372+08
P168290025	P2071327	邓凯中	男	430521197011240490	1970-11-24	15115988888	个人体检	2016-08-29	3816	CardioWise	2016-09-01 09:10:24.106028+08
P168200029	P2024798	余建新	男	430124197105186832	1971-05-18	13607499049	个人体检	2016-08-31	3816	CardioWise	2016-09-04 01:00:02.022322+08
P164190212	P0192671	肖村安	男	430124196807107313	1968-07-10	13723859388	宁乡县环卫局	2016-09-06	3815	CardioWise	2016-09-10 01:00:02.228436+08
P167270184	P0089823	程国奇	男	430303196605292038	1966-05-29	13907494756	望城公证处	2016-09-10	3814	HealthWise	2016-09-14 01:00:02.143503+08
P169120133	P2071805	尹华文	男	432624196901104716	1969-01-10	13828479706	个人体检	2016-09-12	3812	HealthWise	2016-09-16 01:00:02.301317+08
P169120449	P2071816	伍罗莎	女	440682199005155029	1990-05-15	18688803881	个人体检	2016-09-13	3813	HealthWise	2016-09-17 01:00:02.300137+08
P169120450	P2071817	吴继谦	男	430423198912040033	1989-12-04	15116828777	个人体检	2016-09-13	3813	HealthWise	2016-09-17 01:00:02.323707+08
P169120451	P2071818	吴思沅	女	430423198511240026	1985-11-24	18674714111	个人体检	2016-09-13	3813	HealthWise	2016-09-17 01:00:02.326875+08
P167280908	P0029309	肖艳娟	女	430102196704143743	1967-04-14	18673170361	北京银行长沙分行	2016-09-21	3812	HealthWise	2016-09-25 01:00:01.77427+08
P169260012	P0212717	李玉梅	女	430122196408052121	1964-08-05	15116100027	望城公证处	2016-09-26	3814	HealthWise	2016-09-30 01:00:02.395903+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3815	CardioWise	2016-10-09 11:20:50.113131+08
P168170329	P0032629	谢勇	男	430181196401270038	1964-01-27	13974949688	开福区县级领导	2016-08-19	3815	CardioWise	2016-10-09 11:20:50.113131+08
P168290068	P2071359	罗正辉	男	432322196611185918	1966-11-18	13807377858	个人体检	2016-08-30	3815	CardioWise	2016-10-09 11:20:50.113131+08
P168310044	P2071437	余暑纯	女	43010219460725002X	1946-07-25	18229773746	个人体检	2016-08-31	3815	CardioWise	2016-10-09 11:20:50.113131+08
P169190468	P2000793	杨鹏	男	430105196408040538	1964-08-04	13808411500	个人体检	2016-09-19	3815	CardioWise	2016-10-09 11:20:50.113131+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3812	HealthWise	2016-08-11 13:43:09.201395+08
P168170329	P0032629	谢勇	男	430181196401270038	1964-01-27	13974949688	开福区县级领导	2016-08-19	3812	HealthWise	2016-08-23 01:00:01.786445+08
P168290068	P2071359	罗正辉	男	432322196611185918	1966-11-18	13807377858	个人体检	2016-08-30	3812	HealthWise	2016-09-03 01:00:02.189469+08
P168310044	P2071437	余暑纯	女	43010219460725002X	1946-07-25	18229773746	个人体检	2016-08-31	3812	HealthWise	2016-09-04 01:00:02.042037+08
P169190468	P2000793	杨鹏	男	430105196408040538	1964-08-04	13808411500	个人体检	2016-09-19	3812	HealthWise	2016-09-23 01:00:02.526648+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3812	HealthWise	2016-10-11 17:01:31.165707+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3815	CardioWise	2016-10-11 17:01:31.175741+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3812	HealthWise	2016-10-12 01:00:02.306524+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3815	CardioWise	2016-10-12 01:00:02.317329+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3812	HealthWise	2016-10-13 01:00:01.892036+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3815	CardioWise	2016-10-13 01:00:01.903121+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3812	HealthWise	2016-10-14 01:00:02.429835+08
P167150159	P0019989	陈春珍	女	350321197007205229	1970-07-20	13875874555	个人复查	2016-07-15	3815	CardioWise	2016-10-14 01:00:02.440097+08
\.


--
-- Data for Name: xy_tijian; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY xy_tijian (barcode, class0, ksbm, orderitem, itemcode, itemname, result, unit, defvalue, created_at) FROM stdin;
P167230072	心血管病风险筛查	ec	动脉硬化检测	000003	检查结论	血管内皮扩张率正常范围内    提示您的血管内皮层功能很活跃，请维持现在血管的状态、注意生活习惯，一年后复查。			2016-08-11 13:44:12.783851+08
P168020113	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.53	mmol/l	高危人群<4.14;健康人<6.22	2016-08-19 01:00:02.570498+08
P168020113	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.9	mmol/l	<1.7	2016-08-19 01:00:02.567824+08
P168020113	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.48	mmol/l	1.16-1.42	2016-08-19 01:00:02.564986+08
P169260012	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.87	mmol/l	1.29-1.55	2016-09-30 01:00:04.281408+08
P169260012	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	4.83	mmol/l	高危人群<2.59;健康人<4.14	2016-09-30 01:00:04.284499+08
P169260012	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.26		0.17-0.45	2016-09-30 01:00:04.287715+08
P168020113	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	3.19	mmol/l	高危人群<2.59;健康人<4.14	2016-08-19 01:00:02.56252+08
P168020113	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.27		0.17-0.45	2016-08-19 01:00:02.560248+08
P169260012	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.6		1.5-2.5	2016-09-30 01:00:04.29083+08
P168020113	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.9		1.5-2.5	2016-08-19 01:00:02.557804+08
P168020113	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.33	mmol/l	3.9-6.1	2016-08-19 01:00:02.555359+08
P168020113	基本指标	yb	一般检查	010109	舒张压	79			2016-08-19 01:00:02.725445+08
P169260012	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.95	mmol/l	3.9-6.1	2016-09-30 01:00:04.293927+08
P169260012	心血管病风险筛查	hy	血小板聚集（AA血液科）	205307	血小板项目初始值	219	*10^9/L	100-300	2016-09-30 01:00:05.882941+08
P169260012	基本指标	yb	一般检查	010103	收缩压	158			2016-09-30 01:00:04.296915+08
P169260012	基本指标	yb	一般检查	010105	体重指数	27.24			2016-09-30 01:00:04.300016+08
P167230072	基本指标	None	None	100402	甘油三酯	1.49	mmol/l	<1.7	2016-08-11 13:44:12.625097+08
P167230072	基本指标	None	None	100505	低密度脂蛋白胆固醇	2.16	mmol/l	高危人群<2.59;健康人<4.14	2016-08-11 13:44:12.61971+08
P169260012	心血管病风险筛查	hy	血小板聚集（AA血液科）	205308	平均血小板体积初始值	10.27	fL	6.00-12.00	2016-09-30 01:00:05.886038+08
P169260012	基本指标	yb	一般检查	010109	舒张压	105			2016-09-30 01:00:04.30307+08
P15C280643	基本指标	hy	肝肾功能血脂血糖	100504	高密度脂蛋白胆固醇	0.97	mmol/l	1.29-1.55	2016-08-19 01:00:02.530976+08
P15C280643	基本指标	hy	肝肾功能血脂血糖	100505	低密度脂蛋白胆固醇	3.27	mmol/l	高危人群<2.59;健康人<4.14	2016-08-19 01:00:02.523321+08
P15C280643	基本指标	hy	肝肾功能血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.2		0.17-0.45	2016-08-19 01:00:02.525871+08
P15C280643	基本指标	hy	肝肾功能血脂血糖	107501	空腹血糖	4.78	mmol/l	3.9-6.1	2016-08-19 01:00:02.528448+08
P168020116	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	0.95	mmol/l	1.16-1.42	2016-08-19 01:00:02.578554+08
P168020116	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	2.72	mmol/l	<1.7	2016-08-19 01:00:02.575778+08
P168020116	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.08	mmol/l	高危人群<4.14;健康人<6.22	2016-08-19 01:00:02.573081+08
P167270187	心血管病风险筛查	ec	动脉硬化检测	000003	检查结论	血管内皮扩张率正常范围内    提示您的血管内皮层功能很活跃，请维持现在血管的状态、注意生活习惯，一年后复查。			2016-08-11 13:44:12.790039+08
P169260012	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	7.3	mmol/l	高危人群<4.14;健康人<6.22	2016-09-30 01:00:04.274121+08
P169260012	基本指标	yb	一般检查	010110	腰围	90			2016-09-30 01:00:04.306509+08
P169260012	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.32	mmol/l	<1.7	2016-09-30 01:00:04.278176+08
P169260012	腺癌/卵巢癌风险筛查	fk	妇科检查	000001	结论	慢性宫颈炎    建议6个月内复查			2016-09-30 01:00:04.320633+08
P169260012	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	14.2	μmol/L	0-15	2016-09-30 01:00:05.879804+08
P169260012	心血管病风险筛查	hy	血小板聚集（AA血液科）	205309	血小板最大聚集率	48.1	%	35.0-75.0	2016-09-30 01:00:05.889123+08
P168120026	基本指标	hy	肝肾功能血脂血糖	100504	高密度脂蛋白胆固醇	0.94	mmol/l	1.16-1.42	2016-08-19 01:00:02.513004+08
P167291284	基本指标	hy	肝肾功能血脂血糖	100401	总胆固醇	4.07	mmol/l	高危人群<4.14;健康人<6.22	2016-08-19 01:00:02.502817+08
P167291284	基本指标	hy	肝肾功能血脂血糖	100402	甘油三酯	0.9	mmol/l	<1.7	2016-08-19 01:00:02.500156+08
P167291284	基本指标	hy	肝肾功能血脂血糖	100504	高密度脂蛋白胆固醇	1.24	mmol/l	1.16-1.42	2016-08-19 01:00:02.497617+08
P167291284	基本指标	hy	肝肾功能血脂血糖	100505	低密度脂蛋白胆固醇	2.04	mmol/l	高危人群<2.59;健康人<3.12	2016-08-19 01:00:02.495005+08
P167291284	基本指标	hy	肝肾功能血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.3		0.17-0.45	2016-08-19 01:00:02.49236+08
P167291284	基本指标	hy	肝肾功能血脂血糖	107501	空腹血糖	3.61	mmol/l	3.9-6.1	2016-08-19 01:00:02.48856+08
P168120026	基本指标	hy	肝肾功能血脂血糖	100401	总胆固醇	3.55	mmol/l	高危人群<4.14;健康人<6.22	2016-08-19 01:00:02.518222+08
P168120026	基本指标	hy	肝肾功能血脂血糖	100402	甘油三酯	1.29	mmol/l	<1.7	2016-08-19 01:00:02.515605+08
P168120026	基本指标	hy	肝肾功能血脂血糖	100505	低密度脂蛋白胆固醇	2.02	mmol/l	高危人群<2.59;健康人<4.14	2016-08-19 01:00:02.510506+08
P168120026	基本指标	hy	肝肾功能血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.26		0.17-0.45	2016-08-19 01:00:02.50796+08
P168120026	基本指标	hy	肝肾功能血脂血糖	107501	空腹血糖	4.86	mmol/l	3.9-6.1	2016-08-19 01:00:02.505432+08
P15C280643	基本指标	hy	肝肾功能血脂血糖	100401	总胆固醇	4.77	mmol/l	高危人群<4.14;健康人<6.22	2016-08-19 01:00:02.520749+08
P15C280643	基本指标	hy	肝肾功能血脂血糖	100402	甘油三酯	1.17	mmol/l	<1.7	2016-08-19 01:00:02.533642+08
P168020117	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.33		0.17-0.45	2016-08-19 01:00:02.602931+08
P168020116	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.89	mmol/l	高危人群<2.59;健康人<4.14	2016-08-19 01:00:02.581247+08
P168020114	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.05	mmol/l	高危人群<4.14;健康人<6.22	2016-08-19 01:00:02.611044+08
P168020114	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.25	mmol/l	<1.7	2016-08-19 01:00:02.613643+08
P168020114	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.18	mmol/l	1.16-1.42	2016-08-19 01:00:02.61649+08
P168020114	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	3.3	mmol/l	高危人群<2.59;健康人<4.14	2016-08-19 01:00:02.619237+08
P168020114	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.23		0.17-0.45	2016-08-19 01:00:02.621937+08
P168020114	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	2.1		1.5-2.5	2016-08-19 01:00:02.624862+08
P168020117	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.9		1.5-2.5	2016-08-19 01:00:02.605748+08
P168020117	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.12	mmol/l	3.9-6.1	2016-08-19 01:00:02.60842+08
P169260012	心血管病风险筛查	hy	血小板聚集（AA血液科）	205310	血小板最大聚集点	5	P	3-8	2016-09-30 01:00:05.892139+08
P169260012	心血管病风险筛查	hy	血小板聚集（AA血液科）	205311	血小板平均聚集率	35.3	%	35.0-75.0	2016-09-30 01:00:05.895383+08
P169260012	心血管病风险筛查	hy	凝血常规检查（血液科）	105013	凝血酶时间（TT）	18	sec	14-21	2016-09-30 01:00:05.898478+08
P167230072	基本指标	None	None	010109	舒张压	93			2016-08-11 13:44:12.656084+08
P167291284	基本指标	yb	一般检查	010103	收缩压	92			2016-08-19 01:00:02.687775+08
P167291284	基本指标	yb	一般检查	010105	体重指数	19.77			2016-08-19 01:00:02.690473+08
P169260012	心血管病风险筛查	hy	凝血常规检查（血液科）	105055	凝血酶原时间	10.8	sec	9-14	2016-09-30 01:00:05.901709+08
P169260012	心血管病风险筛查	hy	凝血常规检查（血液科）	105059	凝血酶原国际标准化比值	0.94		0.8-1.5	2016-09-30 01:00:05.905001+08
P169260012	心血管病风险筛查	hy	凝血常规检查（血液科）	105060	活化部分凝血活酶时间	22.1	sec	20-40	2016-09-30 01:00:05.908048+08
P169260012	心血管病风险筛查	hy	凝血常规检查（血液科）	105063	纤维蛋白原浓度	3.25	g/L	2-4	2016-09-30 01:00:05.911045+08
P169260012	心血管病风险筛查	hy	血小板聚集（AA血液科）	205312	红细胞初始值	4.44	*10^12/L	4.00-5.50	2016-09-30 01:00:05.914079+08
P167291284	基本指标	yb	一般检查	010109	舒张压	60			2016-08-19 01:00:02.693116+08
P169260012	心血管病风险筛查	hy	血小板聚集（AA血液科）	205313	血小板最小聚集率	11.6	%	0-75	2016-09-30 01:00:05.916947+08
P169260012	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5.0	mg/L	0-10	2016-09-30 01:00:05.919953+08
P169260012	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	4	mg/L	0-3.00	2016-09-30 01:00:05.923044+08
P167130172	基本指标	None	None	100401	总胆固醇	4.49	mmol/l	高危人群<4.14;健康人<6.22	2016-08-11 13:44:12.592646+08
P168020116	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.79	mmol/l	3.9-6.1	2016-08-19 01:00:02.589637+08
P168020116	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.8		1.5-2.5	2016-08-19 01:00:02.586904+08
P168020116	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.19		0.17-0.45	2016-08-19 01:00:02.584234+08
P168020114	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.25	mmol/l	3.9-6.1	2016-08-19 01:00:02.627676+08
P168020117	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.81	mmol/l	高危人群<4.14;健康人<6.22	2016-08-19 01:00:02.592319+08
P168020117	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	2.1	mmol/l	<1.7	2016-08-19 01:00:02.594948+08
P168020117	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.9	mmol/l	1.16-1.42	2016-08-19 01:00:02.597633+08
P167291284	基本指标	yb	一般检查	010110	腰围	73			2016-08-19 01:00:02.695708+08
P15C280643	基本指标	yb	一般检查	010103	收缩压	106			2016-08-19 01:00:02.698434+08
P15C280643	基本指标	yb	一般检查	010105	体重指数	20.39			2016-08-19 01:00:02.700988+08
P15C280643	基本指标	yb	一般检查	010109	舒张压	65			2016-08-19 01:00:02.70362+08
P15C280643	基本指标	yb	一般检查	010110	腰围	66			2016-08-19 01:00:02.706235+08
P168020113	基本指标	yb	一般检查	010103	收缩压	164			2016-08-19 01:00:02.720229+08
P168020113	基本指标	yb	一般检查	010105	体重指数	21.57			2016-08-19 01:00:02.722864+08
P167270186	基本指标	None	None	010103	收缩压	123			2016-08-11 13:44:12.755231+08
P168020116	基本指标	yb	一般检查	010103	收缩压	121			2016-08-19 01:00:02.731456+08
P168020116	基本指标	yb	一般检查	010105	体重指数	22.03			2016-08-19 01:00:02.734138+08
P167270187	心血管病风险筛查	hy	凝血常规检查（血液科）	105060	活化部分凝血活酶时间	25.6	sec	20-40	2016-08-19 01:00:02.889586+08
P168020114	基本指标	yb	一般检查	010105	体重指数	27.8			2016-08-19 01:00:02.755084+08
P167270187	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	10.8	μmol/L	0-15	2016-08-19 01:00:02.859041+08
P167270187	心血管病风险筛查	hy	凝血常规检查（血液科）	105063	纤维蛋白原浓度	2.73	g/L	2-4	2016-08-19 01:00:02.892339+08
P167230072	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	13.5	μmol/L	0-15	2016-08-19 01:00:02.852903+08
P167270187	心血管病风险筛查	hy	血小板聚集（AA血液科）	205309	血小板最大聚集率	70.4	%	35.0-75.0	2016-08-19 01:00:02.867593+08
P167270187	心血管病风险筛查	hy	血小板聚集（AA血液科）	205310	血小板最大聚集点	5	P	3-8	2016-08-19 01:00:02.87043+08
P167270187	心血管病风险筛查	hy	凝血常规检查（血液科）	105013	凝血酶时间（TT）	16.6	sec	14-21	2016-08-19 01:00:02.881626+08
P167270185	心血管病风险筛查	hy	血小板聚集（AA血液科）	205309	血小板最大聚集率	38.1	%	35.0-75.0	2016-08-19 01:00:02.903626+08
P167270185	心血管病风险筛查	hy	血小板聚集（AA血液科）	205313	血小板最小聚集率	8.7	%	0-75	2016-08-19 01:00:02.914333+08
P168020113	心血管病风险筛查	us	颈动脉彩超	000003	检查结论	双侧ABI值均在正常范围,未提示下肢血管阻力增高    \r\n双侧bapwv值均超过年龄平均值+2SD,提示有动脉硬化    建议低盐低脂饮食，适当运动，监测血压，半年后复查			2016-08-19 01:00:02.791896+08
P168020114	基本指标	yb	一般检查	010109	舒张压	67			2016-08-19 01:00:02.757668+08
P167270187	心血管病风险筛查	hy	血小板聚集（AA血液科）	205311	血小板平均聚集率	70.4	%	35.0-75.0	2016-08-19 01:00:02.873175+08
P167270185	心血管病风险筛查	hy	凝血常规检查（血液科）	105055	凝血酶原时间	10	sec	9-14	2016-08-19 01:00:02.919748+08
P167270185	心血管病风险筛查	hy	凝血常规检查（血液科）	105059	凝血酶原国际标准化比值	0.87		0.8-1.5	2016-08-19 01:00:02.922471+08
P167270185	心血管病风险筛查	hy	凝血常规检查（血液科）	105060	活化部分凝血活酶时间	24.9	sec	20-40	2016-08-19 01:00:02.925092+08
P167270185	心血管病风险筛查	hy	凝血常规检查（血液科）	105063	纤维蛋白原浓度	2.19	g/L	2-4	2016-08-19 01:00:02.927697+08
P167270187	心血管病风险筛查	hy	血小板聚集（AA血液科）	205308	平均血小板体积初始值	10.46	fL	6.00-12.00	2016-08-19 01:00:02.864676+08
P168020116	基本指标	yb	一般检查	010109	舒张压	73			2016-08-19 01:00:02.736777+08
P168020114	心血管病风险筛查	us	颈动脉彩超	000003	检查结论	右侧颈动脉内中膜局部增厚  \r\n			2016-08-19 01:00:02.783161+08
P167270186	心血管病风险筛查	ec	动脉硬化检测	000003	检查结论	良性反应性改变（炎性）\r\n\r\n可见线索细胞\r\n\r\n			2016-08-11 13:44:12.780764+08
P165270036	心血管病风险筛查	ct	冠脉CTA	000003	检查结论	   冠脉CTA未见明显异常。			2016-08-11 13:44:12.777822+08
P167270187	心血管病风险筛查	hy	血小板聚集（AA血液科）	205312	红细胞初始值	4.44	*10^12/L	4.00-5.50	2016-08-19 01:00:02.875958+08
P168020117	基本指标	yb	一般检查	010103	收缩压	140			2016-08-19 01:00:02.742055+08
P168020117	基本指标	yb	一般检查	010105	体重指数	23.29			2016-08-19 01:00:02.744629+08
P168020117	基本指标	yb	一般检查	010109	舒张压	88			2016-08-19 01:00:02.747337+08
P168020117	基本指标	yb	一般检查	010110	腰围	85			2016-08-19 01:00:02.749881+08
P168020116	心血管病风险筛查	us	颈动脉彩超	000003	检查结论	双侧ABI值均在正常范围,未提示下肢血管阻力增高    \r\n双侧bapwv值均在标准范围内,未提示有动脉硬化			2016-08-19 01:00:02.788879+08
P167270185	心血管病风险筛查	ec	动脉硬化检测	000003	检查结论	血管内皮扩张率正常范围内    提示您的血管内皮层功能很活跃，请维持现在血管的状态、注意生活习惯，一年后复查。			2016-08-11 13:44:12.793045+08
P167270187	心血管病风险筛查	hy	血小板聚集（AA血液科）	205313	血小板最小聚集率	35.6	%	0-75	2016-08-19 01:00:02.878823+08
P167270185	心血管病风险筛查	hy	血小板聚集（AA血液科）	205308	平均血小板体积初始值	10.13	fL	6.00-12.00	2016-08-19 01:00:02.900895+08
P167270187	心血管病风险筛查	hy	凝血常规检查（血液科）	105059	凝血酶原国际标准化比值	0.93		0.8-1.5	2016-08-19 01:00:02.886916+08
P167270187	心血管病风险筛查	hy	血小板聚集（AA血液科）	205307	血小板项目初始值	192	*10^9/L	100-300	2016-08-19 01:00:02.86179+08
P167270185	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	12	μmol/L	0-15	2016-08-19 01:00:02.895426+08
P167270185	心血管病风险筛查	hy	血小板聚集（AA血液科）	205307	血小板项目初始值	190	*10^9/L	100-300	2016-08-19 01:00:02.898262+08
P168020116	基本指标	yb	一般检查	010110	腰围	81			2016-08-19 01:00:02.739464+08
P167270185	心血管病风险筛查	hy	血小板聚集（AA血液科）	205312	红细胞初始值	4.46	*10^12/L	4.00-5.50	2016-08-19 01:00:02.911637+08
P168020114	基本指标	yb	一般检查	010110	腰围	96			2016-08-19 01:00:02.760223+08
P167270185	心血管病风险筛查	hy	血小板聚集（AA血液科）	205311	血小板平均聚集率	27.6	%	35.0-75.0	2016-08-19 01:00:02.909004+08
P167270185	心血管病风险筛查	hy	凝血常规检查（血液科）	105013	凝血酶时间（TT）	18.8	sec	14-21	2016-08-19 01:00:02.9169+08
P167270185	心血管病风险筛查	hy	血小板聚集（AA血液科）	205310	血小板最大聚集点	5	P	3-8	2016-08-19 01:00:02.906457+08
P167230072	基本指标	None	None	100619	白球蛋白比值	1.8		1.5-2.5	2016-08-11 13:44:12.61457+08
P167291284	心血管病风险筛查	ec	动脉硬化检测	000003	检查结论	双侧ABI值均在正常范围,未提示下肢血管阻力增高    \r\n双侧bapwv值均超过年龄平均值+2SD,提示有动脉硬化    建议低盐低脂饮食，适当运动，监测血压，半年后复查			2016-08-19 01:00:02.810209+08
P167270187	心血管病风险筛查	hy	凝血常规检查（血液科）	105055	凝血酶原时间	10.7	sec	9-14	2016-08-19 01:00:02.884345+08
P169260012	心血管病风险筛查	us	颈动脉彩超	000003	检查结论	良性反应性改变（炎性）\r\n\r\n\r\n\r\n			2016-09-30 01:00:04.309657+08
P167270186	腺癌/卵巢癌风险筛查	fk	妇科检查	000001	结论	慢性宫颈炎    建议6个月内复查\r\n宫颈赘生物性质待定？    建议妇科门诊就诊\r\n子宫稍大查因？    建议结合其他检查辅助诊断			2016-08-19 01:00:02.843635+08
P167270186	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	9.7	μmol/L	0-15	2016-08-19 01:00:02.940975+08
P167270186	心血管病风险筛查	hy	血小板聚集（AA血液科）	205307	血小板项目初始值	206	*10^9/L	100-300	2016-08-19 01:00:02.943662+08
P167270186	心血管病风险筛查	hy	血小板聚集（AA血液科）	205308	平均血小板体积初始值	10.56	fL	6.00-12.00	2016-08-19 01:00:02.946469+08
P167270186	心血管病风险筛查	hy	血小板聚集（AA血液科）	205309	血小板最大聚集率	78.2	%	35.0-75.0	2016-08-19 01:00:02.949078+08
P167270186	心血管病风险筛查	hy	血小板聚集（AA血液科）	205310	血小板最大聚集点	4	P	3-8	2016-08-19 01:00:02.951714+08
P167270186	心血管病风险筛查	hy	血小板聚集（AA血液科）	205311	血小板平均聚集率	76.5	%	35.0-75.0	2016-08-19 01:00:02.954456+08
P167270186	心血管病风险筛查	hy	血小板聚集（AA血液科）	205312	红细胞初始值	4.31	*10^12/L	4.00-5.50	2016-08-19 01:00:02.957082+08
P167270186	心血管病风险筛查	hy	血小板聚集（AA血液科）	205313	血小板最小聚集率	39.5	%	0-75	2016-08-19 01:00:02.959806+08
P167270186	心血管病风险筛查	hy	凝血常规检查（血液科）	105013	凝血酶时间（TT）	15.9	sec	14-21	2016-08-19 01:00:02.962541+08
P167270186	心血管病风险筛查	hy	凝血常规检查（血液科）	105059	凝血酶原国际标准化比值	0.92		0.8-1.5	2016-08-19 01:00:02.967827+08
P167270186	心血管病风险筛查	hy	凝血常规检查（血液科）	105060	活化部分凝血活酶时间	24.2	sec	20-40	2016-08-19 01:00:02.971176+08
P167270186	心血管病风险筛查	hy	凝血常规检查（血液科）	105063	纤维蛋白原浓度	2.52	g/L	2-4	2016-08-19 01:00:02.97408+08
P168020114	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	10.3	μmol/L	0-15	2016-08-19 01:00:02.938318+08
P168170068	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.7		1.5-2.5	2016-08-26 12:42:37.697672+08
P168170068	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.28		0.17-0.45	2016-08-26 12:42:37.700628+08
P168170068	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	1.89	mmol/l	高危人群<2.59;健康人<3.12	2016-08-26 12:42:37.703504+08
P168170068	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.12	mmol/l	1.16-1.42	2016-08-26 12:42:37.706452+08
P169300306	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	4.86	mmol/l	高危人群<4.14;健康人<6.22	2016-10-11 17:01:34.764471+08
P168020113	基本指标	yb	一般检查	010110	腰围	79			2016-08-19 01:00:02.728035+08
P168020114	基本指标	yb	一般检查	010103	收缩压	109			2016-08-19 01:00:02.752552+08
P169300306	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	2.25	mmol/l	<1.7	2016-10-11 17:01:34.76837+08
P168220014	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	4.85	mmol/l	高危人群<2.59;健康人<4.14	2016-08-26 12:42:37.406739+08
P169300306	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.59	mmol/l	1.16-1.42	2016-10-11 17:01:34.77172+08
P168220014	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.14	mmol/l	1.29-1.55	2016-08-26 12:42:37.409678+08
P168220014	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.24	mmol/l	<1.7	2016-08-26 12:42:37.412658+08
P168220014	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	6.55	mmol/l	高危人群<4.14;健康人<6.22	2016-08-26 12:42:37.415559+08
P168190032	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	6.7	mmol/l	3.9-6.1	2016-08-26 12:42:37.530102+08
P168190032	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.1	mmol/l	1.16-1.42	2016-08-26 12:42:37.541648+08
P168170329	基本指标	hy	血脂八项	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.15		0.17-0.45	2016-08-26 12:42:37.58783+08
P168190032	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	2.63	mmol/l	<1.7	2016-08-26 12:42:37.544571+08
P168190032	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	4.88	mmol/l	高危人群<4.14;健康人<6.22	2016-08-26 12:42:37.547462+08
P168160788	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	4.89	mmol/l	高危人群<4.14;健康人<6.22	2016-08-26 12:42:37.610634+08
P168160788	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.17	mmol/l	<1.7	2016-08-26 12:42:37.613578+08
P168160788	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.57	mmol/l	1.16-1.42	2016-08-26 12:42:37.616467+08
P168170068	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	2.21	mmol/l	<1.7	2016-08-26 12:42:37.709463+08
P168170068	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	4.02	mmol/l	高危人群<4.14;健康人<6.22	2016-08-26 12:42:37.712462+08
P167270186	心血管病风险筛查	hy	凝血常规检查（血液科）	105055	凝血酶原时间	10.6	sec	9-14	2016-08-19 01:00:02.965223+08
P168020117	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	10.9	μmol/L	0-15	2016-08-19 01:00:02.935486+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304595	HPV45	阴性			2016-08-19 01:00:03.151023+08
P169300306	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.25	mmol/l	高危人群<2.59;健康人<4.14	2016-10-11 17:01:34.77522+08
P168190032	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.6		1.5-2.5	2016-08-26 12:42:37.532982+08
P168170329	基本指标	hy	肝功能九项	100619	白球蛋白比值	1.3		1.5-2.5	2016-08-26 12:42:37.572863+08
P168170329	基本指标	hy	血脂八项	100401	总胆固醇	4.69	mmol/l	高危人群<4.14;健康人<6.22	2016-08-26 12:42:37.575807+08
P168170329	基本指标	hy	血脂八项	100402	甘油三酯	8.15	mmol/l	<1.7	2016-08-26 12:42:37.578637+08
P168170329	基本指标	hy	血脂八项	100504	高密度脂蛋白胆固醇	0.72	mmol/l	1.16-1.42	2016-08-26 12:42:37.581493+08
P168160788	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.32		0.17-0.45	2016-08-26 12:42:37.622062+08
P168160788	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	2.3		1.5-2.5	2016-08-26 12:42:37.625069+08
P168160788	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.11	mmol/l	3.9-6.1	2016-08-26 12:42:37.628174+08
P168160792	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	4.02	mmol/l	高危人群<4.14;健康人<6.22	2016-08-26 12:42:37.761967+08
P168190032	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.23		0.17-0.45	2016-08-26 12:42:37.535893+08
P168190032	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.58	mmol/l	高危人群<2.59;健康人<4.14	2016-08-26 12:42:37.538772+08
P168170068	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.03	mmol/l	3.9-6.1	2016-08-26 12:42:37.694675+08
P168170329	基本指标	hy	血脂八项	100505	低密度脂蛋白胆固醇	0.81	mmol/l	高危人群<2.59;健康人<3.12	2016-08-26 12:42:37.584326+08
P168160792	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	0.69	mmol/l	<1.7	2016-08-26 12:42:37.764991+08
P169300306	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.33		0.17-0.45	2016-10-11 17:01:34.778594+08
P169300306	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	2.2		1.5-2.5	2016-10-11 17:01:34.781869+08
P169300306	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.79	mmol/l	3.9-6.1	2016-10-11 17:01:34.78523+08
P169300306	基本指标	yb	一般检查	010103	收缩压	123			2016-10-11 17:01:34.788806+08
P169300306	基本指标	yb	一般检查	010105	体重指数	21.85			2016-10-11 17:01:34.792235+08
P169300306	基本指标	yb	一般检查	010109	舒张压	87			2016-10-11 17:01:34.795554+08
P169300306	基本指标	yb	一般检查	010110	腰围	81			2016-10-11 17:01:34.798846+08
P169300306	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	15.1	μmol/L	0-15	2016-10-11 17:01:34.806076+08
P169300306	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-10-11 17:01:34.809402+08
P169300306	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	1	mg/L	0-3.00	2016-10-11 17:01:34.812577+08
P168220014	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.7		1.5-2.5	2016-08-26 12:42:37.400497+08
P168220014	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.17		0.17-0.45	2016-08-26 12:42:37.403737+08
P168190032	基本指标	yb	一般检查	010109	舒张压	75			2016-08-26 12:42:37.888559+08
P168220014	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-26 12:42:38.344478+08
P168190032	基本指标	yb	一般检查	010110	腰围	99			2016-08-26 12:42:37.891435+08
P168160788	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	双侧ABI值均在正常范围,未提示下肢血管阻力增高    \r\n双侧bapwv值均在标准范围内,未提示有动脉硬化			2016-08-26 12:42:38.075135+08
P168020117	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超1	000003	检查结论	双侧ABI值均在正常范围,未提示下肢血管阻力增高    \r\n双侧bapwv值均超过年龄平均值+1SD,提示有轻度动脉硬化可能    建议低盐低脂饮食，适当运动，监测血压，半年后复查			2016-08-19 01:00:02.774667+08
P168170068	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	血管内皮扩张率正常范围内    提示您的血管内皮层功能很活跃，请维持现在血管的状态、注意生活习惯，一年后复查。			2016-08-26 12:42:38.072167+08
P168160788	基本指标	yb	一般检查	010103	收缩压	109			2016-08-26 12:42:37.920442+08
P168220014	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.58	mmol/l	3.9-6.1	2016-08-26 12:42:37.325008+08
P168160788	基本指标	yb	一般检查	010105	体重指数	20.53			2016-08-26 12:42:37.923459+08
P168160792	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.4	mmol/l	高危人群<2.59;健康人<4.14	2016-08-26 12:42:37.771317+08
P168220014	腺癌/卵巢癌风险筛查	fk	妇科检查	000001	结论	未见明显异常			2016-08-26 12:42:38.153866+08
P168160792	腺癌/卵巢癌风险筛查	fk	妇科检查	000001	结论	慢性宫颈炎    建议6个月内复查			2016-08-26 12:42:38.160154+08
P168160792	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.33		0.17-0.45	2016-08-26 12:42:37.774102+08
P168160792	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	2.4		1.5-2.5	2016-08-26 12:42:37.776947+08
P168160792	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.42	mmol/l	3.9-6.1	2016-08-26 12:42:37.779867+08
P168020117	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.96	mmol/l	高危人群<2.59;健康人<4.14	2016-08-19 01:00:02.600231+08
P168160788	基本指标	yb	一般检查	010109	舒张压	73			2016-08-26 12:42:37.926458+08
P168160788	基本指标	yb	一般检查	010110	腰围	74			2016-08-26 12:42:37.929357+08
P168170068	基本指标	yb	一般检查	010103	收缩压	135			2016-08-26 12:42:37.958523+08
P168170068	基本指标	yb	一般检查	010105	体重指数	24.81			2016-08-26 12:42:37.961481+08
P168170068	基本指标	yb	一般检查	010109	舒张压	94			2016-08-26 12:42:37.964641+08
P168170068	基本指标	yb	一般检查	010110	腰围	86			2016-08-26 12:42:37.967578+08
P168160792	基本指标	yb	一般检查	010103	收缩压	106			2016-08-26 12:42:37.997508+08
P168160792	基本指标	yb	一般检查	010105	体重指数	19.88			2016-08-26 12:42:38.000487+08
P168160792	基本指标	yb	一般检查	010109	舒张压	67			2016-08-26 12:42:38.003473+08
P168160792	腺癌/卵巢癌风险筛查	ez	液基细胞学检查	000003	检查结论	未见恶性细胞和上皮内病变细胞\r\n\r\n\r\n\r\n			2016-08-26 12:42:38.170451+08
P168220014	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	10.2	μmol/L	0-15	2016-08-26 12:42:38.176778+08
P168190032	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	9.5	μmol/L	0-15	2016-08-26 12:42:38.23235+08
P168160788	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	10.3	μmol/L	0-15	2016-08-26 12:42:38.279015+08
P168170068	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	12.3	μmol/L	0-15	2016-08-26 12:42:38.32564+08
P168160792	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	7.4	μmol/L	0-15	2016-08-26 12:42:38.335066+08
P168160792	基本指标	yb	一般检查	010110	腰围	69			2016-08-26 12:42:38.006444+08
P168220014	基本指标	yb	一般检查	010103	收缩压	129			2016-08-26 12:42:37.829486+08
P168220014	基本指标	yb	一般检查	010105	体重指数	26.72			2016-08-26 12:42:37.832486+08
P168220014	基本指标	yb	一般检查	010109	舒张压	82			2016-08-26 12:42:37.83545+08
P168220014	基本指标	yb	一般检查	010110	腰围	95			2016-08-26 12:42:37.838392+08
P168190032	基本指标	yb	一般检查	010103	收缩压	121			2016-08-26 12:42:37.882635+08
P168190032	基本指标	yb	一般检查	010105	体重指数	29.13			2016-08-26 12:42:37.885609+08
P168190032	心血管病风险筛查	us	颈动脉彩超	000003	检查结论	血管内皮扩张率正常范围内    提示您的血管内皮层功能很活跃，请维持现在血管的状态、注意生活习惯，一年后复查。			2016-08-26 12:42:38.045859+08
P168160788	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.79	mmol/l	高危人群<2.59;健康人<4.14	2016-08-26 12:42:37.619216+08
P16A100463	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	4.01	mmol/l	高危人群<4.14;健康人<6.22	2016-10-14 01:00:06.046723+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304601	HPV59	阴性			2016-08-26 12:42:38.497515+08
P168160792	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.31	mmol/l	1.29-1.55	2016-08-26 12:42:37.767908+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304602	HPV66	阴性			2016-08-26 12:42:38.500631+08
P168160788	腺癌/卵巢癌风险筛查	hy	CEA(核)	116501	癌胚抗原	2.44	ng/ml	0-4.7正常人群，0-6.5 吸烟人群	2016-08-26 12:42:38.676887+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304605	HPV42	阴性			2016-08-26 12:42:38.761611+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	105014	血清铁蛋白测定	264.01	ng/ml	<322	2016-08-26 12:42:38.683146+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304592	HPV33	阴性			2016-08-26 12:42:38.744394+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304604	HPV11	阴性			2016-08-26 12:42:38.752952+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304608	HPV44	阴性			2016-08-26 12:42:38.755836+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304602	HPV66	阴性			2016-08-26 12:42:38.764538+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304601	HPV59	阴性			2016-08-26 12:42:38.770535+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304609	HPVCP8304	阴性			2016-08-26 12:42:38.773468+08
P168230028	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	4.44	mmol/l	高危人群<4.14;健康人<6.22	2016-08-27 01:00:03.900152+08
P168230028	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	0.74	mmol/l	<1.7	2016-08-27 01:00:03.903496+08
P168230028	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.49	mmol/l	1.29-1.55	2016-08-27 01:00:03.906385+08
P168230028	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.61	mmol/l	高危人群<2.59;健康人<4.14	2016-08-27 01:00:03.909292+08
P168230028	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.34		0.17-0.45	2016-08-27 01:00:03.912936+08
P168230028	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.8		1.5-2.5	2016-08-27 01:00:03.915844+08
P168230028	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.28	mmol/l	3.9-6.1	2016-08-27 01:00:03.918676+08
P168230028	基本指标	yb	一般检查	010103	收缩压	125			2016-08-27 01:00:03.921622+08
P168230028	基本指标	yb	一般检查	010105	体重指数	19.7			2016-08-27 01:00:03.924611+08
P168230028	基本指标	yb	一般检查	010109	舒张压	72			2016-08-27 01:00:03.927432+08
P168230028	基本指标	yb	一般检查	010110	腰围	72			2016-08-27 01:00:03.930239+08
P16A100463	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	3.62	mmol/l	<1.7	2016-10-14 01:00:06.050621+08
P16A100463	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	0.64	mmol/l	1.16-1.42	2016-10-14 01:00:06.053796+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	101001	甲胎蛋白	0.59	ng/ml	<20.00	2016-08-26 12:42:38.680242+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	116501	癌胚抗原	1.7	ng/ml	<5.00	2016-08-26 12:42:38.686113+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	116504	游离前列腺特异性抗原（F-PSA）	0.15	ng/ml	<1.00	2016-08-26 12:42:38.688921+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	116505	CA-125	7.49	KU/L	<35.00	2016-08-26 12:42:38.691838+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	116506	胃肠癌抗原(CA-199)	8.42	KU/L	<35.00	2016-08-26 12:42:38.694709+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	116705	CA-153	25.58	KU/L	<35.00	2016-08-26 12:42:38.697599+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	201393	神经原特异性烯醇化酶	1.74	ng/ml	<13.00	2016-08-26 12:42:38.700476+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	201394	人绒毛膜促性腺激素	0.19	ng/ml	<3.00	2016-08-26 12:42:38.703372+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	301264	前列腺特异抗原(PSA)	0.86	ng/ml	<5	2016-08-26 12:42:38.706137+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	301273	生长激素	0.05	ng/ml	<7.50	2016-08-26 12:42:38.709017+08
P168170068	腺癌/卵巢癌风险筛查	hy	C-12	301285	糖链抗原242	2.67	U/ml	<20.00	2016-08-26 12:42:38.711851+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304585	基因检测结果	未发现人乳头瘤病毒			2016-08-26 12:42:38.714897+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304589	HPV16	阴性			2016-08-26 12:42:38.717785+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304590	HPV18	阴性			2016-08-26 12:42:38.720664+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304591	HPV31	阴性			2016-08-26 12:42:38.7236+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304598	HPV53	阴性			2016-08-26 12:42:38.726444+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304594	HPV39	阴性			2016-08-26 12:42:38.729872+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304596	HPV51	阴性			2016-08-26 12:42:38.732814+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304599	HPV56	阴性			2016-08-26 12:42:38.735697+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304597	HPV52	阴性			2016-08-26 12:42:38.738629+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304595	HPV45	阴性			2016-08-26 12:42:38.741529+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304593	HPV35	阴性			2016-08-26 12:42:38.747162+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304606	HPV43	阴性			2016-08-26 12:42:38.750049+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304607	HPV6	阴性			2016-08-26 12:42:38.758749+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304600	HPV58	阴性			2016-08-26 12:42:38.767619+08
P168160792	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304603	HPV68	阴性			2016-08-26 12:42:38.776408+08
P168290025	腺癌/卵巢癌风险筛查	hy	CEA(核)	116501	癌胚抗原	2.32	ng/ml	0-4.7正常人群，0-6.5 吸烟人群	2016-09-02 01:00:03.406894+08
P16A100463	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	1.72	mmol/l	高危人群<2.59;健康人<4.14	2016-10-14 01:00:06.056996+08
P16A100463	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.16		0.17-0.45	2016-10-14 01:00:06.060152+08
P16A100463	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	2.5		1.5-2.5	2016-10-14 01:00:06.063334+08
P16A100463	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.94	mmol/l	3.9-6.1	2016-10-14 01:00:06.066562+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304599	HPV56	阴性			2016-08-27 01:00:04.002825+08
P168290025	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	5.4	μmol/L	0-15	2016-09-02 01:00:03.397883+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304600	HPV58	阴性			2016-08-27 01:00:04.005676+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304601	HPV59	阴性			2016-08-27 01:00:04.00861+08
P168290025	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-02 01:00:03.400896+08
P168290025	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	13.12	mmol/l	<1.7	2016-09-02 01:00:03.35496+08
P168290025	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	2	mg/L	0-3.00	2016-09-02 01:00:03.40387+08
P168290025	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	0.48	mmol/l	1.16-1.42	2016-09-02 01:00:03.357935+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304602	HPV66	阴性			2016-08-27 01:00:04.011469+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304603	HPV68	阴性			2016-08-27 01:00:04.014269+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304604	HPV11	阴性			2016-08-27 01:00:04.017066+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304605	HPV42	阴性			2016-08-27 01:00:04.019944+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304606	HPV43	阴性			2016-08-27 01:00:04.023269+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304589	HPV16	阴性			2016-08-27 01:00:03.973775+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304590	HPV18	阴性			2016-08-27 01:00:03.976647+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304591	HPV31	阴性			2016-08-27 01:00:03.979459+08
P168250037	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.9	mg/L	0-3.00	2016-08-29 01:00:04.309944+08
P168290025	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	1.06	mmol/l	高危人群<2.59;健康人<3.12	2016-09-02 01:00:03.360886+08
P168290025	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.09		0.17-0.45	2016-09-02 01:00:03.363829+08
P168290025	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.3		1.5-2.5	2016-09-02 01:00:03.366746+08
P168290025	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	6.12	mmol/l	3.9-6.1	2016-09-02 01:00:03.369688+08
P168290025	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.55	mmol/l	高危人群<4.14;健康人<6.22	2016-09-02 01:00:03.35138+08
P168290025	基本指标	yb	一般检查	010103	收缩压	119			2016-09-02 01:00:03.372603+08
P168290025	基本指标	yb	一般检查	010105	体重指数	27.52			2016-09-02 01:00:03.375505+08
P168230028	腺癌/卵巢癌风险筛查	fk	妇科检查	000001	结论	慢性宫颈炎    建议6个月内复查			2016-08-27 01:00:03.943741+08
P168290025	基本指标	yb	一般检查	010109	舒张压	70			2016-09-02 01:00:03.378494+08
P168230028	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	9.6	μmol/L	0-15	2016-08-27 01:00:03.953582+08
P168230028	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-27 01:00:03.956499+08
P168230028	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.2	mg/L	0-3.00	2016-08-27 01:00:03.959453+08
P168230028	腺癌/卵巢癌风险筛查	hy	CEA(核)	116501	癌胚抗原	1.91	ng/ml	0-4.7正常人群，0-6.5 吸烟人群	2016-08-27 01:00:03.962381+08
P168230028	腺癌/卵巢癌风险筛查	hy	CA125(核)	116505	CA-125	17.94	U/ml	0-35	2016-08-27 01:00:03.965219+08
P168230028	腺癌/卵巢癌风险筛查	hy	CA153(核)	116705	CA-153	8.97	U/ml	0-25	2016-08-27 01:00:03.96805+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304592	HPV33	阴性			2016-08-27 01:00:03.982369+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304593	HPV35	阴性			2016-08-27 01:00:03.985161+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304594	HPV39	阴性			2016-08-27 01:00:03.988493+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304595	HPV45	阴性			2016-08-27 01:00:03.991436+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304596	HPV51	阴性			2016-08-27 01:00:03.994353+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304597	HPV52	阴性			2016-08-27 01:00:03.99712+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304598	HPV53	阴性			2016-08-27 01:00:03.999936+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304607	HPV6	阴性			2016-08-27 01:00:04.026153+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304608	HPV44	阴性			2016-08-27 01:00:04.028964+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304609	HPVCP8304	阴性			2016-08-27 01:00:04.031788+08
P168290025	基本指标	yb	一般检查	010110	腰围	93			2016-09-02 01:00:03.381471+08
P168290025	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	血管内皮扩张率低于正常值    提示您的血管内皮机能正在降低，建议接受医生的指导和治疗、注意改善生活习惯，半年后复查。			2016-09-02 01:00:03.38441+08
P168230028	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304585	基因检测结果	未发现人乳头瘤病毒			2016-08-27 01:00:03.970877+08
P168250037	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.89	mmol/l	3.9-6.1	2016-08-29 01:00:04.267171+08
P168250037	基本指标	yb	一般检查	010109	舒张压	72			2016-08-29 01:00:04.294438+08
P168250037	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	2.2		1.5-2.5	2016-08-29 01:00:04.270168+08
P168250037	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.29		0.17-0.45	2016-08-29 01:00:04.273162+08
P168250037	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	3.23	mmol/l	高危人群<2.59;健康人<4.14	2016-08-29 01:00:04.276141+08
P168250037	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.59	mmol/l	1.16-1.42	2016-08-29 01:00:04.279602+08
P168250037	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.3	mmol/l	<1.7	2016-08-29 01:00:04.282538+08
P168250037	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.41	mmol/l	高危人群<4.14;健康人<6.22	2016-08-29 01:00:04.285486+08
P168250037	基本指标	yb	一般检查	010103	收缩压	113			2016-08-29 01:00:04.288411+08
P168250037	基本指标	yb	一般检查	010105	体重指数	16.43			2016-08-29 01:00:04.291387+08
P168250037	基本指标	yb	一般检查	010110	腰围	61			2016-08-29 01:00:04.297543+08
P168250037	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	13.2	μmol/L	0-15	2016-08-29 01:00:04.304029+08
P168250037	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-29 01:00:04.307013+08
P168200029	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	2.46	mmol/l	<1.7	2016-09-04 01:00:03.973834+08
P168310035	腺癌/卵巢癌风险筛查	fk	妇科检查	000001	结论	慢性宫颈炎    建议6个月内复查			2016-09-04 01:00:04.094921+08
P168200029	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.49	mmol/l	1.16-1.42	2016-09-04 01:00:03.976824+08
P168290068	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	3.92	mmol/l	高危人群<4.14;健康人<6.22	2016-09-03 01:00:03.799433+08
P168290068	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.19	mmol/l	<1.7	2016-09-03 01:00:03.802447+08
P168290068	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.1	mmol/l	1.16-1.42	2016-09-03 01:00:03.80543+08
P168290068	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.28	mmol/l	高危人群<2.59;健康人<4.14	2016-09-03 01:00:03.80844+08
P168290068	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.28		0.17-0.45	2016-09-03 01:00:03.811434+08
P168200029	基本指标	yb	一般检查	010109	舒张压	82			2016-09-04 01:00:04.038891+08
P168200029	基本指标	yb	一般检查	010110	腰围	89			2016-09-04 01:00:04.041694+08
P168310035	基本指标	yb	一般检查	010103	收缩压	110			2016-09-04 01:00:04.044599+08
P168310035	基本指标	yb	一般检查	010105	体重指数	20.73			2016-09-04 01:00:04.047476+08
P168310035	基本指标	yb	一般检查	010109	舒张压	62			2016-09-04 01:00:04.050424+08
P168310035	基本指标	yb	一般检查	010110	腰围	65			2016-09-04 01:00:04.053325+08
P168310039	基本指标	yb	一般检查	010103	收缩压	99			2016-09-04 01:00:04.056238+08
P168310039	基本指标	yb	一般检查	010105	体重指数	19.67			2016-09-04 01:00:04.059135+08
P168310039	基本指标	yb	一般检查	010109	舒张压	63			2016-09-04 01:00:04.062065+08
P168310039	基本指标	yb	一般检查	010110	腰围	74			2016-09-04 01:00:04.064966+08
P168310039	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	双侧ABI值均在正常范围,未提示下肢血管阻力增高    \r\n双侧bapwv值均在标准范围内,未提示有动脉硬化			2016-09-04 01:00:04.071483+08
P168230028	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	未见恶性细胞和上皮内病变细胞\r\n\r\n\r\n\r\n			2016-08-27 01:00:03.93311+08
P168290068	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	2.5		1.5-2.5	2016-09-03 01:00:03.814457+08
P168200029	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.94	mmol/l	高危人群<2.59;健康人<4.14	2016-09-04 01:00:03.979743+08
P168200029	基本指标	yb	一般检查	010103	收缩压	116			2016-09-04 01:00:04.032881+08
P168200029	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	血管内皮扩张率正常范围内    提示您的血管内皮层功能很活跃，请维持现在血管的状态、注意生活习惯，一年后复查。			2016-09-04 01:00:04.068516+08
P168290068	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.46	mmol/l	3.9-6.1	2016-09-03 01:00:03.81764+08
P168290068	基本指标	yb	一般检查	010103	收缩压	121			2016-09-03 01:00:03.821146+08
P168290068	基本指标	yb	一般检查	010105	体重指数	27.19			2016-09-03 01:00:03.82422+08
P168290068	基本指标	yb	一般检查	010109	舒张压	84			2016-09-03 01:00:03.827142+08
P168290068	基本指标	yb	一般检查	010110	腰围	95			2016-09-03 01:00:03.830103+08
P168290068	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	11.7	μmol/L	0-15	2016-09-03 01:00:03.846439+08
P168290068	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-03 01:00:03.849438+08
P168290068	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.4	mg/L	0-3.00	2016-09-03 01:00:03.852449+08
P168290068	腺癌/卵巢癌风险筛查	hy	CEA(核)	116501	癌胚抗原	2.35	ng/ml	0-4.7正常人群，0-6.5 吸烟人群	2016-09-03 01:00:03.855429+08
P168290068	腺癌/卵巢癌风险筛查	hy	CA125(核)	116505	CA-125	14.15	U/ml	0-35	2016-09-03 01:00:03.858405+08
P168290068	腺癌/卵巢癌风险筛查	hy	CA199(核医学)	116506	胃肠癌抗原(CA-199)	9.28	U/mL	0-27	2016-09-03 01:00:03.861415+08
P168200029	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.55	mmol/l	高危人群<4.14;健康人<6.22	2016-09-04 01:00:03.970472+08
P168200029	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.27		0.17-0.45	2016-09-04 01:00:03.982677+08
P168200029	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.9		1.5-2.5	2016-09-04 01:00:03.985606+08
P168200029	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.33	mmol/l	3.9-6.1	2016-09-04 01:00:03.988594+08
P168310035	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	3.81	mmol/l	高危人群<4.14;健康人<6.22	2016-09-04 01:00:03.991536+08
P168310035	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.26	mmol/l	<1.7	2016-09-04 01:00:03.994435+08
P168310035	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.56	mmol/l	1.29-1.55	2016-09-04 01:00:03.997374+08
P168310035	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	1.68	mmol/l	高危人群<2.59;健康人<4.14	2016-09-04 01:00:04.000316+08
P168310035	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.41		0.17-0.45	2016-09-04 01:00:04.003218+08
P168310035	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	2.3		1.5-2.5	2016-09-04 01:00:04.006106+08
P168310035	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.38	mmol/l	3.9-6.1	2016-09-04 01:00:04.009001+08
P168310039	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.69	mmol/l	高危人群<4.14;健康人<6.22	2016-09-04 01:00:04.012153+08
P168310039	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.13	mmol/l	<1.7	2016-09-04 01:00:04.015233+08
P168310039	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.32	mmol/l	1.16-1.42	2016-09-04 01:00:04.018141+08
P168310039	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	3.86	mmol/l	高危人群<2.59;健康人<4.14	2016-09-04 01:00:04.021159+08
P168310039	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.23		0.17-0.45	2016-09-04 01:00:04.024077+08
P168310039	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	2		1.5-2.5	2016-09-04 01:00:04.02703+08
P168310039	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.3	mmol/l	3.9-6.1	2016-09-04 01:00:04.02989+08
P168200029	基本指标	yb	一般检查	010105	体重指数	29.72			2016-09-04 01:00:04.035928+08
P168310035	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.4	mg/L	0-3.00	2016-09-04 01:00:04.158865+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304605	HPV42	阴性			2016-09-04 01:00:04.226568+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304603	HPV68	阴性			2016-09-04 01:00:04.220461+08
P168310035	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	未见恶性细胞和上皮内病变细胞\r\n\r\n\r\n\r\n			2016-09-04 01:00:04.074439+08
P168310039	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-04 01:00:04.161702+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304606	HPV43	阴性			2016-09-04 01:00:04.229917+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304607	HPV6	阴性			2016-09-04 01:00:04.233085+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304608	HPV44	阴性			2016-09-04 01:00:04.236178+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304609	HPVCP8304	阴性			2016-09-04 01:00:04.239529+08
P168310039	腺癌/卵巢癌风险筛查	hy	CEA(核)	116501	癌胚抗原	2.7	ng/ml	0-4.7正常人群，0-6.5 吸烟人群	2016-09-04 01:00:04.242643+08
P168310039	腺癌/卵巢癌风险筛查	hy	CA125(核)	116505	CA-125	8.5	U/ml	0-35	2016-09-04 01:00:04.245764+08
P168310039	腺癌/卵巢癌风险筛查	hy	CA199(核医学)	116506	胃肠癌抗原(CA-199)	0.6	U/mL	0-27	2016-09-04 01:00:04.248803+08
P164190212	基本指标	hy	肝肾功能血脂血糖	107501	空腹血糖	5.67	mmol/l	3.9-6.1	2016-09-10 01:00:04.516287+08
P164190212	基本指标	hy	肝肾功能血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.15		0.17-0.45	2016-09-10 01:00:04.519448+08
P164190212	基本指标	hy	肝肾功能血脂血糖	100505	低密度脂蛋白胆固醇	3.46	mmol/l	高危人群<2.59;健康人<4.14	2016-09-10 01:00:04.522382+08
P164190212	基本指标	hy	肝肾功能血脂血糖	100504	高密度脂蛋白胆固醇	0.97	mmol/l	1.16-1.42	2016-09-10 01:00:04.525361+08
P164190212	基本指标	hy	肝肾功能血脂血糖	100402	甘油三酯	4.23	mmol/l	<1.7	2016-09-10 01:00:04.528341+08
P168200029	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	13.7	μmol/L	0-15	2016-09-04 01:00:04.105057+08
P168310035	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	9.7	μmol/L	0-15	2016-09-04 01:00:04.108127+08
P168310035	心血管病风险筛查	hy	血小板聚集（AA血液科）	205307	血小板项目初始值	288	*10^9/L	100-300	2016-09-04 01:00:04.111497+08
P168310035	心血管病风险筛查	hy	血小板聚集（AA血液科）	205308	平均血小板体积初始值	9.92	fL	6.00-12.00	2016-09-04 01:00:04.114552+08
P168310035	心血管病风险筛查	hy	血小板聚集（AA血液科）	205309	血小板最大聚集率	65.3	%	35.0-75.0	2016-09-04 01:00:04.117465+08
P168310035	心血管病风险筛查	hy	血小板聚集（AA血液科）	205310	血小板最大聚集点	4	P	3-8	2016-09-04 01:00:04.120439+08
P168310035	心血管病风险筛查	hy	血小板聚集（AA血液科）	205311	血小板平均聚集率	63.6	%	35.0-75.0	2016-09-04 01:00:04.123444+08
P168310035	心血管病风险筛查	hy	血小板聚集（AA血液科）	205312	红细胞初始值	3.83	*10^12/L	4.00-5.50	2016-09-04 01:00:04.126454+08
P168310035	心血管病风险筛查	hy	血小板聚集（AA血液科）	205313	血小板最小聚集率	32.8	%	0-75	2016-09-04 01:00:04.129461+08
P168310035	心血管病风险筛查	hy	凝血常规检查（血液科）	105013	凝血酶时间（TT）	16.1	sec	14-21	2016-09-04 01:00:04.132422+08
P168310035	心血管病风险筛查	hy	凝血常规检查（血液科）	105055	凝血酶原时间	10.6	sec	9-14	2016-09-04 01:00:04.135403+08
P168310035	心血管病风险筛查	hy	凝血常规检查（血液科）	105059	凝血酶原国际标准化比值	0.92		0.8-1.5	2016-09-04 01:00:04.138372+08
P168310035	心血管病风险筛查	hy	凝血常规检查（血液科）	105060	活化部分凝血活酶时间	28.2	sec	20-40	2016-09-04 01:00:04.141323+08
P168310035	心血管病风险筛查	hy	凝血常规检查（血液科）	105063	纤维蛋白原浓度	2.18	g/L	2-4	2016-09-04 01:00:04.14418+08
P168310039	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	12.2	μmol/L	0-15	2016-09-04 01:00:04.1471+08
P168200029	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-04 01:00:04.150088+08
P168200029	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	1.3	mg/L	0-3.00	2016-09-04 01:00:04.152996+08
P168310035	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-04 01:00:04.15592+08
P168310039	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.9	mg/L	0-3.00	2016-09-04 01:00:04.164642+08
P168200029	腺癌/卵巢癌风险筛查	hy	CEA(核)	116501	癌胚抗原	2.17	ng/ml	0-4.7正常人群，0-6.5 吸烟人群	2016-09-04 01:00:04.168173+08
P168310035	腺癌/卵巢癌风险筛查	hy	CEA(核)	116501	癌胚抗原	2.64	ng/ml	0-4.7正常人群，0-6.5 吸烟人群	2016-09-04 01:00:04.171234+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304585	基因检测结果	有人乳头状瘤病毒感染			2016-09-04 01:00:04.174436+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304589	HPV16	阴性			2016-09-04 01:00:04.177591+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304590	HPV18	阴性			2016-09-04 01:00:04.180656+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304591	HPV31	阴性			2016-09-04 01:00:04.183739+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304592	HPV33	陽性(+)			2016-09-04 01:00:04.18685+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304593	HPV35	阴性			2016-09-04 01:00:04.189879+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304594	HPV39	阴性			2016-09-04 01:00:04.192979+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304595	HPV45	阴性			2016-09-04 01:00:04.196076+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304599	HPV56	阴性			2016-09-04 01:00:04.208237+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304600	HPV58	阴性			2016-09-04 01:00:04.211233+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304601	HPV59	阴性			2016-09-04 01:00:04.214233+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304602	HPV66	阴性			2016-09-04 01:00:04.217314+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304604	HPV11	阴性			2016-09-04 01:00:04.223458+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304596	HPV51	阴性			2016-09-04 01:00:04.19917+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304597	HPV52	阴性			2016-09-04 01:00:04.202262+08
P168310035	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304598	HPV53	阴性			2016-09-04 01:00:04.205253+08
P169120450	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-17 01:00:05.135715+08
P167270185	基本指标	None	None	010103	收缩压	121			2016-08-11 13:44:12.743842+08
P164190212	基本指标	yb	一般检查	010105	体重指数	28.31			2016-09-10 01:00:04.539409+08
P167270187	基本指标	None	None	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.3		0.17-0.45	2016-08-11 13:44:12.735404+08
P164190212	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	3.2	mg/L	0-3.00	2016-09-10 01:00:04.603397+08
P169120449	腺癌/卵巢癌风险筛查	hy	CA125(核)	116505	CA-125	13.24	U/ml	0-35	2016-09-17 01:00:05.147891+08
P169120449	腺癌/卵巢癌风险筛查	hy	CA153(核)	116705	CA-153	4.42	U/ml	0-25	2016-09-17 01:00:05.151031+08
P167230072	基本指标	None	None	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.37		0.17-0.45	2016-08-11 13:44:12.617068+08
P169120451	基本指标	yb	一般检查	010103	收缩压	121			2016-09-17 01:00:05.097839+08
P169120450	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.4	mg/L	0-3.00	2016-09-17 01:00:05.138751+08
P167270187	基本指标	None	None	100619	白球蛋白比值	2.9		1.5-2.5	2016-08-11 13:44:12.738358+08
P167270187	基本指标	None	None	107501	空腹血糖	5.27	mmol/l	3.9-6.1	2016-08-11 13:44:12.741023+08
P169120451	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-17 01:00:05.141795+08
P169120451	基本指标	yb	一般检查	010105	体重指数	17.07			2016-09-17 01:00:05.10133+08
P169120451	基本指标	yb	一般检查	010109	舒张压	66			2016-09-17 01:00:05.104407+08
P169120451	基本指标	yb	一般检查	010110	腰围	65			2016-09-17 01:00:05.107395+08
P169120449	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-17 01:00:05.129576+08
P169120449	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	2.5	mg/L	0-3.00	2016-09-17 01:00:05.132706+08
P169120451	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.5	mg/L	0-3.00	2016-09-17 01:00:05.144874+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304585	基因检测结果	有人乳头状瘤病毒感染			2016-09-17 01:00:05.153972+08
P167270186	基本指标	None	None	010105	体重指数	22.05			2016-08-11 13:44:12.7579+08
P167270187	基本指标	None	None	100402	甘油三酯	1.32	mmol/l	<1.7	2016-08-11 13:44:12.726959+08
P167270187	基本指标	None	None	100504	高密度脂蛋白胆固醇	1.44	mmol/l	1.16-1.42	2016-08-11 13:44:12.729776+08
P167270187	基本指标	None	None	100505	低密度脂蛋白胆固醇	2.81	mmol/l	高危人群<2.59;健康人<4.14	2016-08-11 13:44:12.732573+08
P164190212	基本指标	yb	一般检查	010109	舒张压	95			2016-09-10 01:00:04.542244+08
P167270186	基本指标	None	None	010109	舒张压	73			2016-08-11 13:44:12.760741+08
P167270186	基本指标	None	None	010110	腰围	68			2016-08-11 13:44:12.763526+08
P167270187	基本指标	None	None	010103	收缩压	102			2016-08-11 13:44:12.766506+08
P167270187	基本指标	None	None	010105	体重指数	24.05			2016-08-11 13:44:12.769256+08
P167270187	基本指标	None	None	010109	舒张压	63			2016-08-11 13:44:12.772046+08
P167270187	基本指标	None	None	010110	腰围	84			2016-08-11 13:44:12.774878+08
P167270185	基本指标	None	None	010105	体重指数	27.67			2016-08-11 13:44:12.74676+08
P164190212	基本指标	yb	一般检查	010110	腰围	97			2016-09-10 01:00:04.545171+08
P169120451	心血管病风险筛查	us	颈动脉彩超	000003	检查结论	未见恶性细胞和上皮内病变细胞\r\n\r\n\r\n\r\n			2016-09-17 01:00:05.110402+08
P164190212	心血管病风险筛查	hy	血小板聚集（AA血液科）	205311	血小板平均聚集率	80	%	35.0-75.0	2016-09-10 01:00:04.576871+08
P164190212	心血管病风险筛查	hy	血小板聚集（AA血液科）	205312	红细胞初始值	4.69	*10^12/L	4.00-5.50	2016-09-10 01:00:04.579795+08
P164190212	心血管病风险筛查	hy	血小板聚集（AA血液科）	205313	血小板最小聚集率	40	%	0-75	2016-09-10 01:00:04.582749+08
P164190212	心血管病风险筛查	hy	凝血常规检查（血液科）	105013	凝血酶时间（TT）	18.7	sec	14-21	2016-09-10 01:00:04.585666+08
P164190212	心血管病风险筛查	hy	凝血常规检查（血液科）	105055	凝血酶原时间	10.7	sec	9-14	2016-09-10 01:00:04.588616+08
P164190212	心血管病风险筛查	hy	凝血常规检查（血液科）	105059	凝血酶原国际标准化比值	0.93		0.8-1.5	2016-09-10 01:00:04.591569+08
P167270185	基本指标	None	None	010109	舒张压	77			2016-08-11 13:44:12.749638+08
P164190212	心血管病风险筛查	hy	凝血常规检查（血液科）	105060	活化部分凝血活酶时间	23.9	sec	20-40	2016-09-10 01:00:04.594499+08
P164190212	心血管病风险筛查	hy	凝血常规检查（血液科）	105063	纤维蛋白原浓度	2.82	g/L	2-4	2016-09-10 01:00:04.597427+08
P164190212	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-10 01:00:04.600374+08
P164190212	基本指标	hy	肝肾功能血脂血糖	100401	总胆固醇	6.35	mmol/l	高危人群<4.14;健康人<6.22	2016-09-10 01:00:04.531213+08
P164190212	基本指标	yb	一般检查	010103	收缩压	141			2016-09-10 01:00:04.536428+08
P169120449	腺癌/卵巢癌风险筛查	fk	妇科检查	000001	结论	慢性宫颈炎    建议6个月内复查			2016-09-17 01:00:05.113418+08
P169120451	腺癌/卵巢癌风险筛查	fk	妇科检查	000001	结论	慢性宫颈炎    建议6个月内复查			2016-09-17 01:00:05.116428+08
P169120449	腺癌/卵巢癌风险筛查	ez	液基细胞学检查	000003	检查结论	未见恶性细胞和上皮内病变细胞\r\n\r\n\r\n\r\n			2016-09-17 01:00:05.119451+08
P164190212	心血管病风险筛查	us	颈动脉彩超	000003	检查结论	血管内皮扩张率低于正常值    提示您的血管内皮机能正在降低，建议接受医生的指导和治疗、注意改善生活习惯，半年后复查。			2016-09-10 01:00:04.548066+08
P164190212	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	18.2	μmol/L	0-15	2016-09-10 01:00:04.561413+08
P164190212	心血管病风险筛查	hy	血小板聚集（AA血液科）	205307	血小板项目初始值	150	*10^9/L	100-300	2016-09-10 01:00:04.564434+08
P164190212	心血管病风险筛查	hy	血小板聚集（AA血液科）	205308	平均血小板体积初始值	9.35	fL	6.00-12.00	2016-09-10 01:00:04.567406+08
P164190212	心血管病风险筛查	hy	血小板聚集（AA血液科）	205309	血小板最大聚集率	80	%	35.0-75.0	2016-09-10 01:00:04.570358+08
P164190212	心血管病风险筛查	hy	血小板聚集（AA血液科）	205310	血小板最大聚集点	5	P	3-8	2016-09-10 01:00:04.573803+08
P167270185	基本指标	None	None	100402	甘油三酯	1.36	mmol/l	<1.7	2016-08-11 13:44:12.699395+08
P167270185	基本指标	None	None	100504	高密度脂蛋白胆固醇	1.07	mmol/l	1.16-1.42	2016-08-11 13:44:12.696701+08
P167050081	基本指标	None	None	107501	空腹血糖	5.8	mmol/L	3.6-6.1	2016-08-11 13:44:12.540179+08
P167050081	基本指标	None	None	010103	收缩压	140			2016-08-11 13:44:12.565837+08
P167050081	基本指标	None	None	010105	体重指数	26.12			2016-08-11 13:44:12.569072+08
P167050081	基本指标	None	None	010109	舒张压	90			2016-08-11 13:44:12.571884+08
P167050081	基本指标	None	None	010110	腰围	83			2016-08-11 13:44:12.574729+08
P167270184	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.18	mmol/l	1.16-1.42	2016-09-14 01:00:04.527142+08
P167270184	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.44	mmol/l	<1.7	2016-09-14 01:00:04.529929+08
P167270184	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.28	mmol/l	高危人群<4.14;健康人<6.22	2016-09-14 01:00:04.532693+08
P167270184	基本指标	yb	一般检查	010103	收缩压	128			2016-09-14 01:00:04.535524+08
P167270184	基本指标	yb	一般检查	010105	体重指数	23.92			2016-09-14 01:00:04.538406+08
P167270184	基本指标	yb	一般检查	010109	舒张压	91			2016-09-14 01:00:04.541235+08
P167270184	基本指标	yb	一般检查	010110	腰围	77			2016-09-14 01:00:04.543968+08
P167270184	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	16.1	μmol/L	0-15	2016-09-14 01:00:04.55963+08
P167270184	心血管病风险筛查	hy	血小板聚集（AA血液科）	205307	血小板项目初始值	165	*10^9/L	100-300	2016-09-14 01:00:04.562671+08
P167270184	心血管病风险筛查	hy	血小板聚集（AA血液科）	205308	平均血小板体积初始值	9.65	fL	6.00-12.00	2016-09-14 01:00:04.565519+08
P167270184	心血管病风险筛查	hy	血小板聚集（AA血液科）	205309	血小板最大聚集率	77.6	%	35.0-75.0	2016-09-14 01:00:04.568365+08
P167270184	心血管病风险筛查	hy	血小板聚集（AA血液科）	205310	血小板最大聚集点	4	P	3-8	2016-09-14 01:00:04.571168+08
P167270184	心血管病风险筛查	hy	血小板聚集（AA血液科）	205311	血小板平均聚集率	76.4	%	35.0-75.0	2016-09-14 01:00:04.57395+08
P167270184	心血管病风险筛查	hy	血小板聚集（AA血液科）	205312	红细胞初始值	4.66	*10^12/L	4.00-5.50	2016-09-14 01:00:04.576767+08
P167270184	心血管病风险筛查	hy	血小板聚集（AA血液科）	205313	血小板最小聚集率	39	%	0-75	2016-09-14 01:00:04.579598+08
P167270184	心血管病风险筛查	hy	凝血常规检查（血液科）	105013	凝血酶时间（TT）	18.1	sec	14-21	2016-09-14 01:00:04.582425+08
P167270184	心血管病风险筛查	hy	凝血常规检查（血液科）	105055	凝血酶原时间	10.9	sec	9-14	2016-09-14 01:00:04.585307+08
P167230072	基本指标	None	None	100504	高密度脂蛋白胆固醇	1.67	mmol/l	1.16-1.42	2016-08-11 13:44:12.622438+08
P167270184	心血管病风险筛查	hy	凝血常规检查（血液科）	105059	凝血酶原国际标准化比值	0.94		0.8-1.5	2016-09-14 01:00:04.588411+08
P167230072	基本指标	None	None	100401	总胆固醇	4.51	mmol/l	高危人群<4.14;健康人<6.22	2016-08-11 13:44:12.627805+08
P167270186	基本指标	None	None	100619	白球蛋白比值	1.6		1.5-2.5	2016-08-11 13:44:12.718475+08
P167270186	基本指标	None	None	100505	低密度脂蛋白胆固醇	2.64	mmol/l	高危人群<2.59;健康人<4.14	2016-08-11 13:44:12.712816+08
P167270186	基本指标	None	None	100504	高密度脂蛋白胆固醇	1.5	mmol/l	1.29-1.55	2016-08-11 13:44:12.710104+08
P167270186	基本指标	None	None	100402	甘油三酯	0.92	mmol/l	<1.7	2016-08-11 13:44:12.70752+08
P167270186	基本指标	None	None	100401	总胆固醇	4.56	mmol/l	高危人群<4.14;健康人<6.22	2016-08-11 13:44:12.70474+08
P167130172	基本指标	None	None	107501	空腹血糖	5.68	mmol/l	3.9-6.1	2016-08-11 13:44:12.609177+08
P167230072	基本指标	None	None	010110	腰围	83			2016-08-11 13:44:12.658785+08
P167130172	基本指标	None	None	100619	白球蛋白比值	1.7		1.5-2.5	2016-08-11 13:44:12.606488+08
P167230072	基本指标	None	None	010103	收缩压	135			2016-08-11 13:44:12.650791+08
P167130172	基本指标	None	None	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.22		0.17-0.45	2016-08-11 13:44:12.603819+08
P167130172	基本指标	None	None	100505	低密度脂蛋白胆固醇	2.73	mmol/l	高危人群<2.59;健康人<4.14	2016-08-11 13:44:12.600977+08
P167270185	基本指标	None	None	100505	低密度脂蛋白胆固醇	3.83	mmol/l	高危人群<2.59;健康人<4.14	2016-08-11 13:44:12.69407+08
P167270185	基本指标	None	None	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.19		0.17-0.45	2016-08-11 13:44:12.691471+08
P167130172	基本指标	None	None	100504	高密度脂蛋白胆固醇	0.98	mmol/l	1.16-1.42	2016-08-11 13:44:12.598424+08
P167130172	基本指标	None	None	100402	甘油三酯	1.71	mmol/l	<1.7	2016-08-11 13:44:12.595422+08
P167290010	基本指标	None	None	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.28		0.17-0.45	2016-08-11 13:44:12.672637+08
P167290010	基本指标	None	None	100505	低密度脂蛋白胆固醇	2.07	mmol/l	高危人群<2.59;健康人<3.12	2016-08-11 13:44:12.675407+08
P167290010	基本指标	None	None	100504	高密度脂蛋白胆固醇	1.3	mmol/l	1.16-1.42	2016-08-11 13:44:12.678083+08
P167290010	基本指标	None	None	100402	甘油三酯	3.22	mmol/l	<1.7	2016-08-11 13:44:12.680708+08
P167290010	基本指标	None	None	100401	总胆固醇	4.59	mmol/l	高危人群<4.14;健康人<6.22	2016-08-11 13:44:12.683505+08
P167270187	基本指标	None	None	100401	总胆固醇	4.85	mmol/l	高危人群<4.14;健康人<6.22	2016-08-11 13:44:12.724156+08
P167270185	基本指标	None	None	100401	总胆固醇	5.52	mmol/l	高危人群<4.14;健康人<6.22	2016-08-11 13:44:12.702115+08
P167270185	基本指标	None	None	100619	白球蛋白比值	1.8		1.5-2.5	2016-08-11 13:44:12.688836+08
P167270185	基本指标	None	None	107501	空腹血糖	6.71	mmol/l	3.9-6.1	2016-08-11 13:44:12.686211+08
P167230072	基本指标	None	None	010105	体重指数	23.6			2016-08-11 13:44:12.653484+08
P167270185	基本指标	None	None	010110	腰围	91			2016-08-11 13:44:12.752472+08
P167270184	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.61	mmol/l	3.9-6.1	2016-09-14 01:00:04.515643+08
P167270184	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.9		1.5-2.5	2016-09-14 01:00:04.518614+08
P167270184	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.22		0.17-0.45	2016-09-14 01:00:04.521473+08
P167270184	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	3.45	mmol/l	高危人群<2.59;健康人<4.14	2016-09-14 01:00:04.524332+08
P169120133	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-16 01:00:04.966426+08
P169120133	风湿免疫风险筛查	hy	血沉	111607	红细胞沉降率	7	mm/hr	0-15	2016-09-16 01:00:04.969413+08
P169120449	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.38		0.17-0.45	2016-09-17 01:00:05.015937+08
P169120449	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	1.37	mmol/l	高危人群<2.59;健康人<4.14	2016-09-17 01:00:05.018901+08
P169120449	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.25	mmol/l	1.29-1.55	2016-09-17 01:00:05.021968+08
P169120449	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.53	mmol/l	<1.7	2016-09-17 01:00:05.024982+08
P169120449	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	3.32	mmol/l	高危人群<4.14;健康人<6.22	2016-09-17 01:00:05.027964+08
P169120450	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	3.75	mmol/l	高危人群<4.14;健康人<6.22	2016-09-17 01:00:05.031102+08
P169120450	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.33	mmol/l	<1.7	2016-09-17 01:00:05.034141+08
P169120450	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.39	mmol/l	1.16-1.42	2016-09-17 01:00:05.037211+08
P169120450	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	1.76	mmol/l	高危人群<2.59;健康人<4.14	2016-09-17 01:00:05.040046+08
P169120451	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.64	mmol/l	3.9-6.1	2016-09-17 01:00:05.071026+08
P169120449	基本指标	yb	一般检查	010103	收缩压	103			2016-09-17 01:00:05.074055+08
P169120449	基本指标	yb	一般检查	010105	体重指数	22.49			2016-09-17 01:00:05.077121+08
P169120449	基本指标	yb	一般检查	010109	舒张压	64			2016-09-17 01:00:05.079925+08
P169120450	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.37		0.17-0.45	2016-09-17 01:00:05.043661+08
P169120449	基本指标	yb	一般检查	010110	腰围	85			2016-09-17 01:00:05.082902+08
P169120449	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.5		1.5-2.5	2016-09-17 01:00:05.012985+08
P169120450	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.9		1.5-2.5	2016-09-17 01:00:05.04684+08
P169120450	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.93	mmol/l	3.9-6.1	2016-09-17 01:00:05.049817+08
P169120450	基本指标	yb	一般检查	010103	收缩压	109			2016-09-17 01:00:05.085877+08
P169120451	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	4.53	mmol/l	高危人群<4.14;健康人<6.22	2016-09-17 01:00:05.052899+08
P169120451	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.41	mmol/l	<1.7	2016-09-17 01:00:05.055994+08
P169120451	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.63	mmol/l	1.29-1.55	2016-09-17 01:00:05.058913+08
P169120451	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.26	mmol/l	高危人群<2.59;健康人<4.14	2016-09-17 01:00:05.061914+08
P169120451	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.36		0.17-0.45	2016-09-17 01:00:05.06494+08
P169120450	基本指标	yb	一般检查	010105	体重指数	18.82			2016-09-17 01:00:05.088845+08
P169120450	基本指标	yb	一般检查	010109	舒张压	60			2016-09-17 01:00:05.09181+08
P169120451	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.8		1.5-2.5	2016-09-17 01:00:05.068033+08
P169120450	基本指标	yb	一般检查	010110	腰围	70			2016-09-17 01:00:05.094895+08
P167270186	基本指标	None	None	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.33		0.17-0.45	2016-08-11 13:44:12.715502+08
P167270184	心血管病风险筛查	hy	凝血常规检查（血液科）	105060	活化部分凝血活酶时间	20.9	sec	20-40	2016-09-14 01:00:04.591209+08
P167270184	心血管病风险筛查	hy	凝血常规检查（血液科）	105063	纤维蛋白原浓度	2.92	g/L	2-4	2016-09-14 01:00:04.594941+08
P167270184	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-14 01:00:04.597888+08
P167270184	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	2.2	mg/L	0-3.00	2016-09-14 01:00:04.60067+08
P169120133	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.78	mmol/l	3.9-6.1	2016-09-16 01:00:04.916156+08
P169120133	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.7		1.5-2.5	2016-09-16 01:00:04.919432+08
P169120133	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.19		0.17-0.45	2016-09-16 01:00:04.922813+08
P169120133	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	4.01	mmol/l	高危人群<2.59;健康人<4.14	2016-09-16 01:00:04.925933+08
P169120133	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.07	mmol/l	1.16-1.42	2016-09-16 01:00:04.928932+08
P169120133	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.46	mmol/l	<1.7	2016-09-16 01:00:04.932057+08
P169120133	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.74	mmol/l	高危人群<4.14;健康人<6.22	2016-09-16 01:00:04.935047+08
P169120133	基本指标	yb	一般检查	010103	收缩压	107			2016-09-16 01:00:04.937995+08
P169120133	基本指标	yb	一般检查	010105	体重指数	28.73			2016-09-16 01:00:04.940926+08
P169120133	基本指标	yb	一般检查	010109	舒张压	72			2016-09-16 01:00:04.943848+08
P169120133	基本指标	yb	一般检查	010110	腰围	101			2016-09-16 01:00:04.946763+08
P169120133	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	血管内皮扩张率正常范围内    提示您的血管内皮层功能很活跃，请维持现在血管的状态、注意生活习惯，一年后复查。			2016-09-16 01:00:04.949719+08
P169120133	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	10.1	μmol/L	0-15	2016-09-16 01:00:04.963408+08
P169120133	风湿免疫风险筛查	hy	类风湿因子(RF)测定	200202	类风湿因子	12	IU/ml	0-18	2016-09-16 01:00:04.972531+08
P169120133	风湿免疫风险筛查	hy	抗链球菌溶血素O测定	113401	抗链球菌溶血素“O”	45	IU/ml	0-160	2016-09-16 01:00:04.975541+08
P169120133	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	2.3	mg/L	0-3.00	2016-09-16 01:00:04.978589+08
P169120133	腺癌/卵巢癌风险筛查	hy	CEA(核)	116501	癌胚抗原	1.18	ng/ml	0-4.7正常人群，0-6.5 吸烟人群	2016-09-16 01:00:04.981626+08
P169120133	腺癌/卵巢癌风险筛查	hy	CA125(核)	116505	CA-125	9.29	U/ml	0-35	2016-09-16 01:00:04.98461+08
P169120133	腺癌/卵巢癌风险筛查	hy	CA199(核医学)	116506	胃肠癌抗原(CA-199)	29.11	U/mL	0-27	2016-09-16 01:00:04.98758+08
P169120449	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.58	mmol/l	3.9-6.1	2016-09-17 01:00:05.009839+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304603	HPV68	阴性			2016-09-17 01:00:05.200647+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304608	HPV44	阴性			2016-09-17 01:00:05.215787+08
P167230072	基本指标	None	None	107501	空腹血糖	4.3	mmol/l	3.9-6.1	2016-08-11 13:44:12.611806+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304604	HPV11	阴性			2016-09-17 01:00:05.203693+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304605	HPV42	阴性			2016-09-17 01:00:05.206707+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304593	HPV35	阴性			2016-09-17 01:00:05.237011+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304606	HPV43	阴性			2016-09-17 01:00:05.209703+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304594	HPV39	阴性			2016-09-17 01:00:05.239813+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304609	HPVCP8304	阴性			2016-09-17 01:00:05.218788+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304585	基因检测结果	有人乳头状瘤病毒感染			2016-09-17 01:00:05.221836+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304589	HPV16	阴性			2016-09-17 01:00:05.224846+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304590	HPV18	阴性			2016-09-17 01:00:05.227873+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304591	HPV31	阴性			2016-09-17 01:00:05.230912+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304592	HPV33	阴性			2016-09-17 01:00:05.234037+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304595	HPV45	阴性			2016-09-17 01:00:05.242854+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304603	HPV68	阴性			2016-09-17 01:00:05.266993+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304596	HPV51	阴性			2016-09-17 01:00:05.24582+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304604	HPV11	阴性			2016-09-17 01:00:05.269834+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304597	HPV52	陽性(+)			2016-09-17 01:00:05.248914+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304598	HPV53	阴性			2016-09-17 01:00:05.251983+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304599	HPV56	阴性			2016-09-17 01:00:05.25497+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304600	HPV58	阴性			2016-09-17 01:00:05.25799+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304601	HPV59	阴性			2016-09-17 01:00:05.261038+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304602	HPV66	阴性			2016-09-17 01:00:05.26402+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304605	HPV42	阴性			2016-09-17 01:00:05.272782+08
P169190468	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	2.9	mmol/l	高危人群<2.59;健康人<4.14	2016-09-23 01:00:05.578223+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304606	HPV43	阴性			2016-09-17 01:00:05.275762+08
P169190468	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.45	mmol/l	1.16-1.42	2016-09-23 01:00:05.580994+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304607	HPV6	阴性			2016-09-17 01:00:05.279521+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304608	HPV44	阴性			2016-09-17 01:00:05.282596+08
P169120451	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304609	HPVCP8304	阴性			2016-09-17 01:00:05.285683+08
P169190468	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	4.93	mmol/l	3.9-6.1	2016-09-23 01:00:05.568729+08
P169190468	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.9		1.5-2.5	2016-09-23 01:00:05.572215+08
P169190468	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.28		0.17-0.45	2016-09-23 01:00:05.575222+08
P169190468	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	1.74	mmol/l	<1.7	2016-09-23 01:00:05.583801+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304606	HPV43	阴性			2016-09-25 01:00:05.071701+08
P169190468	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.14	mmol/l	高危人群<4.14;健康人<6.22	2016-09-23 01:00:05.586662+08
P169190468	基本指标	yb	一般检查	010103	收缩压	134			2016-09-23 01:00:05.58954+08
P169190468	基本指标	yb	一般检查	010105	体重指数	23.37			2016-09-23 01:00:05.592369+08
P169190468	基本指标	yb	一般检查	010109	舒张压	83			2016-09-23 01:00:05.595233+08
P169190468	基本指标	yb	一般检查	010110	腰围	80			2016-09-23 01:00:05.598077+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304604	HPV11	阴性			2016-09-25 01:00:05.065656+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304605	HPV42	阴性			2016-09-25 01:00:05.068632+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304606	HPV43	阴性			2016-08-26 12:42:38.512072+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304607	HPV6	阴性			2016-08-26 12:42:38.514989+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304608	HPV44	阴性			2016-08-26 12:42:38.517895+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304609	HPVCP8304	阴性			2016-08-26 12:42:38.520804+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304589	HPV16	阴性			2016-09-17 01:00:05.157036+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304590	HPV18	阴性			2016-09-17 01:00:05.161112+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304591	HPV31	阴性			2016-09-17 01:00:05.164214+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304607	HPV6	阴性			2016-09-17 01:00:05.212723+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304592	HPV33	阴性			2016-09-17 01:00:05.167261+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304593	HPV35	阴性			2016-09-17 01:00:05.170247+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304594	HPV39	阴性			2016-09-17 01:00:05.17321+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304595	HPV45	阴性			2016-09-17 01:00:05.176171+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304596	HPV51	阴性			2016-09-17 01:00:05.179384+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304597	HPV52	陽性(+)			2016-09-17 01:00:05.18246+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304598	HPV53	阴性			2016-09-17 01:00:05.185479+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304599	HPV56	阴性			2016-09-17 01:00:05.188519+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304600	HPV58	阴性			2016-09-17 01:00:05.191502+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304601	HPV59	阴性			2016-09-17 01:00:05.194545+08
P169120449	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304602	HPV66	阴性			2016-09-17 01:00:05.197609+08
P168170068	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-26 12:42:38.395295+08
P168170068	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.7	mg/L	0-3.00	2016-08-26 12:42:38.398103+08
P168020116	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	10.3	mg/L	0-10	2016-08-19 01:00:03.011608+08
P168020116	风湿免疫风险筛查	hy	血沉	111607	红细胞沉降率	2	mm/hr	0-15	2016-08-19 01:00:03.01446+08
P168020116	风湿免疫风险筛查	hy	类风湿因子(RF)测定	200202	类风湿因子	0	IU/ml	0-18	2016-08-19 01:00:03.017246+08
P168020116	风湿免疫风险筛查	hy	抗链球菌溶血素O测定	113401	抗链球菌溶血素“O”	85	IU/ml	0-160	2016-08-19 01:00:03.024679+08
P168020113	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-19 01:00:03.000318+08
P168160792	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.1	mg/L	0-3.00	2016-08-26 12:42:38.429842+08
P168160792	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-26 12:42:38.426921+08
P167270185	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.2	mg/L	0-3.00	2016-08-19 01:00:02.997586+08
P168020113	风湿免疫风险筛查	hy	血沉	111607	红细胞沉降率	4	mm/hr	0-15	2016-08-19 01:00:03.003043+08
P168020113	风湿免疫风险筛查	hy	类风湿因子(RF)测定	200202	类风湿因子	0	IU/ml	0-18	2016-08-19 01:00:03.005882+08
P168020113	风湿免疫风险筛查	hy	抗链球菌溶血素O测定	113401	抗链球菌溶血素“O”	41	IU/ml	0-160	2016-08-19 01:00:03.008745+08
P168020114	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-19 01:00:03.043028+08
P168020114	风湿免疫风险筛查	hy	血沉	111607	红细胞沉降率	6	mm/hr	0-15	2016-08-19 01:00:03.045902+08
P168020114	风湿免疫风险筛查	hy	类风湿因子(RF)测定	200202	类风湿因子	0	IU/ml	0-18	2016-08-19 01:00:03.04881+08
P168020114	风湿免疫风险筛查	hy	抗链球菌溶血素O测定	113401	抗链球菌溶血素“O”	10	IU/ml	0-160	2016-08-19 01:00:03.051895+08
P168020117	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-19 01:00:03.031568+08
P168020117	风湿免疫风险筛查	hy	血沉	111607	红细胞沉降率	3	mm/hr	0-15	2016-08-19 01:00:03.034454+08
P168020117	风湿免疫风险筛查	hy	类风湿因子(RF)测定	200202	类风湿因子	0	IU/ml	0-18	2016-08-19 01:00:03.037247+08
P168020117	风湿免疫风险筛查	hy	抗链球菌溶血素O测定	113401	抗链球菌溶血素“O”	35	IU/ml	0-160	2016-08-19 01:00:03.040093+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304585	基因检测结果	未发现人乳头瘤病毒			2016-08-26 12:42:38.459076+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304589	HPV16	阴性			2016-08-26 12:42:38.462009+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304590	HPV18	阴性			2016-08-26 12:42:38.464829+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304591	HPV31	阴性			2016-08-26 12:42:38.467751+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304592	HPV33	阴性			2016-08-26 12:42:38.470631+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304593	HPV35	阴性			2016-08-26 12:42:38.473471+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304594	HPV39	阴性			2016-08-26 12:42:38.476716+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304595	HPV45	阴性			2016-08-26 12:42:38.48022+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304596	HPV51	阴性			2016-08-26 12:42:38.483068+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304597	HPV52	阴性			2016-08-26 12:42:38.485957+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304598	HPV53	阴性			2016-08-26 12:42:38.488877+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304599	HPV56	阴性			2016-08-26 12:42:38.491822+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304600	HPV58	阴性			2016-08-26 12:42:38.494656+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304603	HPV68	阴性			2016-08-26 12:42:38.503533+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304604	HPV11	阴性			2016-08-26 12:42:38.506433+08
P168220014	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304605	HPV42	阴性			2016-08-26 12:42:38.509177+08
P169190468	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	血管内皮扩张率低于正常值    提示您的血管内皮机能正在降低，建议接受医生的指导和治疗、注意改善生活习惯，半年后复查。			2016-09-23 01:00:05.600965+08
P169190468	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	13.1	μmol/L	0-15	2016-09-23 01:00:05.615475+08
P169190468	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-09-23 01:00:05.618605+08
P169190468	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	1	mg/L	0-3.00	2016-09-23 01:00:05.621583+08
P169190468	腺癌/卵巢癌风险筛查	hy	CEA(核)	116501	癌胚抗原	5.45	ng/ml	0-4.7正常人群，0-6.5 吸烟人群	2016-09-23 01:00:05.624472+08
P168020116	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	10	μmol/L	0-15	2016-08-19 01:00:02.932866+08
P168020113	心血管病风险筛查	hy	同型半胱氨酸	100647	同型半胱氨酸	11.1	μmol/L	0-15	2016-08-19 01:00:02.930231+08
P168220014	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	2.9	mg/L	0-3.00	2016-08-26 12:42:38.347875+08
P167270186	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-19 01:00:03.054855+08
P167270186	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.4	mg/L	0-3.00	2016-08-19 01:00:03.057751+08
P167230072	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.5	mg/L	0-3.00	2016-08-19 01:00:02.979806+08
P167230072	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-19 01:00:02.976931+08
P168190032	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-26 12:42:38.370467+08
P168190032	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.9	mg/L	0-3.00	2016-08-26 12:42:38.37345+08
P167270187	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-19 01:00:02.98896+08
P167270187	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.9	mg/L	0-3.00	2016-08-19 01:00:02.991811+08
P168160788	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-26 12:42:38.382823+08
P168160788	风湿免疫风险筛查	hy	超敏C反应蛋白	107102	超敏C反应蛋白	0.3	mg/L	0-3.00	2016-08-26 12:42:38.385782+08
P167270185	风湿免疫风险筛查	hy	C-反应蛋白	107101	C-反应蛋白(CRP)	<5	mg/L	0-10	2016-08-19 01:00:02.994665+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304608	HPV44	阴性			2016-08-19 01:00:03.187364+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304591	HPV31	阴性			2016-09-25 01:00:05.026875+08
P167280908	基本指标	yb	一般检查	010105	体重指数	24.49			2016-09-25 01:00:04.995484+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304592	HPV33	阴性			2016-09-25 01:00:05.029848+08
P167280908	基本指标	yb	一般检查	010109	舒张压	73			2016-09-25 01:00:04.998431+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304593	HPV35	阴性			2016-09-25 01:00:05.032798+08
P167280908	基本指标	yb	一般检查	010110	腰围	76			2016-09-25 01:00:05.001433+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304594	HPV39	阴性			2016-09-25 01:00:05.035765+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304585	基因检测结果	有人乳头状瘤病毒感染			2016-09-25 01:00:05.017848+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304595	HPV45	阴性			2016-09-25 01:00:05.038764+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304589	HPV16	阴性			2016-09-25 01:00:05.020886+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304596	HPV51	陽性(+)			2016-09-25 01:00:05.041856+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304590	HPV18	阴性			2016-09-25 01:00:05.023899+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304609	HPVCP8304	阴性			2016-08-19 01:00:03.190093+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304597	HPV52	阴性			2016-09-25 01:00:05.044815+08
P167280908	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	未见恶性细胞和上皮内病变细胞\r\n\r\n\r\n\r\n			2016-09-25 01:00:05.004433+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	105014	血清铁蛋白测定	146.17	ng/ml	<322	2016-08-19 01:00:03.063466+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	116504	游离前列腺特异性抗原（F-PSA）	0.43	ng/ml	<1.00	2016-08-19 01:00:03.069145+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	116506	胃肠癌抗原(CA-199)	3.52	KU/L	<35.00	2016-08-19 01:00:03.074981+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	201393	神经原特异性烯醇化酶	4.86	ng/ml	<13.00	2016-08-19 01:00:03.080831+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	301264	前列腺特异抗原(PSA)	1.93	ng/ml	<5	2016-08-19 01:00:03.08677+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	301285	糖链抗原242	1.64	U/ml	<20.00	2016-08-19 01:00:03.09239+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	101001	甲胎蛋白	1.53	ng/ml	<20.00	2016-08-19 01:00:03.060532+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	116501	癌胚抗原	1.04	ng/ml	<5.00	2016-08-19 01:00:03.066305+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	116505	CA-125	9.71	KU/L	<35.00	2016-08-19 01:00:03.072109+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	116705	CA-153	3.17	KU/L	<35.00	2016-08-19 01:00:03.077883+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	201394	人绒毛膜促性腺激素	0.69	ng/ml	<3.00	2016-08-19 01:00:03.083768+08
P167230072	腺癌/卵巢癌风险筛查	hy	C-12	301273	生长激素	1.06	ng/ml	<7.50	2016-08-19 01:00:03.089549+08
P167280908	基本指标	hy	肝全肾功血脂血糖	107501	空腹血糖	5.38	mmol/l	3.9-6.1	2016-09-25 01:00:04.971234+08
P167280908	基本指标	hy	肝全肾功血脂血糖	100619	白球蛋白比值	1.9		1.5-2.5	2016-09-25 01:00:04.974337+08
P167280908	基本指标	hy	肝全肾功血脂血糖	100508	高密度胆固醇(HDL)比总胆固醇(CHO)	0.21		0.17-0.45	2016-09-25 01:00:04.977403+08
P167280908	基本指标	hy	肝全肾功血脂血糖	100505	低密度脂蛋白胆固醇	3.53	mmol/l	高危人群<2.59;健康人<4.14	2016-09-25 01:00:04.980383+08
P167280908	基本指标	hy	肝全肾功血脂血糖	100504	高密度脂蛋白胆固醇	1.21	mmol/l	1.29-1.55	2016-09-25 01:00:04.983363+08
P167280908	基本指标	hy	肝全肾功血脂血糖	100402	甘油三酯	2.23	mmol/l	<1.7	2016-09-25 01:00:04.986389+08
P167280908	基本指标	hy	肝全肾功血脂血糖	100401	总胆固醇	5.75	mmol/l	高危人群<4.14;健康人<6.22	2016-09-25 01:00:04.989383+08
P167280908	基本指标	yb	一般检查	010103	收缩压	113			2016-09-25 01:00:04.992416+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304598	HPV53	阴性			2016-09-25 01:00:05.047798+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304599	HPV56	阴性			2016-09-25 01:00:05.050786+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304600	HPV58	阴性			2016-09-25 01:00:05.053751+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304601	HPV59	阴性			2016-09-25 01:00:05.056735+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304602	HPV66	阴性			2016-09-25 01:00:05.059733+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304603	HPV68	陽性(+)			2016-09-25 01:00:05.062687+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304589	HPV16	阴性			2016-08-19 01:00:03.134019+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304590	HPV18	阴性			2016-08-19 01:00:03.136669+08
P167280908	腺癌/卵巢癌风险筛查	fk	妇科检查	000001	结论	全子宫切除术后			2016-09-25 01:00:05.007447+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304591	HPV31	阴性			2016-08-19 01:00:03.139454+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304592	HPV33	阴性			2016-08-19 01:00:03.142256+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304593	HPV35	阴性			2016-08-19 01:00:03.145409+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304594	HPV39	阴性			2016-08-19 01:00:03.148293+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304596	HPV51	阴性			2016-08-19 01:00:03.153886+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304597	HPV52	阴性			2016-08-19 01:00:03.156719+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304598	HPV53	阴性			2016-08-19 01:00:03.15946+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304599	HPV56	阴性			2016-08-19 01:00:03.162151+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304600	HPV58	阴性			2016-08-19 01:00:03.164923+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304601	HPV59	阴性			2016-08-19 01:00:03.167729+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304602	HPV66	阴性			2016-08-19 01:00:03.170333+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304603	HPV68	阴性			2016-08-19 01:00:03.17307+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304604	HPV11	阴性			2016-08-19 01:00:03.17624+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304605	HPV42	阴性			2016-08-19 01:00:03.178972+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304606	HPV43	阴性			2016-08-19 01:00:03.181752+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304607	HPV6	阴性			2016-08-19 01:00:03.184538+08
P167270186	基本指标	None	None	107501	空腹血糖	5.54	mmol/l	3.9-6.1	2016-08-11 13:44:12.721358+08
P168220014	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	未见恶性细胞和上皮内病变细胞\r\n\r\n\r\n\r\n			2016-08-26 12:42:38.069149+08
P167270186	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304585	基因检测结果	未发现人乳头瘤病毒			2016-08-19 01:00:03.131176+08
P168290068	心血管病风险筛查	us	颈部血管彩超+椎动脉彩超	000003	检查结论	血管内皮扩张率正常范围内    提示您的血管内皮层功能很活跃，请维持现在血管的状态、注意生活习惯，一年后复查。			2016-09-03 01:00:03.833015+08
P167270184	心血管病风险筛查	us	颈动脉彩超	000003	检查结论	血管内皮扩张率正常范围内    提示您的血管内皮层功能很活跃，请维持现在血管的状态、注意生活习惯，一年后复查。			2016-09-14 01:00:04.546744+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304607	HPV6	阴性			2016-09-25 01:00:05.074722+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304608	HPV44	阴性			2016-09-25 01:00:05.078001+08
P167280908	腺癌/卵巢癌风险筛查	hy	HPV分型(妇)	304609	HPVCP8304	陽性(+)			2016-09-25 01:00:05.080964+08
\.


--
-- Data for Name: xy_wenjuan; Type: TABLE DATA; Schema: public; Owner: genopipe
--

COPY xy_wenjuan (barcode, lbcode, lbname, qcode, question, answer, created_at) FROM stdin;
P167050081	3709	生活习惯-饮食	600666	45.您吃水果吗？		2016-08-11 13:44:12.888401+08
P167050081	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？		2016-08-11 13:44:12.890845+08
P167050081	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？		2016-08-11 13:44:12.893516+08
P167050081	3709	生活习惯-饮食	600669	48.您吃肥肉吗？		2016-08-11 13:44:12.896074+08
P167050081	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？		2016-08-11 13:44:12.898661+08
P167050081	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？		2016-08-11 13:44:12.901272+08
P167050081	3709	生活习惯-饮食	600672	51.您喝咖啡吗？		2016-08-11 13:44:12.90383+08
P167050081	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？		2016-08-11 13:44:12.906451+08
P167050081	3710	生活习惯-吸烟	600674	53.您吸烟吗？		2016-08-11 13:44:12.909064+08
P167050081	3710	生活习惯-吸烟	600675	53-1.您通常每天吸多少支烟？（含戒烟前）		2016-08-11 13:44:12.911655+08
P167050081	3710	生活习惯-吸烟	600676	53-2.您持续吸烟的年限？（含戒烟前）		2016-08-11 13:44:12.91433+08
P167050081	3710	生活习惯-吸烟	600677	53-3.您戒烟多长时间了？		2016-08-11 13:44:12.916909+08
P167050081	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）		2016-08-11 13:44:12.919717+08
P167050081	3711	生活习惯-饮酒	600679	54-1.您一般喝什么酒？（可多选）		2016-08-11 13:44:12.922385+08
P167050081	3711	生活习惯-饮酒	600680	54-2.您每周喝几次酒？（含戒酒前）		2016-08-11 13:44:12.92504+08
P167050081	3711	生活习惯-饮酒	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）		2016-08-11 13:44:12.92768+08
P167050081	3711	生活习惯-饮酒	600682	54-4.您持续喝酒的年限？（含戒酒前）		2016-08-11 13:44:12.930368+08
P167050081	3711	生活习惯-饮酒	600683	54-5.您戒酒多长时间了？		2016-08-11 13:44:12.933063+08
P167050081	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）		2016-08-11 13:44:12.935802+08
P167050081	3712	生活习惯-运动锻炼	600685	55-1.您常采用的锻炼方式：（可多选）		2016-08-11 13:44:12.938632+08
P167050081	3712	生活习惯-运动锻炼	600686	55-2.您每周锻炼几次？		2016-08-11 13:44:12.941307+08
P167050081	3712	生活习惯-运动锻炼	600687	55-3.您每次锻炼多长时间？		2016-08-11 13:44:12.943839+08
P167050081	3712	生活习惯-运动锻炼	600688	55-4.您坚持锻炼多少年了？		2016-08-11 13:44:12.946543+08
P167050081	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？		2016-08-11 13:44:12.94918+08
P167050081	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？		2016-08-11 13:44:12.951823+08
P167050081	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？		2016-08-11 13:44:12.954511+08
P167050081	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？		2016-08-11 13:44:12.957101+08
P167230072	3709	生活习惯-饮食	600660	39.您的饮食口味？	C.不好说	2016-08-11 13:44:13.157423+08
P167050081	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	无	2016-08-11 13:44:12.832023+08
P167050081	3702	健康史-家族史	600607	1-1.请选择疾病的名称：（可多选）		2016-08-11 13:44:12.835967+08
P167050081	3702	健康史-家族史	600608	1-2.请确定所患的恶性肿瘤名称：（可多选）		2016-08-11 13:44:12.838855+08
P167050081	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？		2016-08-11 13:44:12.841754+08
P167050081	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	高血压	2016-08-11 13:44:12.844652+08
P167050081	3703	健康史-现病史	600611	2-1.请您确认具体疾病或异常的名称：（可多选）	2016	2016-08-11 13:44:12.847467+08
P167050081	3703	健康史-现病史	600612	2-2.请选择恶性肿瘤的名称？（可多选）		2016-08-11 13:44:12.850219+08
P167050081	3703	健康史-现病史	600613	2-3.请填写您被诊断患有上述疾病或异常的年龄		2016-08-11 13:44:12.853007+08
P167050081	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	是	2016-08-11 13:44:12.855725+08
P167050081	3705	健康史-用药史	600617	4-1.您长期用哪些药物？（可多选）	降压药	2016-08-11 13:44:12.858481+08
P167050081	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？		2016-08-11 13:44:12.861301+08
P167050081	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？		2016-08-11 13:44:12.864026+08
P167050081	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）		2016-08-11 13:44:12.866617+08
P167050081	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？		2016-08-11 13:44:12.869226+08
P167050081	3709	生活习惯-饮食	600660	39.您的饮食口味？		2016-08-11 13:44:12.87197+08
P167050081	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）		2016-08-11 13:44:12.874636+08
P167050081	3709	生活习惯-饮食	600662	41.您的主食结构如何？		2016-08-11 13:44:12.877348+08
P167050081	3709	生活习惯-饮食	600663	42.您喝牛奶吗？		2016-08-11 13:44:12.879866+08
P167050081	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？		2016-08-11 13:44:12.88288+08
P164190212	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-09-10 01:00:07.775411+08
P167230072	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-11 13:44:13.116224+08
P167230072	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-11 13:44:13.122085+08
P167230072	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-11 13:44:13.128006+08
P167230072	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-08-11 13:44:13.140472+08
P167230072	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-11 13:44:13.146075+08
P167230072	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？	C.经常参加（每周4-5次）	2016-08-11 13:44:13.15173+08
P167230072	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？	B.基本能（每周有2-3次不能按时就餐）	2016-08-11 13:44:13.134467+08
P167050081	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？		2016-08-11 13:44:12.885688+08
P167270186	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-11 13:44:13.349877+08
P167230072	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.232019+08
P167230072	3710	生活习惯-吸烟	600674	53.您吸烟吗？	B.天天吸	2016-08-11 13:44:13.237774+08
P167230072	3710	生活习惯-吸烟	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	D.＞30支	2016-08-11 13:44:13.243496+08
P167230072	3710	生活习惯-吸烟	600676	53-2.您持续吸烟的年限？（含戒烟前）	D.＞20年	2016-08-11 13:44:13.248852+08
P167230072	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-11 13:44:13.254623+08
P167230072	3711	生活习惯-饮酒	600679	54-1.您一般喝什么酒？（可多选）	A.白酒；B.啤酒；C.红酒；	2016-08-11 13:44:13.260682+08
P167230072	3711	生活习惯-饮酒	600680	54-2.您每周喝几次酒？（含戒酒前）	C.＞5次	2016-08-11 13:44:13.266637+08
P167230072	3711	生活习惯-饮酒	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	C.＞5两	2016-08-11 13:44:13.272432+08
P167230072	3711	生活习惯-饮酒	600682	54-4.您持续喝酒的年限？（含戒酒前）	D.＞20年	2016-08-11 13:44:13.278302+08
P167230072	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？	B.轻体力劳动	2016-08-11 13:44:13.290038+08
P167230072	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？	B.3～5天	2016-08-11 13:44:13.295967+08
P167230072	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-08-11 13:44:13.301801+08
P167230072	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-08-11 13:44:13.307712+08
P167270185	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-08-11 13:44:13.313986+08
P167270185	3702	健康史-家族史	600607	1-1.请选择疾病的名称：（可多选）	母亲：A.高血压|65岁之后患病；C.冠心病|65岁之后患病；J.痛风；	2016-08-11 13:44:13.325469+08
P167270185	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-11 13:44:13.328425+08
P167270185	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	A.是	2016-08-11 13:44:13.343871+08
P167270185	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	A.是	2016-08-11 13:44:13.346873+08
P167270185	3705	健康史-用药史	600617	4-1.您长期用哪些药物？（可多选）	A.降压药	2016-08-11 13:44:13.355771+08
P167270185	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-11 13:44:13.358824+08
P167270185	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-08-11 13:44:13.373684+08
P167270185	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-11 13:44:13.376511+08
P167270185	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？	B.比较多（每周2-3次）	2016-08-11 13:44:13.390689+08
P167270186	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-08-11 13:44:13.31685+08
P167270186	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-11 13:44:13.364734+08
P167270187	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-08-11 13:44:13.370693+08
P167270186	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-11 13:44:13.340928+08
P167270186	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-11 13:44:13.382231+08
P167270187	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-11 13:44:13.379126+08
P167230072	3709	生活习惯-饮食	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-08-11 13:44:13.19241+08
P167270186	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-11 13:44:13.385017+08
P167270187	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-08-11 13:44:13.319632+08
P167230072	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-08-11 13:44:13.19834+08
P167270187	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？	B.比较多（每周2-3次）	2016-08-11 13:44:13.387726+08
P167230072	3709	生活习惯-饮食	600669	48.您吃肥肉吗？	B.偶尔吃	2016-08-11 13:44:13.209405+08
P167270187	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-11 13:44:13.334758+08
P167270187	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-11 13:44:13.337869+08
P167230072	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-11 13:44:13.215021+08
P167280908	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-09-25 01:00:08.425414+08
P167230072	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-08-11 13:44:13.220714+08
P167270187	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-11 13:44:13.35288+08
P167230072	3709	生活习惯-饮食	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.226434+08
P167270186	3702	健康史-家族史	600607	1-1.请选择疾病的名称：（可多选）	母亲：A.高血压|45-65岁之间患病；	2016-08-11 13:44:13.322579+08
P167270187	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-11 13:44:13.361774+08
P167230072	3709	生活习惯-饮食	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.175559+08
P167230072	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？	C.经常吃（每周3-5次）	2016-08-11 13:44:13.181072+08
P167270186	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-11 13:44:13.331157+08
P167230072	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-11 13:44:13.18673+08
P167230072	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	A.不参加	2016-08-11 13:44:13.284162+08
P167270187	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-11 13:44:13.430096+08
P167270187	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-11 13:44:13.435762+08
P167270187	3709	生活习惯-饮食	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-08-11 13:44:13.446775+08
P167270187	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	A.＜50g（少于1两）	2016-08-11 13:44:13.463533+08
P167270185	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？	A.不吃	2016-08-11 13:44:13.483574+08
P167270185	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？	A.不吃	2016-08-11 13:44:13.486517+08
P167270187	3709	生活习惯-饮食	600669	48.您吃肥肉吗？	A.不吃	2016-08-11 13:44:13.471773+08
P167270186	3709	生活习惯-饮食	600669	48.您吃肥肉吗？	C.经常吃	2016-08-11 13:44:13.474866+08
P167270187	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？	A.不吃	2016-08-11 13:44:13.480686+08
P167270185	3709	生活习惯-饮食	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-08-11 13:44:13.500903+08
P167270186	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-11 13:44:13.477782+08
P167270186	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-08-11 13:44:13.492418+08
P167270187	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-08-11 13:44:13.489469+08
P167270185	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.503813+08
P167270187	3709	生活习惯-饮食	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-08-11 13:44:13.498106+08
P167270186	3709	生活习惯-饮食	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-08-11 13:44:13.495264+08
P167270186	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.506714+08
P167270187	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.509595+08
P167270185	3710	生活习惯-吸烟	600674	53.您吸烟吗？	A.不吸	2016-08-11 13:44:13.518094+08
P167270185	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-11 13:44:13.532687+08
P167270187	3710	生活习惯-吸烟	600674	53.您吸烟吗？	C.吸烟，已戒	2016-08-11 13:44:13.512468+08
P167270186	3710	生活习惯-吸烟	600674	53.您吸烟吗？	A.不吸	2016-08-11 13:44:13.515252+08
P167270186	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-11 13:44:13.535725+08
P167270187	3710	生活习惯-吸烟	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	B.10-20支	2016-08-11 13:44:13.520895+08
P167270185	3711	生活习惯-饮酒	600679	54-1.您一般喝什么酒？（可多选）	C.红酒	2016-08-11 13:44:13.542026+08
P167270185	3711	生活习惯-饮酒	600680	54-2.您每周喝几次酒？（含戒酒前）	A.1～2次	2016-08-11 13:44:13.550908+08
P167270187	3710	生活习惯-吸烟	600676	53-2.您持续吸烟的年限？（含戒烟前）	C.10～20年	2016-08-11 13:44:13.523803+08
P167270186	3711	生活习惯-饮酒	600680	54-2.您每周喝几次酒？（含戒酒前）	A.1～2次	2016-08-11 13:44:13.553929+08
P167270186	3711	生活习惯-饮酒	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	A.1～2两	2016-08-11 13:44:13.556895+08
P167270187	3710	生活习惯-吸烟	600677	53-3.您戒烟多长时间了？	B.1～5年	2016-08-11 13:44:13.526791+08
P167270185	3711	生活习惯-饮酒	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	A.1～2两	2016-08-11 13:44:13.559909+08
P167270186	3709	生活习惯-饮食	600660	39.您的饮食口味？	A.清淡	2016-08-11 13:44:13.399065+08
P167270187	3709	生活习惯-饮食	600660	39.您的饮食口味？	A.清淡	2016-08-11 13:44:13.396367+08
P167270187	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-11 13:44:13.529754+08
P167270187	3711	生活习惯-饮酒	600679	54-1.您一般喝什么酒？（可多选）	A.白酒；B.啤酒；	2016-08-11 13:44:13.545096+08
P167270187	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）	H.无以上嗜好	2016-08-11 13:44:13.404502+08
P167270186	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）	H.无以上嗜好	2016-08-11 13:44:13.401778+08
P167270187	3711	生活习惯-饮酒	600680	54-2.您每周喝几次酒？（含戒酒前）	A.1～2次	2016-08-11 13:44:13.547996+08
P168160792	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-26 12:42:40.133521+08
P167270185	3709	生活习惯-饮食	600662	41.您的主食结构如何？	A.细粮为主	2016-08-11 13:44:13.410101+08
P167270186	3709	生活习惯-饮食	600662	41.您的主食结构如何？	B.粗细搭配	2016-08-11 13:44:13.416485+08
P167270187	3709	生活习惯-饮食	600662	41.您的主食结构如何？	A.细粮为主	2016-08-11 13:44:13.413822+08
P167270186	3709	生活习惯-饮食	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.419078+08
P167270185	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-11 13:44:13.427481+08
P167270186	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-11 13:44:13.432823+08
P167270187	3709	生活习惯-饮食	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.421893+08
P167270187	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-08-11 13:44:13.455045+08
P167270186	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-11 13:44:13.441401+08
P167270185	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-11 13:44:13.438574+08
P167270185	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？	C.200～500g（4两～1斤）	2016-08-11 13:44:13.452269+08
P167270186	3709	生活习惯-饮食	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-08-11 13:44:13.444066+08
P167270186	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？	C.200～500g（4两～1斤）	2016-08-11 13:44:13.457885+08
P167270185	3709	生活习惯-饮食	600669	48.您吃肥肉吗？	A.不吃	2016-08-11 13:44:13.469055+08
P167270186	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-08-11 13:44:13.460689+08
P167270185	3709	生活习惯-饮食	600663	42.您喝牛奶吗？	C.经常喝（每周3-5次）	2016-08-11 13:44:13.424662+08
P168020116	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-11 13:44:13.692124+08
P168020116	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-11 13:44:13.70087+08
P168020116	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-08-11 13:44:13.710054+08
P167270187	3712	生活习惯-运动锻炼	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-08-11 13:44:13.611816+08
P167270187	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？	B.轻体力劳动	2016-08-11 13:44:13.62039+08
P168020113	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-08-11 13:44:13.706814+08
P167270186	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？	B.3～5天	2016-08-11 13:44:13.631927+08
P167270186	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？	B.4～6小时	2016-08-11 13:44:13.634908+08
P168020116	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-08-11 13:44:13.654681+08
P167270187	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？	C.＞5天	2016-08-11 13:44:13.628738+08
P167270187	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-08-11 13:44:13.637781+08
P168020116	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-11 13:44:13.668703+08
P167270186	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	A.＜2小时	2016-08-11 13:44:13.649156+08
P167270187	3711	生活习惯-饮酒	600682	54-4.您持续喝酒的年限？（含戒酒前）	C.10～20年	2016-08-11 13:44:13.566095+08
P168020116	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-11 13:44:13.677377+08
P167270187	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	B.2～4小时	2016-08-11 13:44:13.646221+08
P168020113	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-08-11 13:44:13.652002+08
P168020117	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-08-11 13:44:13.657489+08
P167270187	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-11 13:44:13.57789+08
P167270187	3712	生活习惯-运动锻炼	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步；B.慢跑或快步走；F.球类运动；	2016-08-11 13:44:13.586675+08
P168020117	3702	健康史-家族史	600607	1-1.请选择疾病的名称：（可多选）	父亲：A.高血压|55岁之后患病；	2016-08-11 13:44:13.660373+08
P168020113	3702	健康史-家族史	600607	1-1.请选择疾病的名称：（可多选）	姐妹：E.糖尿病；父亲：A.高血压|55岁之后患病；	2016-08-11 13:44:13.663074+08
P168020117	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-11 13:44:13.671483+08
P168020117	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-11 13:44:13.697938+08
P167270185	3712	生活习惯-运动锻炼	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-08-11 13:44:13.606269+08
P167270185	3712	生活习惯-运动锻炼	600688	55-4.您坚持锻炼多少年了？	D.＞10年	2016-08-11 13:44:13.609079+08
P168020117	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	是	2016-08-11 13:44:13.674384+08
P168020117	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	A.是	2016-08-11 13:44:13.686272+08
P164190212	3702	健康史-家族史                                                                                             	600607	1-1.请选择疾病的名称：（可多选）	母亲：A.高血压|45-65岁之间患病；E.糖尿病；	2016-09-10 01:00:07.779726+08
P167270185	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-11 13:44:13.623105+08
P167270185	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？	B.3～5天	2016-08-11 13:44:13.625954+08
P168020117	3705	健康史-用药史	600617	4-1.您长期用哪些药物？（可多选）	A.降压药	2016-08-11 13:44:13.695051+08
P167270185	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？	B.4～6小时	2016-08-11 13:44:13.640633+08
P167270185	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-11 13:44:13.580939+08
P167270185	3712	生活习惯-运动锻炼	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步；B.慢跑或快步走；C.游泳；K.登山；	2016-08-11 13:44:13.589559+08
P167270185	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	A.＜2小时	2016-08-11 13:44:13.64343+08
P167270186	3711	生活习惯-饮酒	600682	54-4.您持续喝酒的年限？（含戒酒前）	A.＜5年	2016-08-11 13:44:13.571962+08
P167270185	3712	生活习惯-运动锻炼	600686	55-2.您每周锻炼几次？	B.3～5次	2016-08-11 13:44:13.592474+08
P167270186	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-11 13:44:13.574883+08
P167270186	3712	生活习惯-运动锻炼	600686	55-2.您每周锻炼几次？	B.3～5次	2016-08-11 13:44:13.597924+08
P167270186	3712	生活习惯-运动锻炼	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-08-11 13:44:13.60073+08
P167270186	3712	生活习惯-运动锻炼	600688	55-4.您坚持锻炼多少年了？	A.＜1年	2016-08-11 13:44:13.614651+08
P168020113	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-11 13:44:13.665859+08
P167270186	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-11 13:44:13.617507+08
P167270187	3712	生活习惯-运动锻炼	600686	55-2.您每周锻炼几次？	B.3～5次	2016-08-11 13:44:13.595234+08
P167270187	3712	生活习惯-运动锻炼	600687	55-3.您每次锻炼多长时间？	C.＞60分钟	2016-08-11 13:44:13.603527+08
P168020113	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-11 13:44:13.680378+08
P168020113	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-11 13:44:13.689212+08
P168020113	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-11 13:44:13.70381+08
P168020117	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？	B.比较多（每周2-3次）	2016-08-11 13:44:13.731684+08
P168020117	3709	生活习惯-饮食	600660	39.您的饮食口味？	B.偏咸	2016-08-11 13:44:13.734755+08
P168020117	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）	A.熏制、腌制类；C.甜点；D.辛辣；E.热烫；	2016-08-11 13:44:13.749952+08
P168020113	3709	生活习惯-饮食	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-08-11 13:44:13.795975+08
P168020116	3709	生活习惯-饮食	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-08-11 13:44:13.793127+08
P168020117	3709	生活习惯-饮食	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-08-11 13:44:13.790412+08
P168020117	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？	C.200～500g（4两～1斤）	2016-08-11 13:44:13.804558+08
P168020116	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-08-11 13:44:13.801733+08
P168020113	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-08-11 13:44:13.798829+08
P168020113	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-08-11 13:44:13.813137+08
P168020116	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-08-11 13:44:13.810211+08
P168020117	3709	生活习惯-饮食	600669	48.您吃肥肉吗？	B.偶尔吃	2016-08-11 13:44:13.821737+08
P168020117	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？	C.经常吃	2016-08-11 13:44:13.824603+08
P168020116	3709	生活习惯-饮食	600669	48.您吃肥肉吗？	B.偶尔吃	2016-08-11 13:44:13.818842+08
P168020113	3709	生活习惯-饮食	600669	48.您吃肥肉吗？	B.偶尔吃	2016-08-11 13:44:13.815955+08
P168020113	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-11 13:44:13.830434+08
P168020116	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-11 13:44:13.827496+08
P168020117	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-08-11 13:44:13.838938+08
P168020117	3709	生活习惯-饮食	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.841836+08
P168020116	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-08-11 13:44:13.836073+08
P168020113	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-08-11 13:44:13.833242+08
P168020113	3709	生活习惯-饮食	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.847508+08
P168020116	3709	生活习惯-饮食	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.844694+08
P168020117	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.856174+08
P168020116	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-08-11 13:44:13.853319+08
P168020113	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.850454+08
P168020113	3710	生活习惯-吸烟	600674	53.您吸烟吗？	A.不吸	2016-08-11 13:44:13.864863+08
P168020116	3710	生活习惯-吸烟	600674	53.您吸烟吗？	B.天天吸	2016-08-11 13:44:13.861979+08
P168020117	3710	生活习惯-吸烟	600674	53.您吸烟吗？	B.天天吸	2016-08-11 13:44:13.859119+08
P168020117	3710	生活习惯-吸烟	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	B.10-20支	2016-08-11 13:44:13.870675+08
P168020116	3710	生活习惯-吸烟	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	C.21～30支	2016-08-11 13:44:13.867752+08
P168020113	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-11 13:44:13.882627+08
P168020116	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-11 13:44:13.71924+08
P168020116	3710	生活习惯-吸烟	600676	53-2.您持续吸烟的年限？（含戒烟前）	D.＞20年	2016-08-11 13:44:13.8765+08
P168020117	3710	生活习惯-吸烟	600676	53-2.您持续吸烟的年限？（含戒烟前）	D.＞20年	2016-08-11 13:44:13.873614+08
P169300306	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	B.天天吸	2016-10-11 17:01:38.89779+08
P168020116	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-08-11 13:44:13.879444+08
P168020116	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-11 13:44:13.728599+08
P168020116	3709	生活习惯-饮食	600660	39.您的饮食口味？	A.清淡	2016-08-11 13:44:13.737751+08
P168020117	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-11 13:44:13.716231+08
P168020113	3709	生活习惯-饮食	600660	39.您的饮食口味？	A.清淡	2016-08-11 13:44:13.740862+08
P168020117	3709	生活习惯-饮食	600662	41.您的主食结构如何？	A.细粮为主	2016-08-11 13:44:13.752886+08
P168020116	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）	D.辛辣	2016-08-11 13:44:13.746919+08
P168020117	3709	生活习惯-饮食	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.768723+08
P168020113	3709	生活习惯-饮食	600662	41.您的主食结构如何？	A.细粮为主	2016-08-11 13:44:13.75935+08
P168020117	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？	C.经常吃（每周3-5次）	2016-08-11 13:44:13.771908+08
P168020117	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？	C.经常吃	2016-08-11 13:44:13.787431+08
P168020116	3709	生活习惯-饮食	600662	41.您的主食结构如何？	A.细粮为主	2016-08-11 13:44:13.756119+08
P168020113	3709	生活习惯-饮食	600663	42.您喝牛奶吗？	C.经常喝（每周3-5次）	2016-08-11 13:44:13.762528+08
P168020116	3709	生活习惯-饮食	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-11 13:44:13.765728+08
P168020113	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？	C.经常吃（每周3-5次）	2016-08-11 13:44:13.778139+08
P168020113	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-11 13:44:13.781069+08
P168020116	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？	C.经常吃（每周3-5次）	2016-08-11 13:44:13.775021+08
P168020116	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-11 13:44:13.784147+08
P168020113	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）	D.辛辣	2016-08-11 13:44:13.74395+08
P168020117	3711	生活习惯-饮酒	600679	54-1.您一般喝什么酒？（可多选）	A.白酒	2016-08-11 13:44:13.888649+08
P168020117	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？	A.＜4小时	2016-08-11 13:44:13.971806+08
P168020117	3711	生活习惯-饮酒	600680	54-2.您每周喝几次酒？（含戒酒前）	A.1～2次	2016-08-11 13:44:13.897829+08
P168020113	3712	生活习惯-运动锻炼	600688	55-4.您坚持锻炼多少年了？	C.6～10年	2016-08-11 13:44:13.943165+08
P164190212	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-09-10 01:00:07.782869+08
P168020113	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？	C.＞5天	2016-08-11 13:44:13.962089+08
P168020113	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	A.＜2小时	2016-08-11 13:44:13.981181+08
P15C280643	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-19 01:00:03.233916+08
P15C280643	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-08-19 01:00:03.223794+08
P15C280643	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-19 01:00:03.230969+08
P168020116	3712	生活习惯-运动锻炼	600686	55-2.您每周锻炼几次？	B.3～5次	2016-08-11 13:44:13.927798+08
P168020116	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-11 13:44:13.918693+08
P168020116	3712	生活习惯-运动锻炼	600685	55-1.您常采用的锻炼方式：（可多选）	B.慢跑或快步走；C.游泳；	2016-08-11 13:44:13.921736+08
P15C280643	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-19 01:00:03.236839+08
P168020116	3712	生活习惯-运动锻炼	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-08-11 13:44:13.940054+08
P168020116	3712	生活习惯-运动锻炼	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-08-11 13:44:13.937003+08
P15C280643	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-08-19 01:00:03.242938+08
P15C280643	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-19 01:00:03.246101+08
P168020117	3711	生活习惯-饮酒	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	B.3～4两	2016-08-11 13:44:13.900854+08
P168020117	3711	生活习惯-饮酒	600682	54-4.您持续喝酒的年限？（含戒酒前）	D.＞20年	2016-08-11 13:44:13.909792+08
P168020117	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	A.不参加	2016-08-11 13:44:13.912683+08
P168020116	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-11 13:44:13.949413+08
P168020116	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？	B.3～5天	2016-08-11 13:44:13.958952+08
P168020117	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-08-11 13:44:13.713086+08
P168020117	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？	B.轻体力劳动	2016-08-11 13:44:13.952549+08
P168020117	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	C.100～250g（2～5两）	2016-08-11 13:44:13.807399+08
P168020117	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？	C.＞5天	2016-08-11 13:44:13.955662+08
P167270185	3709	生活习惯-饮食	600660	39.您的饮食口味？	A.清淡	2016-08-11 13:44:13.393494+08
P168020117	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-11 13:44:13.885565+08
P168020117	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-08-11 13:44:13.975007+08
P15C280643	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？	B.基本能（每周有2-3次不能按时就餐）	2016-08-19 01:00:03.23977+08
P167270186	3711	生活习惯-饮酒	600679	54-1.您一般喝什么酒？（可多选）	C.红酒	2016-08-11 13:44:13.538909+08
P167270185	3709	生活习惯-饮食	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-08-11 13:44:13.449554+08
P167270186	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-08-11 13:44:13.367751+08
P168020113	3712	生活习惯-运动锻炼	600686	55-2.您每周锻炼几次？	B.3～5次	2016-08-11 13:44:13.930816+08
P168020113	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-11 13:44:13.94634+08
P168020113	3712	生活习惯-运动锻炼	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-08-11 13:44:13.93385+08
P168020113	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-08-11 13:44:13.965392+08
P167270186	3712	生活习惯-运动锻炼	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步；B.慢跑或快步走；K.登山；	2016-08-11 13:44:13.58371+08
P167270187	3711	生活习惯-饮酒	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	C.＞5两	2016-08-11 13:44:13.562916+08
P168020113	3711	生活习惯-饮酒	600679	54-1.您一般喝什么酒？（可多选）	A.白酒；B.啤酒；C.红酒；	2016-08-11 13:44:13.891606+08
P168020113	3711	生活习惯-饮酒	600680	54-2.您每周喝几次酒？（含戒酒前）	A.1～2次	2016-08-11 13:44:13.894798+08
P168020113	3711	生活习惯-饮酒	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	A.1～2两	2016-08-11 13:44:13.903815+08
P168020113	3711	生活习惯-饮酒	600682	54-4.您持续喝酒的年限？（含戒酒前）	B.5～10年	2016-08-11 13:44:13.906799+08
P168020113	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-11 13:44:13.915708+08
P168020113	3712	生活习惯-运动锻炼	600685	55-1.您常采用的锻炼方式：（可多选）	B.慢跑或快步走	2016-08-11 13:44:13.924768+08
P168020116	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-08-11 13:44:13.968554+08
P168020116	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-08-11 13:44:13.97815+08
P167291284	3709	生活习惯-饮食	600660	39.您的饮食口味？	C.不好说	2016-08-19 01:00:03.897825+08
P167291284	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）	D.辛辣；E.热烫；	2016-08-19 01:00:03.900704+08
P167291284	3709	生活习惯-饮食	600662	41.您的主食结构如何？	B.粗细搭配	2016-08-19 01:00:03.903622+08
P15C280643	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？	A.＜100g（少于2两）	2016-08-19 01:00:03.271728+08
P15C280643	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-08-19 01:00:03.274578+08
P15C280643	3709	生活习惯-饮食	600669	48.您吃肥肉吗？	A.不吃	2016-08-19 01:00:03.277321+08
P15C280643	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-19 01:00:03.280121+08
P15C280643	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-08-19 01:00:03.282847+08
P15C280643	3709	生活习惯-饮食	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-19 01:00:03.285669+08
P15C280643	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-08-19 01:00:03.288454+08
P15C280643	3710	生活习惯-吸烟	600674	53.您吸烟吗？	A.不吸	2016-08-19 01:00:03.291394+08
P15C280643	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-08-19 01:00:03.294155+08
P15C280643	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	A.不参加	2016-08-19 01:00:03.296872+08
P15C280643	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-19 01:00:03.299758+08
P15C280643	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？	B.3～5天	2016-08-19 01:00:03.30264+08
P15C280643	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-08-19 01:00:03.30546+08
P167230072	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）	A.熏制、腌制类；C.甜点；D.辛辣；	2016-08-11 13:44:13.163057+08
P167270185	3702	健康史-家族史	600608	1-2.请确定所患的恶性肿瘤名称：（可多选）		2016-08-19 01:00:03.444879+08
P167270185	3703	健康史-现病史	600611	2-1.请您确认具体疾病或异常的名称：（可多选）	A.高血压	2016-08-19 01:00:03.454946+08
P167270185	3703	健康史-现病史	600612	2-2.请选择恶性肿瘤的名称？（可多选）		2016-08-19 01:00:03.457947+08
P167270185	3703	健康史-现病史	600613	2-3.请填写您被诊断患有上述疾病或异常的年龄		2016-08-19 01:00:03.460951+08
P167270185	3710	生活习惯-吸烟	600675	53-1.您通常每天吸多少支烟？（含戒烟前）		2016-08-19 01:00:03.537941+08
P167270185	3710	生活习惯-吸烟	600676	53-2.您持续吸烟的年限？（含戒烟前）		2016-08-19 01:00:03.540912+08
P167270185	3710	生活习惯-吸烟	600677	53-3.您戒烟多长时间了？		2016-08-19 01:00:03.543855+08
P167270185	3711	生活习惯-饮酒	600683	54-5.您戒酒多长时间了？		2016-08-19 01:00:03.563941+08
P167291284	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-08-19 01:00:03.865844+08
P167291284	3702	健康史-家族史	600608	1-2.请确定所患的恶性肿瘤名称：（可多选）	祖母：G.脑瘤；	2016-08-19 01:00:03.871725+08
P167291284	3702	健康史-家族史	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-19 01:00:03.874713+08
P167291284	3703	健康史-现病史	600610	2.您目前是否患有明确诊断的疾病或异常？	是	2016-08-19 01:00:03.877658+08
P167291284	3709	生活习惯-饮食	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-19 01:00:03.886025+08
P167291284	3709	生活习惯-饮食	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-08-19 01:00:03.888742+08
P167291284	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-19 01:00:03.891598+08
P167291284	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-19 01:00:03.894493+08
P167291284	3709	生活习惯-饮食	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-19 01:00:03.906562+08
P167291284	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-19 01:00:03.909451+08
P167291284	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？	C.经常吃	2016-08-19 01:00:03.912425+08
P167291284	3709	生活习惯-饮食	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-08-19 01:00:03.915251+08
P167291284	3709	生活习惯-饮食	600667	46.您平均每天吃多少蔬菜？	C.200～500g（4两～1斤）	2016-08-19 01:00:03.918076+08
P167291284	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-08-19 01:00:03.920971+08
P167291284	3709	生活习惯-饮食	600669	48.您吃肥肉吗？	B.偶尔吃	2016-08-19 01:00:03.923788+08
P167291284	3709	生活习惯-饮食	600670	49.您吃动物内脏吗？	C.经常吃	2016-08-19 01:00:03.926661+08
P167291284	3709	生活习惯-饮食	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-08-19 01:00:03.929667+08
P164190212	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-09-10 01:00:07.789132+08
P15C280643	3709	生活习惯-饮食	600660	39.您的饮食口味？	A.清淡	2016-08-19 01:00:03.252303+08
P15C280643	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）	B.高油脂、油炸食品；C.甜点；F.吃零食（适量坚果除外）；	2016-08-19 01:00:03.255091+08
P15C280643	3709	生活习惯-饮食	600662	41.您的主食结构如何？	A.细粮为主	2016-08-19 01:00:03.257814+08
P15C280643	3709	生活习惯-饮食	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-19 01:00:03.260581+08
P15C280643	3709	生活习惯-饮食	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-19 01:00:03.263361+08
P15C280643	3709	生活习惯-饮食	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-19 01:00:03.266153+08
P15C280643	3709	生活习惯-饮食	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-08-19 01:00:03.268928+08
P167291284	3705	健康史-用药史	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-19 01:00:03.883163+08
P167291284	3703	健康史-现病史	600611	2-1.请您确认具体疾病或异常的名称：（可多选）	P.慢性肝炎或肝硬化|2013年患病；	2016-08-19 01:00:03.880342+08
P167291284	3711	生活习惯-饮酒	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-19 01:00:03.94236+08
P167291284	3711	生活习惯-饮酒	600679	54-1.您一般喝什么酒？（可多选）	B.啤酒；C.红酒；	2016-08-19 01:00:03.945163+08
P167291284	3711	生活习惯-饮酒	600680	54-2.您每周喝几次酒？（含戒酒前）	A.1～2次	2016-08-19 01:00:03.948004+08
P167291284	3712	生活习惯-运动锻炼	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-19 01:00:03.970768+08
P167291284	3712	生活习惯-运动锻炼	600690	56-1.您每周工作几天？	C.＞5天	2016-08-19 01:00:03.973609+08
P167291284	3712	生活习惯-运动锻炼	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-08-19 01:00:03.976486+08
P168020113	3709	生活习惯-饮食	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-11 13:44:13.722563+08
P168020117	3703	健康史-现病史	600611	2-1.请您确认具体疾病或异常的名称：（可多选）	A.高血压|2002年患病；E.脂肪肝|2015年患病；O.骨质疏松|2011年患病；	2016-08-11 13:44:13.683243+08
P168160788	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-08-26 12:42:39.99959+08
P168160788	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-26 12:42:40.002632+08
P168160788	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-26 12:42:40.005584+08
P168160788	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-26 12:42:40.008446+08
P168160788	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-26 12:42:40.011854+08
P168160788	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-08-26 12:42:40.014761+08
P168160788	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-26 12:42:40.01762+08
P168160788	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	B.比较多（每周2-3次）	2016-08-26 12:42:40.020449+08
P168160788	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	B.偏咸	2016-08-26 12:42:40.023268+08
P168160788	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	A.熏制、腌制类；D.辛辣；	2016-08-26 12:42:40.026157+08
P168160788	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	D.不好说	2016-08-26 12:42:40.02906+08
P168160788	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-26 12:42:40.031951+08
P168160788	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-26 12:42:40.034814+08
P168160788	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-26 12:42:40.037645+08
P168160788	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-08-26 12:42:40.040491+08
P168160788	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	A.＜100g（少于2两）	2016-08-26 12:42:40.043428+08
P168160788	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-08-26 12:42:40.04636+08
P168160788	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	C.经常吃	2016-08-26 12:42:40.049159+08
P168160788	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-26 12:42:40.052053+08
P164190212	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	B.基本能（每周有2-3次不能按时就餐）	2016-09-10 01:00:07.792246+08
P167291284	3710	生活习惯-吸烟	600674	53.您吸烟吗？	A.不吸	2016-08-19 01:00:03.939398+08
P167291284	3711	生活习惯-饮酒	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	A.1～2两	2016-08-19 01:00:03.950841+08
P167291284	3711	生活习惯-饮酒	600682	54-4.您持续喝酒的年限？（含戒酒前）	A.＜5年	2016-08-19 01:00:03.953725+08
P167291284	3712	生活习惯-运动锻炼	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-19 01:00:03.95662+08
P167291284	3712	生活习惯-运动锻炼	600685	55-1.您常采用的锻炼方式：（可多选）	M.其他	2016-08-19 01:00:03.959466+08
P167291284	3712	生活习惯-运动锻炼	600686	55-2.您每周锻炼几次？	A.1～2次	2016-08-19 01:00:03.96225+08
P167291284	3712	生活习惯-运动锻炼	600687	55-3.您每次锻炼多长时间？	A.＜30分钟	2016-08-19 01:00:03.964975+08
P167291284	3712	生活习惯-运动锻炼	600688	55-4.您坚持锻炼多少年了？	A.＜1年	2016-08-19 01:00:03.967993+08
P167280908	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-09-25 01:00:08.466401+08
P167280908	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-09-25 01:00:08.469304+08
P167280908	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-09-25 01:00:08.472168+08
P167280908	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	B.偶尔吃	2016-09-25 01:00:08.475121+08
P167280908	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	A.不吃	2016-09-25 01:00:08.478075+08
P167280908	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-09-25 01:00:08.480991+08
P167280908	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-09-25 01:00:08.48388+08
P167280908	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-09-25 01:00:08.486818+08
P167280908	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	A.不吸	2016-09-25 01:00:08.48969+08
P167280908	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-09-25 01:00:08.492902+08
P167280908	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-09-25 01:00:08.495991+08
P167280908	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步；D.骑自行车；	2016-09-25 01:00:08.498996+08
P167280908	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	A.1～2次	2016-09-25 01:00:08.502+08
P164190212	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	B.偏咸	2016-09-10 01:00:07.804719+08
P164190212	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	A.熏制、腌制类；D.辛辣；E.热烫；	2016-09-10 01:00:07.807859+08
P164190212	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	B.粗细搭配	2016-09-10 01:00:07.810934+08
P164190212	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-09-10 01:00:07.814062+08
P164190212	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-09-10 01:00:07.882124+08
P164190212	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-09-10 01:00:07.885213+08
P167280908	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-09-25 01:00:08.428517+08
P167280908	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-09-25 01:00:08.431489+08
P167280908	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-09-25 01:00:08.434414+08
P167280908	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-09-25 01:00:08.437345+08
P167280908	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-09-25 01:00:08.440228+08
P167280908	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-09-25 01:00:08.443142+08
P167280908	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	B.比较多（每周2-3次）	2016-09-25 01:00:08.446166+08
P167280908	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	A.清淡	2016-09-25 01:00:08.449108+08
P167280908	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	H.无以上嗜好	2016-09-25 01:00:08.451865+08
P167280908	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	A.细粮为主	2016-09-25 01:00:08.454777+08
P167280908	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-09-25 01:00:08.457615+08
P167280908	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-09-25 01:00:08.460516+08
P167280908	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	C.经常吃	2016-09-25 01:00:08.463469+08
P167270185	3711	生活习惯-饮酒	600682	54-4.您持续喝酒的年限？（含戒酒前）	C.10～20年	2016-08-11 13:44:13.569008+08
P167291284	3709	生活习惯-饮食	600673	52.您喝含糖饮料（果汁、可乐等）吗？	C.经常喝（每周3-5次）	2016-08-19 01:00:03.935873+08
P167291284	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	B.2～4小时	2016-08-19 01:00:03.979302+08
P168160792	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-08-26 12:42:40.156449+08
P168160792	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-26 12:42:40.159357+08
P164190212	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-09-10 01:00:07.786104+08
P167280908	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	A.＜30分钟	2016-09-25 01:00:08.505045+08
P167280908	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-09-25 01:00:08.50807+08
P167280908	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-09-25 01:00:08.511226+08
P167280908	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	B.3～5天	2016-09-25 01:00:08.514405+08
P167280908	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-09-25 01:00:08.517452+08
P169300306	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-10-11 17:01:38.826876+08
P169300306	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-10-11 17:01:38.830069+08
P169300306	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-10-11 17:01:38.833238+08
P169300306	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-10-11 17:01:38.836416+08
P169300306	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	B.基本能（每周有2-3次不能按时就餐）	2016-10-11 17:01:38.839611+08
P169300306	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-10-11 17:01:38.842794+08
P169300306	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-10-11 17:01:38.845971+08
P169300306	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-10-11 17:01:38.849055+08
P169300306	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	A.清淡	2016-10-11 17:01:38.852247+08
P169300306	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	A.熏制、腌制类；C.甜点；D.辛辣；	2016-10-11 17:01:38.855416+08
P169300306	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	B.粗细搭配	2016-10-11 17:01:38.85862+08
P169300306	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-10-11 17:01:38.861728+08
P169300306	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-10-11 17:01:38.86513+08
P169300306	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-10-11 17:01:38.868378+08
P169300306	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-10-11 17:01:38.871637+08
P169300306	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-10-11 17:01:38.874968+08
P169300306	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-10-11 17:01:38.878135+08
P169300306	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	B.偶尔吃	2016-10-11 17:01:38.881422+08
P169300306	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	C.经常吃	2016-10-11 17:01:38.884688+08
P169300306	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-10-11 17:01:38.887942+08
P167230072	3702	健康史-家族史	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	A.是	2016-08-11 13:44:13.104177+08
P167230072	3702	健康史-家族史	600607	1-1.请选择疾病的名称：（可多选）	父亲：C.冠心病； 母亲：A.高血压；E.糖尿病	2016-08-11 13:44:13.11026+08
P168310039	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-09-04 01:00:07.192608+08
P168170068	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	C.＞60分钟	2016-08-26 12:42:40.257928+08
P168170068	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	A.＜4小时	2016-08-26 12:42:40.269554+08
P168170329	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-08-26 12:42:40.275376+08
P168170329	3702	健康史-家族史                                                                                             	600607	1-1.请选择疾病的名称：（可多选）		2016-08-26 12:42:40.278141+08
P168170329	3702	健康史-家族史                                                                                             	600608	1-2.请确定所患的恶性肿瘤名称：（可多选）		2016-08-26 12:42:40.281031+08
P168170329	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-26 12:42:40.283873+08
P168170329	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	是	2016-08-26 12:42:40.286798+08
P168170329	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	B.偏咸	2016-08-26 12:42:40.316148+08
P168310035	3711	生活习惯-饮酒                                                                                             	600682	54-4.您持续喝酒的年限？（含戒酒前）	B.5～10年	2016-09-04 01:00:07.103596+08
P168310035	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-09-04 01:00:07.106696+08
P168310035	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	K.登山	2016-09-04 01:00:07.109886+08
P168310035	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	A.1～2次	2016-09-04 01:00:07.1136+08
P168310035	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-09-04 01:00:07.116751+08
P168310035	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	D.＞10年	2016-09-04 01:00:07.119843+08
P168310035	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	E.不工作	2016-09-04 01:00:07.123054+08
P168310039	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-09-04 01:00:07.129415+08
P168310039	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-09-04 01:00:07.139049+08
P168310039	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	C.不能（每周超过3次不能按时就餐）	2016-09-04 01:00:07.141995+08
P168310039	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-09-04 01:00:07.145065+08
P168310039	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-09-04 01:00:07.151282+08
P168310039	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	B.偏咸	2016-09-04 01:00:07.154429+08
P168310039	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	B.粗细搭配	2016-09-04 01:00:07.160688+08
P168310039	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-09-04 01:00:07.163969+08
P168310039	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	C.经常吃（每周3-5次）	2016-09-04 01:00:07.167437+08
P168310039	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	C.经常吃	2016-09-04 01:00:07.1705+08
P168310039	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-09-04 01:00:07.173676+08
P168310039	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-09-04 01:00:07.176739+08
P168310039	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-09-04 01:00:07.179879+08
P168310039	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	C.经常吃	2016-09-04 01:00:07.183088+08
P168310039	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	A.不吃	2016-09-04 01:00:07.18617+08
P168310039	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-09-04 01:00:07.189411+08
P164190212	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步	2016-09-10 01:00:07.86388+08
P168170329	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	A.不吸	2016-08-26 12:42:40.357152+08
P168310039	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-09-04 01:00:07.195737+08
P168310039	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	B.天天吸	2016-09-04 01:00:07.198816+08
P168310039	3710	生活习惯-吸烟                                                                                             	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	B.10-20支	2016-09-04 01:00:07.201918+08
P168310039	3710	生活习惯-吸烟                                                                                             	600676	53-2.您持续吸烟的年限？（含戒烟前）	D.＞20年	2016-09-04 01:00:07.205175+08
P168310039	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-09-04 01:00:07.208342+08
P168310039	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-09-04 01:00:07.211499+08
P168310039	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	B.3～5次	2016-09-04 01:00:07.217756+08
P168310039	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	C.＞60分钟	2016-09-04 01:00:07.22084+08
P168310039	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-09-04 01:00:07.224149+08
P168310039	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-09-04 01:00:07.22722+08
P168310039	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	A.＜3天	2016-09-04 01:00:07.230445+08
P168310039	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	B.4～6小时	2016-09-04 01:00:07.233757+08
P168310039	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-09-04 01:00:07.236883+08
P164190212	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-09-10 01:00:07.795376+08
P164190212	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-09-10 01:00:07.798467+08
P164190212	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-09-10 01:00:07.817084+08
P164190212	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-09-10 01:00:07.820232+08
P164190212	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	D.每天都吃（每周6次以上）	2016-09-10 01:00:07.823319+08
P164190212	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-09-10 01:00:07.826469+08
P164190212	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	C.100～250g（2～5两）	2016-09-10 01:00:07.82957+08
P164190212	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	A.不吃	2016-09-10 01:00:07.832641+08
P164190212	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-09-10 01:00:07.83569+08
P164190212	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-09-10 01:00:07.838781+08
P164190212	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-09-10 01:00:07.842005+08
P164190212	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-09-10 01:00:07.845389+08
P164190212	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	B.天天吸	2016-09-10 01:00:07.848457+08
P164190212	3710	生活习惯-吸烟                                                                                             	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	B.10-20支	2016-09-10 01:00:07.851576+08
P164190212	3710	生活习惯-吸烟                                                                                             	600676	53-2.您持续吸烟的年限？（含戒烟前）	D.＞20年	2016-09-10 01:00:07.854689+08
P164190212	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-09-10 01:00:07.857723+08
P164190212	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-09-10 01:00:07.860766+08
P169260012	3702	健康史-家族史                                                                                             	600607	1-1.请选择疾病的名称：（可多选）	母亲：M.恶性肿瘤；	2016-09-30 01:00:06.942369+08
P169260012	3702	健康史-家族史                                                                                             	600608	1-2.请确定所患的恶性肿瘤名称：（可多选）	母亲：E.结直肠癌；	2016-09-30 01:00:06.945546+08
P169260012	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-09-30 01:00:06.948749+08
P169260012	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	是	2016-09-30 01:00:06.951846+08
P169260012	3703	健康史-现病史                                                                                             	600611	2-1.请您确认具体疾病或异常的名称：（可多选）	A.高血压|2000年患病；C.冠心病|2010年患病；W.血脂异常|2012年患病；AA.其他|其他；	2016-09-30 01:00:06.95493+08
P169260012	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	A.是	2016-09-30 01:00:06.958068+08
P169260012	3705	健康史-用药史                                                                                             	600617	4-1.您长期用哪些药物？（可多选）	A.降压药	2016-09-30 01:00:06.96113+08
P169260012	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-09-30 01:00:06.964359+08
P169260012	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-09-30 01:00:06.967429+08
P169260012	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-09-30 01:00:06.970605+08
P169260012	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-09-30 01:00:06.973754+08
P169260012	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	B.偏咸	2016-09-30 01:00:06.976887+08
P167230072	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	A.＜50g（少于1两）	2016-08-11 13:44:13.203821+08
P169260012	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	B.高油脂、油炸食品；C.甜点；	2016-09-30 01:00:06.979976+08
P169260012	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-09-30 01:00:06.938467+08
P169260012	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	B.粗细搭配	2016-09-30 01:00:06.983046+08
P169260012	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	A.不喝（几乎从来不喝）	2016-09-30 01:00:06.98612+08
P167230072	3709	生活习惯-饮食	600662	41.您的主食结构如何？	A.细粮为主	2016-08-11 13:44:13.169567+08
P168160788	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-08-26 12:42:40.054889+08
P168160788	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-08-26 12:42:40.061406+08
P168170329	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	C.100～250g（2～5两）	2016-08-26 12:42:40.339757+08
P168170329	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-08-26 12:42:40.351384+08
P168170329	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-08-26 12:42:40.410626+08
P168190032	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-08-26 12:42:40.454654+08
P164190212	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	C.经常参加（每周4-5次）	2016-09-10 01:00:07.801481+08
P164190212	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	C.＞5次	2016-09-10 01:00:07.866912+08
P164190212	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-09-10 01:00:07.869999+08
P164190212	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	A.＜1年	2016-09-10 01:00:07.873058+08
P164190212	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-09-10 01:00:07.876067+08
P164190212	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	B.3～5天	2016-09-10 01:00:07.87909+08
P15C280643	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-19 01:00:03.249104+08
P15C280643	3712	生活习惯-运动锻炼	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	B.2～4小时	2016-08-19 01:00:03.308224+08
P168230028	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-27 01:00:05.96917+08
P168230028	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-08-27 01:00:05.972139+08
P168230028	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	C.经常吃	2016-08-27 01:00:05.995488+08
P168230028	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-08-27 01:00:05.998375+08
P168230028	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-08-27 01:00:06.001263+08
P168230028	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	C.100～250g（2～5两）	2016-08-27 01:00:06.004021+08
P168230028	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	A.不吃	2016-08-27 01:00:06.006861+08
P168230028	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-27 01:00:06.009752+08
P168230028	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	A.不吃	2016-08-27 01:00:06.012601+08
P168230028	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-27 01:00:06.015997+08
P168230028	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-08-27 01:00:06.018997+08
P168230028	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	A.不吸	2016-08-27 01:00:06.021863+08
P168230028	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-08-27 01:00:06.024747+08
P168230028	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-27 01:00:06.027627+08
P168230028	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步	2016-08-27 01:00:06.030538+08
P168230028	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	A.1～2次	2016-08-27 01:00:06.033445+08
P168230028	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-08-27 01:00:06.03635+08
P168230028	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	A.＜1年	2016-08-27 01:00:06.039408+08
P168170068	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	B.3～5次	2016-08-26 12:42:40.255109+08
P168170068	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	A.＜2小时	2016-08-26 12:42:40.272441+08
P168230028	3702	健康史-家族史                                                                                             	600608	1-2.请确定所患的恶性肿瘤名称：（可多选）	父亲：L.鼻咽癌；	2016-08-27 01:00:05.957655+08
P168230028	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-27 01:00:05.960556+08
P168230028	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-27 01:00:05.963443+08
P168230028	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-27 01:00:05.966322+08
P168230028	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-27 01:00:05.974976+08
P168230028	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-27 01:00:05.977821+08
P168230028	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	A.清淡	2016-08-27 01:00:05.98064+08
P168230028	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	H.无以上嗜好	2016-08-27 01:00:05.98348+08
P168230028	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	B.粗细搭配	2016-08-27 01:00:05.986327+08
P168230028	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	C.经常喝（每周3-5次）	2016-08-27 01:00:05.989777+08
P168230028	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-27 01:00:05.99264+08
P168230028	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	B.轻体力劳动	2016-08-27 01:00:06.042327+08
P168250037	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-29 01:00:06.470703+08
P168250037	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	G.喜食快餐	2016-08-29 01:00:06.491437+08
P168250037	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	D.不好说	2016-08-29 01:00:06.494396+08
P168250037	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-29 01:00:06.473732+08
P168250037	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	C.经常吃（每周3-5次）	2016-08-29 01:00:06.500384+08
P168250037	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-29 01:00:06.503388+08
P168250037	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-08-29 01:00:06.506389+08
P168250037	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	C.经常喝（每周3-5次）	2016-08-29 01:00:06.49736+08
P168250037	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	A.＜100g（少于2两）	2016-08-29 01:00:06.509353+08
P168250037	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	A.＜50g（少于1两）	2016-08-29 01:00:06.512354+08
P168250037	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	A.不吃	2016-08-29 01:00:06.515304+08
P168250037	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-29 01:00:06.518244+08
P168250037	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	A.不吃	2016-08-29 01:00:06.521083+08
P168250037	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-29 01:00:06.524039+08
P168250037	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-08-29 01:00:06.526884+08
P168250037	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	A.不吸	2016-08-29 01:00:06.530429+08
P168250037	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-08-29 01:00:06.533429+08
P168250037	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-29 01:00:06.536433+08
P168250037	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	B.慢跑或快步走	2016-08-29 01:00:06.539618+08
P168230028	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-08-27 01:00:05.95197+08
P168230028	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	C.＞5天	2016-08-27 01:00:06.045235+08
P168230028	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	B.2～4小时	2016-08-27 01:00:06.051242+08
P168250037	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-08-29 01:00:06.464101+08
P168250037	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-29 01:00:06.467074+08
P168250037	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	B.基本能（每周有2-3次不能按时就餐）	2016-08-29 01:00:06.476738+08
P168250037	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-08-29 01:00:06.47982+08
P168250037	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-29 01:00:06.482755+08
P168250037	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-29 01:00:06.485676+08
P168250037	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	A.清淡	2016-08-29 01:00:06.488486+08
P168250037	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	A.1～2次	2016-08-29 01:00:06.54261+08
P168190032	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	C.经常吃	2016-08-26 12:42:40.451564+08
P168170329	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-08-26 12:42:40.354335+08
P168290025	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-09-02 01:00:05.611475+08
P168290025	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-09-02 01:00:05.619914+08
P168290025	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	B.基本能（每周有2-3次不能按时就餐）	2016-09-02 01:00:05.622683+08
P168290025	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	C.经常吃（每周吃夜宵超过1次）	2016-09-02 01:00:05.625744+08
P168290025	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-09-02 01:00:05.628561+08
P168290025	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-09-02 01:00:05.631448+08
P168290025	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	B.偏咸	2016-09-02 01:00:05.634211+08
P168290025	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	A.熏制、腌制类；B.高油脂、油炸食品；D.辛辣；E.热烫；	2016-09-02 01:00:05.636909+08
P168290025	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	A.细粮为主	2016-09-02 01:00:05.639726+08
P168290025	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	A.不喝（几乎从来不喝）	2016-09-02 01:00:05.642487+08
P168290025	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	C.经常吃（每周3-5次）	2016-09-02 01:00:05.645259+08
P168290025	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-09-02 01:00:05.64794+08
P168290025	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-09-02 01:00:05.650766+08
P168290025	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	A.＜100g（少于2两）	2016-09-02 01:00:05.653572+08
P168290025	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	C.100～250g（2～5两）	2016-09-02 01:00:05.656331+08
P168290025	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	C.经常吃	2016-09-02 01:00:05.659439+08
P168290025	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	C.经常吃	2016-09-02 01:00:05.662208+08
P168290025	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-09-02 01:00:05.664921+08
P168290025	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-09-02 01:00:05.667672+08
P168290025	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-09-02 01:00:05.670374+08
P168290025	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	C.吸烟，已戒	2016-09-02 01:00:05.673227+08
P168290025	3710	生活习惯-吸烟                                                                                             	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	A.＜10支	2016-09-02 01:00:05.67594+08
P168290025	3710	生活习惯-吸烟                                                                                             	600676	53-2.您持续吸烟的年限？（含戒烟前）	C.10～20年	2016-09-02 01:00:05.678733+08
P168230028	3702	健康史-家族史                                                                                             	600607	1-1.请选择疾病的名称：（可多选）	父亲：M.恶性肿瘤；	2016-08-27 01:00:05.954849+08
P168250037	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-08-29 01:00:06.550139+08
P168250037	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-29 01:00:06.553248+08
P168250037	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	B.3～5天	2016-08-29 01:00:06.556177+08
P168250037	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	B.4～6小时	2016-08-29 01:00:06.559147+08
P168250037	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-08-29 01:00:06.562125+08
P168290025	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-09-02 01:00:05.614359+08
P168290025	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-09-02 01:00:05.617169+08
P168290025	3710	生活习惯-吸烟                                                                                             	600677	53-3.您戒烟多长时间了？	A.＜1年	2016-09-02 01:00:05.681578+08
P168290068	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-09-03 01:00:06.581156+08
P168290068	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-09-03 01:00:06.584119+08
P168290068	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-09-03 01:00:06.586994+08
P168290068	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	A.＜50g（少于1两）	2016-09-03 01:00:06.590443+08
P168290068	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	B.偶尔吃	2016-09-03 01:00:06.593503+08
P168290068	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	A.不吃	2016-09-03 01:00:06.596475+08
P168290068	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-09-03 01:00:06.599467+08
P168290068	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-09-03 01:00:06.605346+08
P168230028	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	B.4～6小时	2016-08-27 01:00:06.048366+08
P168250037	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-08-29 01:00:06.546107+08
P168290025	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-09-02 01:00:05.684372+08
P168290025	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-09-02 01:00:05.69071+08
P168290025	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	A.＜3天	2016-09-02 01:00:05.693424+08
P168290068	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	C.甜点；G.喜食快餐；	2016-09-03 01:00:06.569433+08
P168290068	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	A.不吸	2016-09-03 01:00:06.60832+08
P167270184	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-09-14 01:00:07.8076+08
P167270184	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-09-14 01:00:07.8106+08
P168290025	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	A.不参加	2016-09-02 01:00:05.687786+08
P168290025	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	A.＜4小时	2016-09-02 01:00:05.696299+08
P168290025	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	D.＞6小时	2016-09-02 01:00:05.699169+08
P168290068	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	A.细粮为主	2016-09-03 01:00:06.572383+08
P168290068	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-09-03 01:00:06.575325+08
P168290068	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-09-03 01:00:06.578268+08
P168290068	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-09-03 01:00:06.602395+08
P168290068	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-09-03 01:00:06.19009+08
P168290068	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	A.清淡	2016-09-03 01:00:06.195999+08
P168290068	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-09-03 01:00:06.611302+08
P168290068	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-09-03 01:00:06.614335+08
P168310039	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步；B.慢跑或快步走；K.登山；	2016-09-04 01:00:07.214578+08
P167270184	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-09-14 01:00:07.798449+08
P167270184	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-09-14 01:00:07.80151+08
P167270184	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-09-14 01:00:07.804566+08
P168160788	3711	生活习惯-饮酒                                                                                             	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	B.3～4两	2016-08-26 12:42:40.081255+08
P168160788	3711	生活习惯-饮酒                                                                                             	600682	54-4.您持续喝酒的年限？（含戒酒前）	C.10～20年	2016-08-26 12:42:40.083949+08
P168160788	3710	生活习惯-吸烟                                                                                             	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	D.＞30支	2016-08-26 12:42:40.066956+08
P168160788	3710	生活习惯-吸烟                                                                                             	600676	53-2.您持续吸烟的年限？（含戒烟前）	C.10～20年	2016-08-26 12:42:40.069793+08
P168160788	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-26 12:42:40.07268+08
P168160788	3711	生活习惯-饮酒                                                                                             	600679	54-1.您一般喝什么酒？（可多选）	A.白酒	2016-08-26 12:42:40.075486+08
P168160788	3711	生活习惯-饮酒                                                                                             	600680	54-2.您每周喝几次酒？（含戒酒前）	C.＞5次	2016-08-26 12:42:40.07838+08
P168160788	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	A.不参加	2016-08-26 12:42:40.086791+08
P168160788	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-26 12:42:40.089654+08
P168160788	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	B.3～5天	2016-08-26 12:42:40.092541+08
P168160788	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	B.4～6小时	2016-08-26 12:42:40.095782+08
P168160788	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	D.＞6小时	2016-08-26 12:42:40.098656+08
P168160792	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-08-26 12:42:40.102057+08
P168160792	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-26 12:42:40.10501+08
P168160792	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-26 12:42:40.107882+08
P168160792	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-26 12:42:40.110744+08
P168160792	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-26 12:42:40.113625+08
P168160792	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-08-26 12:42:40.116432+08
P168160792	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-26 12:42:40.119317+08
P168160792	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-26 12:42:40.122131+08
P168160792	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	B.偏咸	2016-08-26 12:42:40.125034+08
P168160792	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	A.熏制、腌制类；D.辛辣；	2016-08-26 12:42:40.127786+08
P168160792	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	C.粗粮为主	2016-08-26 12:42:40.130646+08
P168290068	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	A.1～2次	2016-09-03 01:00:06.621815+08
P168290068	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-09-03 01:00:06.624781+08
P168290068	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-09-03 01:00:06.627765+08
P168290068	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-09-03 01:00:06.630705+08
P168290068	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	C.＞5天	2016-09-03 01:00:06.633631+08
P167270184	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-09-14 01:00:07.813602+08
P168160788	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	B.天天吸	2016-08-26 12:42:40.064116+08
P168290068	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	D.＞8小时	2016-09-03 01:00:06.636619+08
P168160792	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-26 12:42:40.153502+08
P168160792	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-08-26 12:42:40.162227+08
P168160792	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	D.经常被动吸烟	2016-08-26 12:42:40.165112+08
P168160792	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-08-26 12:42:40.168051+08
P168160792	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	A.不参加	2016-08-26 12:42:40.170943+08
P168160792	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	E.不工作	2016-08-26 12:42:40.174049+08
P168160792	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-08-26 12:42:40.177065+08
P168170068	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-08-26 12:42:40.179915+08
P168170068	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-26 12:42:40.182771+08
P168170068	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-26 12:42:40.185575+08
P168170068	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-26 12:42:40.188439+08
P168170068	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-26 12:42:40.191263+08
P168170068	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-08-26 12:42:40.193963+08
P168170068	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-26 12:42:40.196837+08
P168170068	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-26 12:42:40.199722+08
P168170068	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	A.清淡	2016-08-26 12:42:40.202633+08
P168170068	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	H.无以上嗜好	2016-08-26 12:42:40.205517+08
P168170068	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	C.粗粮为主	2016-08-26 12:42:40.208369+08
P168170068	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	A.不喝（几乎从来不喝）	2016-08-26 12:42:40.21111+08
P168170068	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-26 12:42:40.213946+08
P168170068	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-26 12:42:40.216811+08
P168170068	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	A.不吃（几乎从来不吃）	2016-08-26 12:42:40.219685+08
P168170068	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-08-26 12:42:40.222552+08
P168170068	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	B.偶尔吃	2016-08-26 12:42:40.228715+08
P167270184	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-09-14 01:00:07.816684+08
P167270184	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-09-14 01:00:07.820107+08
P168160792	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	C.经常吃	2016-08-26 12:42:40.139161+08
P168160792	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-08-26 12:42:40.142067+08
P168160792	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	A.＜50g（少于1两）	2016-08-26 12:42:40.147797+08
P168160792	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	B.偶尔吃	2016-08-26 12:42:40.150651+08
P168170068	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-26 12:42:40.231723+08
P168170068	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-08-26 12:42:40.23462+08
P168170068	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-08-26 12:42:40.260808+08
P168170068	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	B.轻体力劳动	2016-08-26 12:42:40.263743+08
P168170068	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	A.＜3天	2016-08-26 12:42:40.266654+08
P168170329	3703	健康史-现病史                                                                                             	600611	2-1.请您确认具体疾病或异常的名称：（可多选）	A.高血压|1997年患病；	2016-08-26 12:42:40.289703+08
P168170329	3703	健康史-现病史                                                                                             	600612	2-2.请选择恶性肿瘤的名称？（可多选）		2016-08-26 12:42:40.292615+08
P168170329	3703	健康史-现病史                                                                                             	600613	2-3.请填写您被诊断患有上述疾病或异常的年龄		2016-08-26 12:42:40.295477+08
P168170329	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	A.是	2016-08-26 12:42:40.298649+08
P168170329	3705	健康史-用药史                                                                                             	600617	4-1.您长期用哪些药物？（可多选）	A.降压药；C.降脂药；	2016-08-26 12:42:40.301544+08
P168170329	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-26 12:42:40.304443+08
P168170329	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-08-26 12:42:40.307395+08
P168170329	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-08-26 12:42:40.310374+08
P168170329	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-26 12:42:40.313261+08
P168170329	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	A.熏制、腌制类；D.辛辣；	2016-08-26 12:42:40.319041+08
P168170329	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	A.细粮为主	2016-08-26 12:42:40.322336+08
P168170329	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-26 12:42:40.325349+08
P168170329	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-26 12:42:40.328221+08
P168170329	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-08-26 12:42:40.3311+08
P168170329	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-08-26 12:42:40.333962+08
P168170329	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-08-26 12:42:40.336784+08
P168170329	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	A.不吃	2016-08-26 12:42:40.342762+08
P168170329	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-26 12:42:40.345633+08
P168170329	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	B.偶尔吃	2016-08-26 12:42:40.348489+08
P168170329	3710	生活习惯-吸烟                                                                                             	600675	53-1.您通常每天吸多少支烟？（含戒烟前）		2016-08-26 12:42:40.360086+08
P168170329	3710	生活习惯-吸烟                                                                                             	600676	53-2.您持续吸烟的年限？（含戒烟前）		2016-08-26 12:42:40.363036+08
P168170329	3710	生活习惯-吸烟                                                                                             	600677	53-3.您戒烟多长时间了？		2016-08-26 12:42:40.365968+08
P168170329	3711	生活习惯-饮酒                                                                                             	600679	54-1.您一般喝什么酒？（可多选）	A.白酒；B.啤酒；C.红酒；	2016-08-26 12:42:40.371802+08
P168170329	3711	生活习惯-饮酒                                                                                             	600680	54-2.您每周喝几次酒？（含戒酒前）	A.1～2次	2016-08-26 12:42:40.374722+08
P167270184	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	A.清淡	2016-09-14 01:00:07.823174+08
P168170068	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	A.不吸	2016-08-26 12:42:40.24325+08
P168170068	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-08-26 12:42:40.246093+08
P168170068	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-26 12:42:40.249169+08
P168170068	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步	2016-08-26 12:42:40.252069+08
P168170329	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-26 12:42:40.368871+08
P168170329	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-08-26 12:42:40.395346+08
P168170329	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-08-26 12:42:40.398648+08
P168170329	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-26 12:42:40.401706+08
P168170329	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	B.3～5天	2016-08-26 12:42:40.404679+08
P168170329	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-08-26 12:42:40.407654+08
P168190032	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-08-26 12:42:40.413607+08
P168190032	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-08-26 12:42:40.416502+08
P168190032	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-08-26 12:42:40.419451+08
P168190032	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-08-26 12:42:40.422411+08
P168190032	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-08-26 12:42:40.425381+08
P168190032	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	B.偶尔吃（每周吃夜宵不超过1次）	2016-08-26 12:42:40.428343+08
P168190032	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	A.是	2016-08-26 12:42:40.431161+08
P168190032	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	B.比较多（每周2-3次）	2016-08-26 12:42:40.434023+08
P168190032	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	C.不好说	2016-08-26 12:42:40.436937+08
P168190032	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	E.热烫	2016-08-26 12:42:40.43992+08
P168190032	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	A.细粮为主	2016-08-26 12:42:40.44281+08
P168190032	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-08-26 12:42:40.445633+08
P168190032	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	C.经常吃（每周3-5次）	2016-08-26 12:42:40.448605+08
P168190032	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-08-26 12:42:40.457613+08
P168190032	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	C.100～250g（2～5两）	2016-08-26 12:42:40.460495+08
P168190032	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	B.偶尔吃	2016-08-26 12:42:40.463455+08
P168190032	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-08-26 12:42:40.466398+08
P168190032	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-08-26 12:42:40.469352+08
P168190032	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-26 12:42:40.472707+08
P168190032	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-08-26 12:42:40.475719+08
P168190032	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-08-26 12:42:40.481834+08
P168190032	3711	生活习惯-饮酒                                                                                             	600679	54-1.您一般喝什么酒？（可多选）	A.白酒	2016-08-26 12:42:40.484781+08
P167270184	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	H.无以上嗜好	2016-09-14 01:00:07.826105+08
P168170329	3711	生活习惯-饮酒                                                                                             	600683	54-5.您戒酒多长时间了？		2016-08-26 12:42:40.383561+08
P168170329	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-26 12:42:40.386476+08
P168170329	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	B.慢跑或快步走	2016-08-26 12:42:40.389406+08
P168170329	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	B.3～5次	2016-08-26 12:42:40.392389+08
P168190032	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	D.经常被动吸烟	2016-08-26 12:42:40.478825+08
P168190032	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-08-26 12:42:40.511893+08
P168190032	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	C.＞5天	2016-08-26 12:42:40.514947+08
P168190032	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	D.＞8小时	2016-08-26 12:42:40.517922+08
P168190032	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	B.2～4小时	2016-08-26 12:42:40.520912+08
P168290068	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-09-03 01:00:06.169594+08
P168290068	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	是	2016-09-03 01:00:06.172706+08
P168290068	3703	健康史-现病史                                                                                             	600611	2-1.请您确认具体疾病或异常的名称：（可多选）	E.脂肪肝|2008年患病；P.慢性肝炎或肝硬化|1989年患病；	2016-09-03 01:00:06.176302+08
P168290068	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-09-03 01:00:06.180025+08
P168290068	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-09-03 01:00:06.183711+08
P168290068	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-09-03 01:00:06.1871+08
P168290068	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	B.比较多（每周2-3次）	2016-09-03 01:00:06.193035+08
P168200029	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-09-04 01:00:06.791944+08
P168200029	3702	健康史-家族史                                                                                             	600607	1-1.请选择疾病的名称：（可多选）	母亲：A.高血压|45-65岁之间患病；C.冠心病|45-65岁之间患病；	2016-09-04 01:00:06.796014+08
P168200029	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-09-04 01:00:06.799215+08
P168200029	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-09-04 01:00:06.802042+08
P168200029	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-09-04 01:00:06.80509+08
P168200029	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	A.能（几乎每天均可以按时就餐）	2016-09-04 01:00:06.808144+08
P168200029	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	A.不吃（每天均不吃夜宵）	2016-09-04 01:00:06.811179+08
P168200029	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-09-04 01:00:06.814394+08
P168200029	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	B.比较多（每周2-3次）	2016-09-04 01:00:06.817459+08
P168200029	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	A.清淡	2016-09-04 01:00:06.820582+08
P168200029	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	H.无以上嗜好	2016-09-04 01:00:06.823709+08
P168200029	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	B.粗细搭配	2016-09-04 01:00:06.826752+08
P167270184	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	A.细粮为主	2016-09-14 01:00:07.829021+08
P168190032	3711	生活习惯-饮酒                                                                                             	600682	54-4.您持续喝酒的年限？（含戒酒前）	C.10～20年	2016-08-26 12:42:40.493649+08
P168190032	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-08-26 12:42:40.496632+08
P168190032	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步；B.慢跑或快步走；	2016-08-26 12:42:40.499815+08
P168190032	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	B.3～5次	2016-08-26 12:42:40.502822+08
P168190032	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	C.＞60分钟	2016-08-26 12:42:40.5057+08
P168190032	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-08-26 12:42:40.508625+08
P168290068	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步；D.骑自行车；	2016-09-03 01:00:06.617317+08
P168200029	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	B.偶尔吃	2016-09-04 01:00:06.94255+08
P168200029	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-09-04 01:00:06.945702+08
P168200029	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	D.每天都吃	2016-09-04 01:00:06.948952+08
P168200029	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-09-04 01:00:06.952+08
P168200029	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-09-04 01:00:06.955172+08
P168200029	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	A.不吸	2016-09-04 01:00:06.958317+08
P168200029	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-09-04 01:00:06.961505+08
P168200029	3711	生活习惯-饮酒                                                                                             	600679	54-1.您一般喝什么酒？（可多选）	A.白酒	2016-09-04 01:00:06.964549+08
P168200029	3711	生活习惯-饮酒                                                                                             	600680	54-2.您每周喝几次酒？（含戒酒前）	B.3～5次	2016-09-04 01:00:06.968156+08
P168200029	3711	生活习惯-饮酒                                                                                             	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	B.3～4两	2016-09-04 01:00:06.971459+08
P168200029	3711	生活习惯-饮酒                                                                                             	600682	54-4.您持续喝酒的年限？（含戒酒前）	D.＞20年	2016-09-04 01:00:06.974664+08
P168200029	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-09-04 01:00:06.977846+08
P168200029	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步	2016-09-04 01:00:06.98095+08
P168200029	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	B.3～5次	2016-09-04 01:00:06.984162+08
P168200029	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-09-04 01:00:06.987268+08
P168200029	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-09-04 01:00:06.990419+08
P168200029	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	C.中度体力劳动	2016-09-04 01:00:06.993501+08
P168200029	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	B.3～5天	2016-09-04 01:00:06.996633+08
P168200029	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-09-04 01:00:06.999723+08
P168200029	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	A.＜2小时	2016-09-04 01:00:07.00284+08
P168310035	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	是	2016-09-04 01:00:07.005904+08
P168310035	3702	健康史-家族史                                                                                             	600607	1-1.请选择疾病的名称：（可多选）	母亲：M.恶性肿瘤；祖母：E.糖尿病；父亲：E.糖尿病；	2016-09-04 01:00:07.009459+08
P168310035	3702	健康史-家族史                                                                                             	600608	1-2.请确定所患的恶性肿瘤名称：（可多选）	母亲：G.脑瘤；	2016-09-04 01:00:07.01262+08
P168310035	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-09-04 01:00:07.015756+08
P168310035	3705	健康史-用药史                                                                                             	600616	4.您是否长期用某些药物？（可多选）	B.否	2016-09-04 01:00:07.021804+08
P167270184	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-09-14 01:00:07.831974+08
P168200029	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-09-04 01:00:06.926551+08
P168200029	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-09-04 01:00:06.929824+08
P168200029	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-09-04 01:00:06.933+08
P168200029	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	A.＜100g（少于2两）	2016-09-04 01:00:06.936126+08
P168200029	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	A.＜50g（少于1两）	2016-09-04 01:00:06.939395+08
P168310035	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-09-04 01:00:07.018768+08
P168310035	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-09-04 01:00:07.062622+08
P168310035	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	B.偶尔吃	2016-09-04 01:00:07.065717+08
P168310035	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	A.不吃	2016-09-04 01:00:07.068837+08
P168310035	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-09-04 01:00:07.071871+08
P168310035	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-09-04 01:00:07.075092+08
P168310035	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-09-04 01:00:07.078135+08
P168310035	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	B.天天吸	2016-09-04 01:00:07.081384+08
P168310035	3710	生活习惯-吸烟                                                                                             	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	B.10-20支	2016-09-04 01:00:07.084538+08
P168310035	3710	生活习惯-吸烟                                                                                             	600676	53-2.您持续吸烟的年限？（含戒烟前）	C.10～20年	2016-09-04 01:00:07.087816+08
P168310035	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-09-04 01:00:07.090934+08
P167270184	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-09-14 01:00:07.855996+08
P167270184	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-09-14 01:00:07.859023+08
P167270184	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-09-14 01:00:07.862005+08
P168310035	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-09-04 01:00:07.03148+08
P168310035	3709	生活习惯-饮食                                                                                             	600659	38.您参加请客吃饭（应酬）情况？	C.经常参加（每周4-5次）	2016-09-04 01:00:07.034664+08
P168310035	3709	生活习惯-饮食                                                                                             	600660	39.您的饮食口味？	B.偏咸	2016-09-04 01:00:07.037709+08
P168310035	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	B.高油脂、油炸食品；D.辛辣；G.喜食快餐；	2016-09-04 01:00:07.040782+08
P168310035	3709	生活习惯-饮食                                                                                             	600662	41.您的主食结构如何？	D.不好说	2016-09-04 01:00:07.043853+08
P168310035	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	A.不喝（几乎从来不喝）	2016-09-04 01:00:07.047036+08
P168310035	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	C.经常吃（每周3-5次）	2016-09-04 01:00:07.050076+08
P168310035	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	C.经常吃	2016-09-04 01:00:07.053268+08
P168310035	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-09-04 01:00:07.056493+08
P168310035	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-09-04 01:00:07.059458+08
P168310035	3711	生活习惯-饮酒                                                                                             	600679	54-1.您一般喝什么酒？（可多选）	C.红酒	2016-09-04 01:00:07.094063+08
P168310035	3711	生活习惯-饮酒                                                                                             	600680	54-2.您每周喝几次酒？（含戒酒前）	B.3～5次	2016-09-04 01:00:07.097257+08
P168310035	3711	生活习惯-饮酒                                                                                             	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	B.3～4两	2016-09-04 01:00:07.10046+08
P167270184	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-09-14 01:00:07.834966+08
P167270184	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-09-14 01:00:07.837966+08
P167270184	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	C.经常吃（每周3-5次）	2016-09-14 01:00:07.840944+08
P167270184	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	C.200～500g（4两～1斤）	2016-09-14 01:00:07.843906+08
P167270184	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-09-14 01:00:07.846937+08
P167270184	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	B.偶尔吃	2016-09-14 01:00:07.850044+08
P167270184	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	B.偶尔吃	2016-09-14 01:00:07.85304+08
P169260012	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	C.＞5天	2016-09-30 01:00:07.035131+08
P169260012	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	B.100～200g（2～4两）	2016-09-30 01:00:06.999373+08
P169260012	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	A.＜50g（少于1两）	2016-09-30 01:00:07.002643+08
P169260012	3709	生活习惯-饮食                                                                                             	600669	48.您吃肥肉吗？	A.不吃	2016-09-30 01:00:07.006248+08
P169260012	3709	生活习惯-饮食                                                                                             	600670	49.您吃动物内脏吗？	A.不吃	2016-09-30 01:00:07.009594+08
P169260012	3709	生活习惯-饮食                                                                                             	600671	50.您吃鱼肉或海鲜吗？	C.经常吃	2016-09-30 01:00:07.012785+08
P169260012	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-09-30 01:00:07.015927+08
P169260012	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-09-30 01:00:07.019222+08
P169260012	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	A.不吸	2016-09-30 01:00:07.022423+08
P169260012	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-09-30 01:00:07.025612+08
P169260012	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	A.不参加	2016-09-30 01:00:07.0288+08
P169260012	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	C.中度体力劳动	2016-09-30 01:00:07.031982+08
P169260012	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	B.4～6小时	2016-09-30 01:00:07.038424+08
P169260012	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	A.＜2小时	2016-09-30 01:00:07.041629+08
P168160788	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-26 12:42:40.058436+08
P168310039	3703	健康史-现病史                                                                                             	600610	2.您目前是否患有明确诊断的疾病或异常？	否	2016-09-04 01:00:07.135951+08
P168310039	3709	生活习惯-饮食                                                                                             	600658	37.您常暴饮暴食吗？（每周2次以上）	B.否	2016-09-04 01:00:07.14814+08
P167270184	3710	生活习惯-吸烟                                                                                             	600674	53.您吸烟吗？	A.不吸	2016-09-14 01:00:07.865007+08
P167270184	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	A.不喝	2016-09-14 01:00:07.867992+08
P167270184	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-09-14 01:00:07.870973+08
P167270184	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	A.散步；B.慢跑或快步走；	2016-09-14 01:00:07.873991+08
P167270184	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	C.＞5次	2016-09-14 01:00:07.877003+08
P167270184	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	C.＞60分钟	2016-09-14 01:00:07.880017+08
P167270184	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	B.1～5年	2016-09-14 01:00:07.882953+08
P167270184	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-09-14 01:00:07.886032+08
P167270184	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	C.＞5天	2016-09-14 01:00:07.889214+08
P167270184	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	C.6～8小时	2016-09-14 01:00:07.892386+08
P167270184	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	B.2～4小时	2016-09-14 01:00:07.895847+08
P169300306	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-10-11 17:01:38.891146+08
P169300306	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	B.偶尔喝（每周1-2次）	2016-10-11 17:01:38.894567+08
P169260012	3709	生活习惯-饮食                                                                                             	600665	44.您吃豆类及豆制品吗？	B.偶尔吃	2016-09-30 01:00:06.99276+08
P169260012	3709	生活习惯-饮食                                                                                             	600666	45.您吃水果吗？	B.偶尔吃（每周1-2次）	2016-09-30 01:00:06.996079+08
P168310035	3709	生活习惯-饮食                                                                                             	600657	36.您是否经常吃夜宵吗？	C.经常吃（每周吃夜宵超过1次）	2016-09-04 01:00:07.02809+08
P168310035	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-09-04 01:00:07.126243+08
P168310039	3702	健康史-家族史                                                                                             	600609	1-3.您的父亲有否在55岁、母亲在65岁之前患有上述疾病吗？	否	2016-09-04 01:00:07.132445+08
P168170068	3709	生活习惯-饮食                                                                                             	600672	51.您喝咖啡吗？	A.不喝（几乎从来不喝）	2016-08-26 12:42:40.237462+08
P168170068	3709	生活习惯-饮食                                                                                             	600673	52.您喝含糖饮料（果汁、可乐等）吗？	A.不喝（几乎从来不喝）	2016-08-26 12:42:40.240372+08
P168170329	3711	生活习惯-饮酒                                                                                             	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	A.1～2两	2016-08-26 12:42:40.377657+08
P168170329	3711	生活习惯-饮酒                                                                                             	600682	54-4.您持续喝酒的年限？（含戒酒前）	B.5～10年	2016-08-26 12:42:40.380625+08
P168190032	3711	生活习惯-饮酒                                                                                             	600680	54-2.您每周喝几次酒？（含戒酒前）	B.3～5次	2016-08-26 12:42:40.487744+08
P168190032	3711	生活习惯-饮酒                                                                                             	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	C.＞5两	2016-08-26 12:42:40.490707+08
P168290068	3702	健康史-家族史                                                                                             	600606	1.您的父母或兄弟姐妹是否患有明确诊断的疾病？	否	2016-09-03 01:00:06.165853+08
P168310039	3709	生活习惯-饮食                                                                                             	600661	40.您的饮食嗜好？（可多选）	B.高油脂、油炸食品；D.辛辣；F.吃零食（适量坚果除外）；	2016-09-04 01:00:07.157559+08
P169300306	3711	生活习惯-饮酒                                                                                             	600680	54-2.您每周喝几次酒？（含戒酒前）	A.1～2次	2016-10-11 17:01:36.073485+08
P169300306	3711	生活习惯-饮酒                                                                                             	600681	54-3.您每次喝几两？（1两相当于50ml白酒，100ml红酒，300ml啤酒）	B.3～4两	2016-10-11 17:01:36.07737+08
P169300306	3711	生活习惯-饮酒                                                                                             	600682	54-4.您持续喝酒的年限？（含戒酒前）	C.10～20年	2016-10-11 17:01:36.080792+08
P168290068	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	B.2～4小时	2016-09-03 01:00:06.639581+08
P168200029	3709	生活习惯-饮食                                                                                             	600663	42.您喝牛奶吗？	B.偶尔喝（每周1-2次）	2016-09-04 01:00:06.922751+08
P169300306	3712	生活习惯-运动锻炼                                                                                           	600684	55.您参加运动锻炼吗？ （平均每周锻炼1次以上）	B.参加	2016-10-11 17:01:36.084223+08
P168310035	3709	生活习惯-饮食                                                                                             	600656	35.您通常能够按时吃三餐吗？	C.不能（每周超过3次不能按时就餐）	2016-09-04 01:00:07.024891+08
P169300306	3712	生活习惯-运动锻炼                                                                                           	600685	55-1.您常采用的锻炼方式：（可多选）	B.慢跑或快步走；F.球类运动；	2016-10-11 17:01:36.087581+08
P169300306	3712	生活习惯-运动锻炼                                                                                           	600686	55-2.您每周锻炼几次？	A.1～2次	2016-10-11 17:01:36.090921+08
P169300306	3712	生活习惯-运动锻炼                                                                                           	600687	55-3.您每次锻炼多长时间？	B.30～60分钟	2016-10-11 17:01:36.094347+08
P169300306	3712	生活习惯-运动锻炼                                                                                           	600688	55-4.您坚持锻炼多少年了？	D.＞10年	2016-10-11 17:01:36.097675+08
P169300306	3712	生活习惯-运动锻炼                                                                                           	600689	56.您工作中的体力强度？	A.脑力劳动为主	2016-10-11 17:01:36.101002+08
P169300306	3712	生活习惯-运动锻炼                                                                                           	600690	56-1.您每周工作几天？	C.＞5天	2016-10-11 17:01:36.104306+08
P169300306	3712	生活习惯-运动锻炼                                                                                           	600691	56-2.您每天工作多长时间？	D.＞8小时	2016-10-11 17:01:36.107641+08
P169300306	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	B.2～4小时	2016-10-11 17:01:36.110987+08
P168160792	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-08-26 12:42:40.136407+08
P168160792	3709	生活习惯-饮食                                                                                             	600667	46.您平均每天吃多少蔬菜？	A.＜100g（少于2两）	2016-08-26 12:42:40.144969+08
P168170068	3709	生活习惯-饮食                                                                                             	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	A.＜50g（少于1两）	2016-08-26 12:42:40.225436+08
P167291284	3709	生活习惯-饮食	600672	51.您喝咖啡吗？	B.偶尔喝（每周1-2次）	2016-08-19 01:00:03.932634+08
P169260012	3709	生活习惯-饮食                                                                                             	600664	43.您吃鸡蛋吗？	B.偶尔吃（每周1-2次）	2016-09-30 01:00:06.989311+08
P168020113	3709	生活习惯-饮食	600659	38.您参加请客吃饭（应酬）情况？	A.不参加或偶尔参加（每周1次以下）	2016-08-11 13:44:13.72555+08
P167280908	3712	生活习惯-运动锻炼                                                                                           	600692	57.除工作、学习时间外，您每天坐着（如看电视、上网、打麻将、打牌等）的时间是？	C.4～6小时	2016-09-25 01:00:08.520389+08
P169300306	3710	生活习惯-吸烟                                                                                             	600675	53-1.您通常每天吸多少支烟？（含戒烟前）	B.10-20支	2016-10-11 17:01:38.901043+08
P169300306	3710	生活习惯-吸烟                                                                                             	600676	53-2.您持续吸烟的年限？（含戒烟前）	D.＞20年	2016-10-11 17:01:38.905216+08
P169300306	3711	生活习惯-饮酒                                                                                             	600678	54.您喝酒吗？（平均每周饮酒1次以上）	B.喝	2016-10-11 17:01:38.90881+08
P169300306	3711	生活习惯-饮酒                                                                                             	600679	54-1.您一般喝什么酒？（可多选）	A.白酒；B.啤酒；C.红酒；	2016-10-11 17:01:38.912089+08
P15C280643	3702	健康史-家族史	600607	1-1.请选择疾病的名称：（可多选）	父亲：A.高血压|55岁之后患病；外祖母：A.高血压|45岁之前患病；C.冠心病|45-65岁之间患病；	2016-08-19 01:00:03.227992+08
P167270185	3709	生活习惯-饮食	600661	40.您的饮食嗜好？（可多选）	H.无以上嗜好	2016-08-11 13:44:13.407367+08
P167270185	3709	生活习惯-饮食	600668	47.您平均每天吃多少肉（猪、牛、羊、禽）？	B.50～100g（1～2两）	2016-08-11 13:44:13.466352+08
P167291284	3702	健康史-家族史	600607	1-1.请选择疾病的名称：（可多选）	母亲：C.冠心病|45-65岁之间患病；父亲：A.高血压|45-55岁之间患病；祖母：A.高血压|65岁之后患病；B.脑卒中（中风）|65岁之后患病；M.恶性肿瘤；祖父：A.高血压|55岁之后患病；B.脑卒中（中风）|55岁之后患病；	2016-08-19 01:00:03.868795+08
\.


--
-- Name: departments_name_key; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY departments
    ADD CONSTRAINT departments_name_key UNIQUE (name);


--
-- Name: departments_pkey; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- Name: gene_results_barcode_test_product_test_item_gw_id_key; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY gene_results
    ADD CONSTRAINT gene_results_barcode_test_product_test_item_gw_id_key UNIQUE (barcode, test_product, test_item, gw_id);


--
-- Name: gene_results_pkey; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY gene_results
    ADD CONSTRAINT gene_results_pkey PRIMARY KEY (id);


--
-- Name: reports_barcode_test_product_plate_id_key; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_barcode_test_product_plate_id_key UNIQUE (barcode, test_product, plate_id);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: roles_name_key; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- Name: user_log_pkey; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY user_log
    ADD CONSTRAINT user_log_pkey PRIMARY KEY (id);


--
-- Name: user_role_pkey; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY user_role
    ADD CONSTRAINT user_role_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users_name_key; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_name_key UNIQUE (name);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: xy_conclusions_pkey; Type: CONSTRAINT; Schema: public; Owner: genopipe; Tablespace: 
--

ALTER TABLE ONLY xy_conclusions
    ADD CONSTRAINT xy_conclusions_pkey PRIMARY KEY (report_id);


--
-- Name: user_log_user_id_idx; Type: INDEX; Schema: public; Owner: genopipe; Tablespace: 
--

CREATE INDEX user_log_user_id_idx ON user_log USING btree (user_id);


--
-- Name: tg_department; Type: TRIGGER; Schema: public; Owner: genopipe
--

CREATE TRIGGER tg_department BEFORE INSERT OR UPDATE ON departments FOR EACH ROW EXECUTE PROCEDURE tp_change_department();


--
-- Name: tg_role; Type: TRIGGER; Schema: public; Owner: genopipe
--

CREATE TRIGGER tg_role BEFORE INSERT OR UPDATE ON roles FOR EACH ROW EXECUTE PROCEDURE tp_change_role();


--
-- Name: tg_user; Type: TRIGGER; Schema: public; Owner: genopipe
--

CREATE TRIGGER tg_user BEFORE INSERT OR DELETE OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE tp_change_user();


--
-- Name: user_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: genopipe
--

ALTER TABLE ONLY user_log
    ADD CONSTRAINT user_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id);


--
-- Name: user_role_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: genopipe
--

ALTER TABLE ONLY user_role
    ADD CONSTRAINT user_role_role_id_fkey FOREIGN KEY (role_id) REFERENCES roles(role_id);


--
-- Name: user_role_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: genopipe
--

ALTER TABLE ONLY user_role
    ADD CONSTRAINT user_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id);


--
-- Name: users_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: genopipe
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id) ON UPDATE CASCADE;


--
-- Name: xy_conclusions_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: genopipe
--

ALTER TABLE ONLY xy_conclusions
    ADD CONSTRAINT xy_conclusions_report_id_fkey FOREIGN KEY (report_id) REFERENCES reports(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: departments; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE departments FROM PUBLIC;
REVOKE ALL ON TABLE departments FROM genopipe;
GRANT ALL ON TABLE departments TO genopipe;
GRANT ALL ON TABLE departments TO genopipe_role;


--
-- Name: gene_results; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE gene_results FROM PUBLIC;
REVOKE ALL ON TABLE gene_results FROM genopipe;
GRANT ALL ON TABLE gene_results TO genopipe;
GRANT ALL ON TABLE gene_results TO genopipe_role;


--
-- Name: reports; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE reports FROM PUBLIC;
REVOKE ALL ON TABLE reports FROM genopipe;
GRANT ALL ON TABLE reports TO genopipe;
GRANT ALL ON TABLE reports TO genopipe_role;


--
-- Name: roles; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE roles FROM PUBLIC;
REVOKE ALL ON TABLE roles FROM genopipe;
GRANT ALL ON TABLE roles TO genopipe;
GRANT ALL ON TABLE roles TO genopipe_role;


--
-- Name: user_log; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE user_log FROM PUBLIC;
REVOKE ALL ON TABLE user_log FROM genopipe;
GRANT ALL ON TABLE user_log TO genopipe;
GRANT ALL ON TABLE user_log TO genopipe_role;


--
-- Name: user_role; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE user_role FROM PUBLIC;
REVOKE ALL ON TABLE user_role FROM genopipe;
GRANT ALL ON TABLE user_role TO genopipe;
GRANT ALL ON TABLE user_role TO genopipe_role;


--
-- Name: users; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE users FROM genopipe;
GRANT ALL ON TABLE users TO genopipe;
GRANT ALL ON TABLE users TO genopipe_role;


--
-- Name: xy_conclusions; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE xy_conclusions FROM PUBLIC;
REVOKE ALL ON TABLE xy_conclusions FROM genopipe;
GRANT ALL ON TABLE xy_conclusions TO genopipe;
GRANT ALL ON TABLE xy_conclusions TO genopipe_role;


--
-- Name: xy_specimen; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE xy_specimen FROM PUBLIC;
REVOKE ALL ON TABLE xy_specimen FROM genopipe;
GRANT ALL ON TABLE xy_specimen TO genopipe;
GRANT ALL ON TABLE xy_specimen TO genopipe_role;


--
-- Name: view_conclusions; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE view_conclusions FROM PUBLIC;
REVOKE ALL ON TABLE view_conclusions FROM genopipe;
GRANT ALL ON TABLE view_conclusions TO genopipe;
GRANT ALL ON TABLE view_conclusions TO genopipe_role;


--
-- Name: view_user_log; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE view_user_log FROM PUBLIC;
REVOKE ALL ON TABLE view_user_log FROM genopipe;
GRANT ALL ON TABLE view_user_log TO genopipe;
GRANT ALL ON TABLE view_user_log TO genopipe_role;


--
-- Name: view_user_role; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE view_user_role FROM PUBLIC;
REVOKE ALL ON TABLE view_user_role FROM genopipe;
GRANT ALL ON TABLE view_user_role TO genopipe;
GRANT ALL ON TABLE view_user_role TO genopipe_role;


--
-- Name: view_users; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE view_users FROM PUBLIC;
REVOKE ALL ON TABLE view_users FROM genopipe;
GRANT ALL ON TABLE view_users TO genopipe;
GRANT ALL ON TABLE view_users TO genopipe_role;


--
-- Name: xy_tijian; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE xy_tijian FROM PUBLIC;
REVOKE ALL ON TABLE xy_tijian FROM genopipe;
GRANT ALL ON TABLE xy_tijian TO genopipe;
GRANT ALL ON TABLE xy_tijian TO genopipe_role;


--
-- Name: xy_wenjuan; Type: ACL; Schema: public; Owner: genopipe
--

REVOKE ALL ON TABLE xy_wenjuan FROM PUBLIC;
REVOKE ALL ON TABLE xy_wenjuan FROM genopipe;
GRANT ALL ON TABLE xy_wenjuan TO genopipe;
GRANT ALL ON TABLE xy_wenjuan TO genopipe_role;


--
-- PostgreSQL database dump complete
--

