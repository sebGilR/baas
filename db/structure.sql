SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: gen_uuidv7(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_uuidv7() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE
  unix_ts_ms bytea;
  rand_bytes bytea;
  uuid_bytes bytea;
BEGIN
  unix_ts_ms = decode(lpad(to_hex(floor(extract(epoch from clock_timestamp()) * 1000)::bigint), 12, '0'), 'hex');
  rand_bytes = gen_random_bytes(10);
  uuid_bytes = unix_ts_ms || rand_bytes;
  uuid_bytes = set_byte(uuid_bytes, 6, (get_byte(uuid_bytes, 6) & 15) | 112);
  uuid_bytes = set_byte(uuid_bytes, 8, (get_byte(uuid_bytes, 8) & 63) | 128);
  RETURN encode(uuid_bytes, 'hex')::uuid;
END
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_memberships (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    user_id bigint NOT NULL,
    account_id bigint NOT NULL,
    role integer DEFAULT 0,
    status integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: account_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_memberships_id_seq OWNED BY public.account_memberships.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    status integer DEFAULT 0,
    plan integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blogs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blogs (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    account_id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    settings jsonb DEFAULT '{}'::jsonb,
    status integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blogs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blogs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blogs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blogs_id_seq OWNED BY public.blogs.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    account_id bigint NOT NULL,
    parent_id bigint,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    "position" integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drafts (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    account_id bigint NOT NULL,
    blog_id bigint NOT NULL,
    author_id bigint NOT NULL,
    post_id bigint,
    title character varying,
    content text,
    autosaved_at timestamp(6) without time zone,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: drafts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.drafts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: drafts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.drafts_id_seq OWNED BY public.drafts.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    account_id bigint NOT NULL,
    blog_id bigint NOT NULL,
    author_id bigint NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    content text,
    excerpt text,
    status integer DEFAULT 0 NOT NULL,
    published_at timestamp(6) without time zone,
    scheduled_for timestamp(6) without time zone,
    seo_title character varying,
    seo_description text,
    reading_time_minutes integer,
    featured boolean DEFAULT false NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    category_id bigint
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_tokens (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    user_id bigint NOT NULL,
    jti character varying NOT NULL,
    token_digest character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    device_info jsonb DEFAULT '{}'::jsonb,
    last_used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.refresh_tokens_id_seq OWNED BY public.refresh_tokens.id;


--
-- Name: revisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.revisions (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    account_id bigint NOT NULL,
    post_id bigint NOT NULL,
    created_by_id bigint NOT NULL,
    title character varying NOT NULL,
    content text,
    revision_number integer NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.revisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.revisions_id_seq OWNED BY public.revisions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taggings (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    account_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    taggable_type character varying NOT NULL,
    taggable_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taggings_id_seq OWNED BY public.taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    account_id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    color character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    public_id uuid DEFAULT public.gen_uuidv7() NOT NULL,
    email character varying NOT NULL,
    password_digest character varying NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: account_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_memberships ALTER COLUMN id SET DEFAULT nextval('public.account_memberships_id_seq'::regclass);


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: blogs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blogs ALTER COLUMN id SET DEFAULT nextval('public.blogs_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: drafts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts ALTER COLUMN id SET DEFAULT nextval('public.drafts_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('public.refresh_tokens_id_seq'::regclass);


--
-- Name: revisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revisions ALTER COLUMN id SET DEFAULT nextval('public.revisions_id_seq'::regclass);


--
-- Name: taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings ALTER COLUMN id SET DEFAULT nextval('public.taggings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: account_memberships account_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_memberships
    ADD CONSTRAINT account_memberships_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: blogs blogs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blogs
    ADD CONSTRAINT blogs_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: drafts drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: revisions revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revisions
    ADD CONSTRAINT revisions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_account_memberships_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_memberships_on_account_id ON public.account_memberships USING btree (account_id);


--
-- Name: index_account_memberships_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_memberships_on_public_id ON public.account_memberships USING btree (public_id);


--
-- Name: index_account_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_memberships_on_user_id ON public.account_memberships USING btree (user_id);


--
-- Name: index_account_memberships_on_user_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_memberships_on_user_id_and_account_id ON public.account_memberships USING btree (user_id, account_id);


--
-- Name: index_accounts_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_public_id ON public.accounts USING btree (public_id);


--
-- Name: index_accounts_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_slug ON public.accounts USING btree (slug);


--
-- Name: index_blogs_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blogs_on_account_id ON public.blogs USING btree (account_id);


--
-- Name: index_blogs_on_account_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blogs_on_account_id_and_slug ON public.blogs USING btree (account_id, slug);


--
-- Name: index_blogs_on_account_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blogs_on_account_id_and_status ON public.blogs USING btree (account_id, status);


--
-- Name: index_blogs_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blogs_on_public_id ON public.blogs USING btree (public_id);


--
-- Name: index_categories_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_account_id ON public.categories USING btree (account_id);


--
-- Name: index_categories_on_account_id_and_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_account_id_and_parent_id ON public.categories USING btree (account_id, parent_id);


--
-- Name: index_categories_on_account_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_categories_on_account_id_and_slug ON public.categories USING btree (account_id, slug);


--
-- Name: index_categories_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_parent_id ON public.categories USING btree (parent_id);


--
-- Name: index_categories_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_categories_on_public_id ON public.categories USING btree (public_id);


--
-- Name: index_drafts_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_account_id ON public.drafts USING btree (account_id);


--
-- Name: index_drafts_on_account_id_and_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_account_id_and_author_id ON public.drafts USING btree (account_id, author_id);


--
-- Name: index_drafts_on_account_id_and_blog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_account_id_and_blog_id ON public.drafts USING btree (account_id, blog_id);


--
-- Name: index_drafts_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_author_id ON public.drafts USING btree (author_id);


--
-- Name: index_drafts_on_blog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_blog_id ON public.drafts USING btree (blog_id);


--
-- Name: index_drafts_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_post_id ON public.drafts USING btree (post_id);


--
-- Name: index_drafts_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_drafts_on_public_id ON public.drafts USING btree (public_id);


--
-- Name: index_posts_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_account_id ON public.posts USING btree (account_id);


--
-- Name: index_posts_on_account_id_and_blog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_account_id_and_blog_id ON public.posts USING btree (account_id, blog_id);


--
-- Name: index_posts_on_account_id_and_featured; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_account_id_and_featured ON public.posts USING btree (account_id, featured);


--
-- Name: index_posts_on_account_id_and_published_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_account_id_and_published_at ON public.posts USING btree (account_id, published_at);


--
-- Name: index_posts_on_account_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_posts_on_account_id_and_slug ON public.posts USING btree (account_id, slug);


--
-- Name: index_posts_on_account_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_account_id_and_status ON public.posts USING btree (account_id, status);


--
-- Name: index_posts_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_author_id ON public.posts USING btree (author_id);


--
-- Name: index_posts_on_blog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_blog_id ON public.posts USING btree (blog_id);


--
-- Name: index_posts_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_category_id ON public.posts USING btree (category_id);


--
-- Name: index_posts_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_posts_on_public_id ON public.posts USING btree (public_id);


--
-- Name: index_refresh_tokens_on_jti; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_refresh_tokens_on_jti ON public.refresh_tokens USING btree (jti);


--
-- Name: index_refresh_tokens_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_refresh_tokens_on_public_id ON public.refresh_tokens USING btree (public_id);


--
-- Name: index_refresh_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refresh_tokens_on_user_id ON public.refresh_tokens USING btree (user_id);


--
-- Name: index_refresh_tokens_on_user_id_and_revoked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refresh_tokens_on_user_id_and_revoked_at ON public.refresh_tokens USING btree (user_id, revoked_at);


--
-- Name: index_revisions_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_revisions_on_account_id ON public.revisions USING btree (account_id);


--
-- Name: index_revisions_on_account_id_and_post_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_revisions_on_account_id_and_post_id_and_created_at ON public.revisions USING btree (account_id, post_id, created_at);


--
-- Name: index_revisions_on_account_id_and_post_id_and_revision_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_revisions_on_account_id_and_post_id_and_revision_number ON public.revisions USING btree (account_id, post_id, revision_number);


--
-- Name: index_revisions_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_revisions_on_created_by_id ON public.revisions USING btree (created_by_id);


--
-- Name: index_revisions_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_revisions_on_post_id ON public.revisions USING btree (post_id);


--
-- Name: index_revisions_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_revisions_on_public_id ON public.revisions USING btree (public_id);


--
-- Name: index_taggings_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_account_id ON public.taggings USING btree (account_id);


--
-- Name: index_taggings_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_taggings_on_public_id ON public.taggings USING btree (public_id);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tag_id ON public.taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable ON public.taggings USING btree (taggable_type, taggable_id);


--
-- Name: index_taggings_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_taggings_uniqueness ON public.taggings USING btree (account_id, tag_id, taggable_type, taggable_id);


--
-- Name: index_tags_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_account_id ON public.tags USING btree (account_id);


--
-- Name: index_tags_on_account_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_account_id_and_name ON public.tags USING btree (account_id, name);


--
-- Name: index_tags_on_account_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_account_id_and_slug ON public.tags USING btree (account_id, slug);


--
-- Name: index_tags_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_public_id ON public.tags USING btree (public_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_public_id ON public.users USING btree (public_id);


--
-- Name: posts fk_rails_04d13ef8c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_04d13ef8c7 FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: drafts fk_rails_1b49dc20e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT fk_rails_1b49dc20e4 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: refresh_tokens fk_rails_279e9a0091; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT fk_rails_279e9a0091 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: blogs fk_rails_39105cea0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blogs
    ADD CONSTRAINT fk_rails_39105cea0c FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: categories fk_rails_4fd3bba7e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_4fd3bba7e8 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: drafts fk_rails_71119d8b1d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT fk_rails_71119d8b1d FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: revisions fk_rails_7f51d992ef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revisions
    ADD CONSTRAINT fk_rails_7f51d992ef FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: categories fk_rails_82f48f7407; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_82f48f7407 FOREIGN KEY (parent_id) REFERENCES public.categories(id);


--
-- Name: tags fk_rails_86647bc40a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_86647bc40a FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: account_memberships fk_rails_8e0ff21478; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_memberships
    ADD CONSTRAINT fk_rails_8e0ff21478 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: posts fk_rails_9b1b26f040; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_9b1b26f040 FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: taggings fk_rails_9fcd2e236b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT fk_rails_9fcd2e236b FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: drafts fk_rails_a6ea34b2b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT fk_rails_a6ea34b2b4 FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: taggings fk_rails_b1ed8e1e37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT fk_rails_b1ed8e1e37 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: account_memberships fk_rails_c33721ecfa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_memberships
    ADD CONSTRAINT fk_rails_c33721ecfa FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: posts fk_rails_dda555d01f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_dda555d01f FOREIGN KEY (blog_id) REFERENCES public.blogs(id);


--
-- Name: drafts fk_rails_e27f6caf88; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT fk_rails_e27f6caf88 FOREIGN KEY (blog_id) REFERENCES public.blogs(id);


--
-- Name: revisions fk_rails_e32d42bb6c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revisions
    ADD CONSTRAINT fk_rails_e32d42bb6c FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: revisions fk_rails_eedd777d36; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revisions
    ADD CONSTRAINT fk_rails_eedd777d36 FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: posts fk_rails_ff02f0408e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_ff02f0408e FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20251130203859'),
('20251130203228'),
('20251130203226'),
('20251130203225'),
('20251130203223'),
('20251130203221'),
('20251130203220'),
('20251130203147'),
('20251123220637'),
('20251123220608'),
('20251123220549'),
('20251123220517'),
('20251123220438'),
('20251123022948');

