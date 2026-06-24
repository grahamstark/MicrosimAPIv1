-- psql -h /var/run/postgresql/ -U postgres
-- pg_lsclusters

-- drop database microapi; create database microapi;\c microapi

create table users(
    user_id bigint not null,
    email text default '',
    password text default '',
    description text,
    created timestamp,
    expiry timestamp,
    is_temp boolean default true,
    primary key(user_id));
insert into users values
( '1', '', md5('anything'), 'admin', now(), now() + interval '1000 years', false ),
( '2', '', md5('anything'), 'default', now(), now() + interval '1000 years', false );

create table models(
    model_name char(20) not null primary key,
    description text );
insert into models values( 'scotben', 'A Scottish Tax Benfit Model implemented in Julia.');

create table model_editions(
    model_name char(30) not null,
    model_edition char(30) not null default 'simple-2026a',
    description text,
    primary key( model_name, model_edition ),
    foreign key( model_name ) references models on delete cascade );
insert into model_editions values
    ('scotben', 'simple-2026a','A simple default set of parameters for Scotben.'),
    ('scotben', 'basic-income-2026a','A basic income simulation, God help us...');

create table q_statuses(
    qstatus char(1) not null primary key,
    label text );

insert into q_statuses values
('E', 'Editing'),
('Q', 'Queued/Submitted'),
('X', 'Executing'),
('C', 'Completed'),
('Z', 'Errored');

create table runs(
    user_id bigint not null,
    model_name char(20) not null default 'scotben',
    model_edition char(24) not null default 'simple-2026a',
    run_id integer not null,
    run_name text, -- actually, a uuid
    created timestamp,
    last_change timestamp,
    qstatus char(1) not null default 'E', -- E, Q,X,C
    output_is_cached boolean default false,
    -- is_edited boolean default false,
    working_dir text,
    primary key( user_id, run_id, model_name, model_edition ),
    foreign key( user_id ) references users on delete cascade,
    foreign key( qstatus ) references q_statuses,
    foreign key( model_name, model_edition) references model_editions );
-- a dummy test run
insert into runs values( 2, 'scotben', 'simple-2026a', 1234567890, 'default test run', now(), now(), 'E', true , 'dummy dir');

create table run_state(
    user_id bigint not null,
    model_name char(20) not null default 'scotben',
    model_edition char(40) not null default 'simple-2026a',
    run_id integer not null,
    thread_no int default 1,
    phase text not null,
    completed integer default 0,
    todo integer,
    timer timestamp,
    primary key( user_id, run_id, model_name, model_edition, thread_no ),
    foreign key( user_id, run_id, model_name, model_edition) references runs on delete cascade);

create table param_page_description(
    model_name char(20) not null default 'scotben',
    model_edition char(24) not null default 'simple-2026a',
    subsys char(30) not null,
    title text,
    info text,
    primary key( model_name, model_edition, subsys ),
    foreign key( model_name, model_edition) references model_editions );

-- replaced with Julia initialisation 'initialise_database()'
-- insert into param_page_description values
-- ('scotben', 'simple-2026a', 'SimpleParams', 'Basic Set of SB Parameters', '' ),
-- ('scotben', 'basic-income-2026a', 'BIParams','Basic Income Simulation Parameters', ''),
-- ('scotben', 'simple-2026a', 'RunSettings','Basic Income Run Settings Subset', ''),
-- ('scotben', 'basic-income-2026a', 'RunSettings', 'Default Run Settings Subset','');

create table run_params(
    user_id bigint not null,
    model_name char(20) not null default 'scotben',
    model_edition char(24) not null default 'simple-2026a',
    run_id integer not null,
    subsys char(30) not null,
    data text,
    errors text,
    primary key( user_id, run_id, model_name, model_edition, subsys ),
    foreign key( user_id, run_id, model_name, model_edition ) references runs on delete cascade on update cascade,
    foreign key( model_name, model_edition, subsys ) references param_page_description on delete cascade );

-- nb remove model_edition here on the assumption that any model edition can produce the same output
create table result_description(
    model_name char(20) not null default 'scotben',
    -- model_edition char(24) not null default 'simple-2026a',
    datatype char(30) not null default 'json',
    item char(30) not null,
    info text,
    primary key( model_name, item, datatype ),
    foreign key( model_name ) references models );

insert into result_description( model_name, item, datatype, info ) values

('scotben', 'overall_cost_table', 'html', 'One Line entry showing the net costs of your reform' ),
('scotben', 'costs_table', 'html', 'Short Table with headline costs of your reform' ),
('scotben', 'hhtype_gl', 'html', 'Gain Lose Table By Household Size (counts of individuals)' ),
('scotben', 'ten_gl', 'html', 'Gain Lose Table By Tenure(counts of individuals)' ),
('scotben', 'dec_gl', 'html', 'Gain Lose Table By Income Decile(counts of individuals)' ),
('scotben', 'children_gl', 'html', 'Gain Lose Table By Number of Children in the Household (counts of individuals)' ),
('scotben', 'reg_gl', 'html', 'Gain Lose Table By Region (counts of individuals)' ),
('scotben', 'sfc', 'html', 'Table describing our SFC correction' ),
('scotben', 'gain_lose_summary', 'html', 'Short text summary of numbers of gainers and losers' ),
('scotben', 'inequality_summary', 'html', 'Short textual summmary of our standard inequality measures.' ),
('scotben', 'metrs_table', 'html', 'Summary table of our Marginal Rate estimates (if available).' ),
('scotben', 'metrs_transitions', 'html', 'Transitions table from our Marginal Rate estimates (if available).' ),
('scotben', 'poverty_summary', 'html', 'Short Table with headline poverty measures' ),
('scotben', 'poverty_transitions', 'html', 'Summary table of our Poverty estimates (if available).' ),
('scotben', 'run_settings_summary', 'html', 'Highlights from the run settings' ),
('scotben', 'detailed_costs', 'html', 'Huge dump of all incomes and case counts from the run.' ),

('scotben', 'summary_graphs', 'svg', '4 quadrant summary graph' ),
('scotben', 'summary_graphs_v2', 'svg', '4 quadrant summary graph, 2nd version' ),
('scotben', 'taxable_graph', 'svg', 'Graph showing taxable income in bands against marginal tax rates' ),
('scotben', 'hbai', 'svg', 'Comparison graphs of equilvalised income in bands, similar to DWPs HBAI report graph' ),
('scotben', 'lorenz_curve', 'svg', 'Pre- and Post- Lorenz Curve' ),
('scotben', 'lorenz_curve_thumb', 'svg', 'Pre- and Post- Lorenz Curve (thumbnail)' ),
('scotben', 'deciles', 'svg', 'Average Gains and Losses by Eq, Income Decile' ),
('scotben', 'deciles_thumb', 'svg', 'Average Gains and Losses by Eq, Income Decile, thumbnail version' ),
('scotben', 'metrs_hist', 'svg', 'Density Plot of pre- and post- Marginal Effective Tax Rates (METRs)'),
('scotben', 'metrs', 'svg', 'pre- and post- Marginal Effective Tax Rates (METRs) in 2% intervals' ),
('scotben', 'metrs2', 'svg', 'pre- and post- Marginal Effective Tax Rates (METRs) in 2% intervals, 2 graph version' ),
('scotben', 'metrs_hist_thumb', 'svg', 'Density Plot of pre- and post- Marginal Effective Tax Rates (METRs), thumbnail version' );

create table run_results_cache(
    model_name char(20) not null default 'scotben',
    model_edition char(24) not null default 'simple-2026a',
    param_hash bigint not null,
    datatype char(30) not null default 'json',
    item char(30) not null,
    data text,
    primary key( model_name, model_edition, param_hash, item, datatype ),
    foreign key( model_name, item, datatype ) references result_description );
