--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.7
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE access_levels (
    id integer NOT NULL,
    name character varying,
    application_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ad_security_group character varying
);


--
-- Name: access_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE access_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE access_levels_id_seq OWNED BY access_levels.id;


--
-- Name: adp_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE adp_events (
    id integer NOT NULL,
    json text,
    msg_id text,
    status text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: adp_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE adp_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adp_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE adp_events_id_seq OWNED BY adp_events.id;


--
-- Name: applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE applications (
    id integer NOT NULL,
    name character varying,
    description text,
    dependency text,
    onboard_instructions text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    offboard_instructions text,
    ad_controls boolean
);


--
-- Name: applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE applications_id_seq OWNED BY applications.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE departments (
    id integer NOT NULL,
    name character varying,
    code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    parent_org_id integer,
    status character varying
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE departments_id_seq OWNED BY departments.id;


--
-- Name: dept_mach_bundles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE dept_mach_bundles (
    id integer NOT NULL,
    department_id integer,
    machine_bundle_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: dept_mach_bundles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dept_mach_bundles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dept_mach_bundles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dept_mach_bundles_id_seq OWNED BY dept_mach_bundles.id;


--
-- Name: dept_sec_profs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE dept_sec_profs (
    id integer NOT NULL,
    department_id integer,
    security_profile_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: dept_sec_profs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dept_sec_profs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dept_sec_profs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dept_sec_profs_id_seq OWNED BY dept_sec_profs.id;


--
-- Name: emp_access_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE emp_access_levels (
    id integer NOT NULL,
    access_level_id integer,
    active boolean,
    employee_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: emp_access_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emp_access_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emp_access_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE emp_access_levels_id_seq OWNED BY emp_access_levels.id;


--
-- Name: emp_delta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE emp_delta (
    id integer NOT NULL,
    employee_id integer,
    before hstore,
    after hstore,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: emp_delta_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emp_delta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emp_delta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE emp_delta_id_seq OWNED BY emp_delta.id;


--
-- Name: emp_mach_bundles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE emp_mach_bundles (
    id integer NOT NULL,
    employee_id integer,
    machine_bundle_id integer,
    emp_transaction_id integer,
    details hstore,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: emp_mach_bundles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emp_mach_bundles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emp_mach_bundles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE emp_mach_bundles_id_seq OWNED BY emp_mach_bundles.id;


--
-- Name: emp_sec_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE emp_sec_profiles (
    id integer NOT NULL,
    employee_id integer,
    security_profile_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    emp_transaction_id integer,
    revoking_transaction_id integer
);


--
-- Name: emp_sec_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emp_sec_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emp_sec_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE emp_sec_profiles_id_seq OWNED BY emp_sec_profiles.id;


--
-- Name: emp_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE emp_transactions (
    id integer NOT NULL,
    kind character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    notes text
);


--
-- Name: emp_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emp_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emp_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE emp_transactions_id_seq OWNED BY emp_transactions.id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE employees (
    id integer NOT NULL,
    email character varying,
    first_name character varying,
    last_name character varying,
    workday_username character varying,
    employee_id character varying,
    hire_date timestamp without time zone,
    contract_end_date timestamp without time zone,
    termination_date timestamp without time zone,
    job_family_id character varying,
    job_family character varying,
    job_profile_id character varying,
    job_profile character varying,
    business_title character varying,
    employee_type character varying,
    contingent_worker_id character varying,
    contingent_worker_type character varying,
    manager_id character varying,
    personal_mobile_phone character varying,
    office_phone character varying,
    home_address_1 character varying,
    home_address_2 character varying,
    home_city character varying,
    home_state character varying,
    home_zip character varying,
    image_code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ad_updated_at timestamp without time zone,
    leave_start_date timestamp without time zone,
    leave_return_date timestamp without time zone,
    department_id integer,
    location_id integer,
    sam_account_name character varying,
    company character varying,
    status character varying,
    adp_assoc_oid character varying,
    worker_type_id integer,
    job_title_id integer
);


--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE employees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE employees_id_seq OWNED BY employees.id;


--
-- Name: job_titles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE job_titles (
    id integer NOT NULL,
    name character varying,
    code character varying,
    status character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: job_titles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE job_titles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_titles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE job_titles_id_seq OWNED BY job_titles.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE locations (
    id integer NOT NULL,
    name character varying,
    kind character varying DEFAULT 'Pending Assignment'::character varying,
    country character varying DEFAULT 'Pending Assignment'::character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status character varying,
    code character varying,
    timezone character varying DEFAULT 'Pending Assignment'::character varying
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE locations_id_seq OWNED BY locations.id;


--
-- Name: machine_bundles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE machine_bundles (
    id integer NOT NULL,
    name character varying,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: machine_bundles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE machine_bundles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_bundles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE machine_bundles_id_seq OWNED BY machine_bundles.id;


--
-- Name: offboarding_infos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE offboarding_infos (
    id integer NOT NULL,
    employee_id integer,
    emp_transaction_id integer,
    archive_data boolean,
    replacement_hired boolean,
    forward_email_id integer,
    reassign_salesforce_id integer,
    transfer_google_docs_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: offboarding_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE offboarding_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offboarding_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE offboarding_infos_id_seq OWNED BY offboarding_infos.id;


--
-- Name: onboarding_infos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE onboarding_infos (
    id integer NOT NULL,
    employee_id integer,
    emp_transaction_id integer,
    buddy_id integer,
    cw_email boolean,
    cw_google_membership boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: onboarding_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE onboarding_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: onboarding_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE onboarding_infos_id_seq OWNED BY onboarding_infos.id;


--
-- Name: parent_orgs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE parent_orgs (
    id integer NOT NULL,
    name character varying,
    code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: parent_orgs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE parent_orgs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parent_orgs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE parent_orgs_id_seq OWNED BY parent_orgs.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sec_prof_access_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sec_prof_access_levels (
    id integer NOT NULL,
    access_level_id integer,
    security_profile_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sec_prof_access_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sec_prof_access_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sec_prof_access_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sec_prof_access_levels_id_seq OWNED BY sec_prof_access_levels.id;


--
-- Name: security_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE security_profiles (
    id integer NOT NULL,
    name character varying,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: security_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE security_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: security_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE security_profiles_id_seq OWNED BY security_profiles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    first_name character varying,
    last_name character varying,
    ldap_user character varying DEFAULT ''::character varying NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role_names character varying DEFAULT 'Basic'::character varying NOT NULL,
    employee_id character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: worker_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE worker_types (
    id integer NOT NULL,
    name character varying,
    code character varying,
    kind character varying DEFAULT 'Pending Assignment'::character varying,
    status character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: worker_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE worker_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE worker_types_id_seq OWNED BY worker_types.id;


--
-- Name: xml_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE xml_transactions (
    id integer NOT NULL,
    name character varying,
    checksum character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: xml_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE xml_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: xml_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE xml_transactions_id_seq OWNED BY xml_transactions.id;


--
-- Name: access_levels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_levels ALTER COLUMN id SET DEFAULT nextval('access_levels_id_seq'::regclass);


--
-- Name: adp_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY adp_events ALTER COLUMN id SET DEFAULT nextval('adp_events_id_seq'::regclass);


--
-- Name: applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY applications ALTER COLUMN id SET DEFAULT nextval('applications_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY departments ALTER COLUMN id SET DEFAULT nextval('departments_id_seq'::regclass);


--
-- Name: dept_mach_bundles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY dept_mach_bundles ALTER COLUMN id SET DEFAULT nextval('dept_mach_bundles_id_seq'::regclass);


--
-- Name: dept_sec_profs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY dept_sec_profs ALTER COLUMN id SET DEFAULT nextval('dept_sec_profs_id_seq'::regclass);


--
-- Name: emp_access_levels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_access_levels ALTER COLUMN id SET DEFAULT nextval('emp_access_levels_id_seq'::regclass);


--
-- Name: emp_delta id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_delta ALTER COLUMN id SET DEFAULT nextval('emp_delta_id_seq'::regclass);


--
-- Name: emp_mach_bundles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_mach_bundles ALTER COLUMN id SET DEFAULT nextval('emp_mach_bundles_id_seq'::regclass);


--
-- Name: emp_sec_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_sec_profiles ALTER COLUMN id SET DEFAULT nextval('emp_sec_profiles_id_seq'::regclass);


--
-- Name: emp_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_transactions ALTER COLUMN id SET DEFAULT nextval('emp_transactions_id_seq'::regclass);


--
-- Name: employees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY employees ALTER COLUMN id SET DEFAULT nextval('employees_id_seq'::regclass);


--
-- Name: job_titles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY job_titles ALTER COLUMN id SET DEFAULT nextval('job_titles_id_seq'::regclass);


--
-- Name: locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY locations ALTER COLUMN id SET DEFAULT nextval('locations_id_seq'::regclass);


--
-- Name: machine_bundles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY machine_bundles ALTER COLUMN id SET DEFAULT nextval('machine_bundles_id_seq'::regclass);


--
-- Name: offboarding_infos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY offboarding_infos ALTER COLUMN id SET DEFAULT nextval('offboarding_infos_id_seq'::regclass);


--
-- Name: onboarding_infos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY onboarding_infos ALTER COLUMN id SET DEFAULT nextval('onboarding_infos_id_seq'::regclass);


--
-- Name: parent_orgs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY parent_orgs ALTER COLUMN id SET DEFAULT nextval('parent_orgs_id_seq'::regclass);


--
-- Name: sec_prof_access_levels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sec_prof_access_levels ALTER COLUMN id SET DEFAULT nextval('sec_prof_access_levels_id_seq'::regclass);


--
-- Name: security_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY security_profiles ALTER COLUMN id SET DEFAULT nextval('security_profiles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: worker_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY worker_types ALTER COLUMN id SET DEFAULT nextval('worker_types_id_seq'::regclass);


--
-- Name: xml_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY xml_transactions ALTER COLUMN id SET DEFAULT nextval('xml_transactions_id_seq'::regclass);


--
-- Name: access_levels access_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_levels
    ADD CONSTRAINT access_levels_pkey PRIMARY KEY (id);


--
-- Name: adp_events adp_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY adp_events
    ADD CONSTRAINT adp_events_pkey PRIMARY KEY (id);


--
-- Name: applications applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: dept_mach_bundles dept_mach_bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dept_mach_bundles
    ADD CONSTRAINT dept_mach_bundles_pkey PRIMARY KEY (id);


--
-- Name: dept_sec_profs dept_sec_profs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dept_sec_profs
    ADD CONSTRAINT dept_sec_profs_pkey PRIMARY KEY (id);


--
-- Name: emp_access_levels emp_access_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_access_levels
    ADD CONSTRAINT emp_access_levels_pkey PRIMARY KEY (id);


--
-- Name: emp_delta emp_delta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_delta
    ADD CONSTRAINT emp_delta_pkey PRIMARY KEY (id);


--
-- Name: emp_mach_bundles emp_mach_bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_mach_bundles
    ADD CONSTRAINT emp_mach_bundles_pkey PRIMARY KEY (id);


--
-- Name: emp_sec_profiles emp_sec_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_sec_profiles
    ADD CONSTRAINT emp_sec_profiles_pkey PRIMARY KEY (id);


--
-- Name: emp_transactions emp_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_transactions
    ADD CONSTRAINT emp_transactions_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: job_titles job_titles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY job_titles
    ADD CONSTRAINT job_titles_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: machine_bundles machine_bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY machine_bundles
    ADD CONSTRAINT machine_bundles_pkey PRIMARY KEY (id);


--
-- Name: offboarding_infos offboarding_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY offboarding_infos
    ADD CONSTRAINT offboarding_infos_pkey PRIMARY KEY (id);


--
-- Name: onboarding_infos onboarding_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY onboarding_infos
    ADD CONSTRAINT onboarding_infos_pkey PRIMARY KEY (id);


--
-- Name: parent_orgs parent_orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parent_orgs
    ADD CONSTRAINT parent_orgs_pkey PRIMARY KEY (id);


--
-- Name: sec_prof_access_levels sec_prof_access_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sec_prof_access_levels
    ADD CONSTRAINT sec_prof_access_levels_pkey PRIMARY KEY (id);


--
-- Name: security_profiles security_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY security_profiles
    ADD CONSTRAINT security_profiles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: worker_types worker_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY worker_types
    ADD CONSTRAINT worker_types_pkey PRIMARY KEY (id);


--
-- Name: xml_transactions xml_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY xml_transactions
    ADD CONSTRAINT xml_transactions_pkey PRIMARY KEY (id);


--
-- Name: index_emp_access_levels_on_access_level_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emp_access_levels_on_access_level_id ON emp_access_levels USING btree (access_level_id);


--
-- Name: index_emp_access_levels_on_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emp_access_levels_on_employee_id ON emp_access_levels USING btree (employee_id);


--
-- Name: index_users_on_ldap_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_ldap_user ON users USING btree (ldap_user);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: emp_access_levels fk_rails_48d50172ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_access_levels
    ADD CONSTRAINT fk_rails_48d50172ea FOREIGN KEY (access_level_id) REFERENCES access_levels(id);


--
-- Name: emp_access_levels fk_rails_aad375f9bf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emp_access_levels
    ADD CONSTRAINT fk_rails_aad375f9bf FOREIGN KEY (employee_id) REFERENCES employees(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20160422190723');

INSERT INTO schema_migrations (version) VALUES ('20160422214340');

INSERT INTO schema_migrations (version) VALUES ('20160517181703');

INSERT INTO schema_migrations (version) VALUES ('20160517213334');

INSERT INTO schema_migrations (version) VALUES ('20160531164351');

INSERT INTO schema_migrations (version) VALUES ('20160610201900');

INSERT INTO schema_migrations (version) VALUES ('20160705233106');

INSERT INTO schema_migrations (version) VALUES ('20160705234807');

INSERT INTO schema_migrations (version) VALUES ('20160706215814');

INSERT INTO schema_migrations (version) VALUES ('20160707191206');

INSERT INTO schema_migrations (version) VALUES ('20160707213149');

INSERT INTO schema_migrations (version) VALUES ('20160708213547');

INSERT INTO schema_migrations (version) VALUES ('20160708213630');

INSERT INTO schema_migrations (version) VALUES ('20160708214050');

INSERT INTO schema_migrations (version) VALUES ('20160708214143');

INSERT INTO schema_migrations (version) VALUES ('20160708214302');

INSERT INTO schema_migrations (version) VALUES ('20160725214442');

INSERT INTO schema_migrations (version) VALUES ('20160726001734');

INSERT INTO schema_migrations (version) VALUES ('20160810173516');

INSERT INTO schema_migrations (version) VALUES ('20160810173734');

INSERT INTO schema_migrations (version) VALUES ('20160812213629');

INSERT INTO schema_migrations (version) VALUES ('20160816201525');

INSERT INTO schema_migrations (version) VALUES ('20160823182401');

INSERT INTO schema_migrations (version) VALUES ('20160824224525');

INSERT INTO schema_migrations (version) VALUES ('20160825205552');

INSERT INTO schema_migrations (version) VALUES ('20160902210944');

INSERT INTO schema_migrations (version) VALUES ('20160912181907');

INSERT INTO schema_migrations (version) VALUES ('20160912203248');

INSERT INTO schema_migrations (version) VALUES ('20160912210728');

INSERT INTO schema_migrations (version) VALUES ('20160929213305');

INSERT INTO schema_migrations (version) VALUES ('20161004015631');

INSERT INTO schema_migrations (version) VALUES ('20161004174735');

INSERT INTO schema_migrations (version) VALUES ('20161111191909');

INSERT INTO schema_migrations (version) VALUES ('20170110233820');

INSERT INTO schema_migrations (version) VALUES ('20170111023308');

INSERT INTO schema_migrations (version) VALUES ('20170112011029');

INSERT INTO schema_migrations (version) VALUES ('20170112011420');

INSERT INTO schema_migrations (version) VALUES ('20170118005328');

INSERT INTO schema_migrations (version) VALUES ('20170119035854');

INSERT INTO schema_migrations (version) VALUES ('20170119035936');

INSERT INTO schema_migrations (version) VALUES ('20170123200145');

INSERT INTO schema_migrations (version) VALUES ('20170204023615');

INSERT INTO schema_migrations (version) VALUES ('20170210005501');

INSERT INTO schema_migrations (version) VALUES ('20170509185839');

INSERT INTO schema_migrations (version) VALUES ('20170614232456');

