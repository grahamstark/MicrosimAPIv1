-- psql -h /var/run/postgresql/ -U postgres
-- pg_lsclusters

-- drop database microapi;
-- create database microapi;
\c microapi

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
insert into models values( 'scotben', '');

create table model_versions(
    model_name char(20) not null,
    model_version char(12) not null default '0.17.0',
    description text,
    primary key( model_name, model_version ),
    foreign key( model_name ) references models on delete cascade );
insert into model_versions values('scotben', '0.17.0','');

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
    model_version char(12) not null default '0.17.0',
    run_id integer not null,
    run_name char(32), -- actually, a uuid
    submission timestamp,
    qstatus char(1) not null default 'E', -- E, Q,X,C
    output_in_sync boolean default true,
    -- is_edited boolean default false,
    working_dir text,
    primary key( user_id, run_id, model_name, model_version ),
    foreign key( user_id ) references users on delete cascade,
    foreign key( qstatus ) references q_statuses,
    foreign key( model_name, model_version) references model_versions );
-- a dummy test run
insert into runs values( 2, 'scotben', '0.17.0', 1234567890, 'default test run', now(), 'E', true , 'dummy dir');

create table run_state(
    user_id bigint not null,
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17.0',
    run_id integer not null,
    thread_no int default 1,
    phase text not null,
    completed integer default 0,
    todo integer,
    timer timestamp,
    primary key( user_id, run_id, model_name, model_version, thread_no ),
    foreign key( user_id, run_id, model_name, model_version) references runs );

create table param_page_description(
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17.0',
    name  char(30) not null,
    info text,
    primary key( model_name, model_version, name ),
    foreign key( model_name, model_version) references model_versions );

insert into param_page_description values
('scotben', '0.17.0', 'SimpleParams', 'Basic Set of SB Parameters' ),
('scotben', '0.17.0', 'RunSettings',  'Default Run Settings' );

create table run_params(
    user_id bigint not null,
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17.0',
    run_id integer not null,
    name char(30) not null,
    data text,
    errors text,
    primary key( user_id, run_id, model_name, model_version, name ),
    foreign key( user_id, run_id, model_name, model_version ) references runs on delete cascade on update cascade,
    foreign key( model_name, model_version, name) references param_page_description );

create table result_description(
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17.0',
    datatype char(30) not null default 'json',
    item char(30) not null,
    info text,
    primary key( model_name, model_version, item, datatype ),
    foreign key( model_name, model_version) references model_versions );

insert into result_description( model_name, model_version, datatype, item, info ) values
('scotben', '0.17.0', 'summmary_graphs', 'svg', 'A set of four summary graphs'),
('scotben', '0.17.0', 'summary_graphs_v2 ', 'svg', 'A set of four summary graphs'),
('scotben', '0.17.0', 'taxable_graph', 'svg', 'Chart of taxable income, in bands, with marginal tax rates.'),
('scotben', '0.17.0', 'hbai', 'svg', 'Reproduction of the standard HBAI diagram, with income in bands and deciles.'),
('scotben', '0.17.0', 'lorenz_curve', 'svg', 'A standard Lorenz Curve'),
('scotben', '0.17.0', 'lorenz_curve_thumb','svg', 'Thumbnail verison of a standard Lorenz Curve'),
('scotben', '0.17.0', 'deciles','svg', 'Average Gains by income decile.'),
('scotben', '0.17.0', 'deciles_thumb', 'svg', 'Average Gains by income decile, Thumbnail version.'),
('scotben', '0.17.0', 'metrs_hist', 'svg', 'Histogram of Marginal Effective Tax Rates (METRs)'),
('scotben', '0.17.0', 'metrs', 'svg', 'Bar Chart of Marginal Effective Tax Rates (METRs)'),
('scotben', '0.17.0', 'metrs2', 'svg', 'Bar Chart of Marginal Effective Tax Rates (METRs)'),
('scotben', '0.17.0', 'metrs_hist_thumb', 'svg', 'Bar Chart of Marginal Effective Tax Rates (METRs), thumbnail'),
('scotben', '0.17.0', 'overall_cost_table', 'html', 'format_overall_cost('),
('scotben', '0.17.0', 'costs_table', 'html', 'format_costs_table('),
('scotben', '0.17.0', 'hhtype_gl', 'html', 'format_gainlose("By Household Size",summary.gain_lose[2].hhtype_gl ),'),
('scotben', '0.17.0', 'ten_gl', 'html', 'format_gainlose("By Tenure Type",summary.gain_lose[2].ten_gl ),'),
('scotben', '0.17.0', 'dec_gl', 'html', 'format_gainlose("By Decile",summary.gain_lose[2].dec_gl ),'),
('scotben', '0.17.0', 'children_gl', 'html', 'format_gainlose("By Numbers of Children",summary.gain_lose[2].children_gl ),'),
('scotben', '0.17.0', 'reg_gl', 'html', 'format_gainlose("By Region",summary.gain_lose[2].reg_gl ),'),
('scotben', '0.17.0', 'sfc', 'html', 'format_sfc("SFC Behavioral Corrections", results.behavioural_results[2]),'),
('scotben', '0.17.0', 'gain_lose_summary', 'html', 'format_gain_lose_table_v2( summary.gain_lose[2] ),'),
('scotben', '0.17.0', 'inequality_summary', 'html', 'format_ineq_table('),
('scotben', '0.17.0', 'metrs_table', 'html', 'format_mr_table( summary.metrs[1], summary.metrs[2] ),'),
('scotben', '0.17.0', 'poverty_summary', 'html', 'format_pov_table( summary.poverty[1],'),
('scotben', '0.17.0', 'poverty_transitions', 'html', 'format_pov_transitions( summary.povtrans_matrix[2]),'),
('scotben', '0.17.0', 'run_settings_summary', 'html', 'format_run_settings_summary( settings ),'),
('scotben', '0.17.0', 'detailed_costs', 'html', 'costs_frame_to_table(detailed_cost_dataframe('),
('scotben', '0.17.0', 'headline_figures','json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'quantiles', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'quantiles_df', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'deciles', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'deciles_df', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'income_summary', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'poverty', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'inequality', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'metrs', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'metrs_df', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'child_poverty', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'ten_gl', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'dec_gl', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'reg_gl', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'children_gl', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'poverty_lines', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'short_income_summary', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'very_short_income_summary', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'income_hists', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'income_hists_df', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'taxable_income_hists', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'povtrans_matrix', 'json', 'Desciption Goes Here'),
('scotben', '0.17.0', 'povtrans_matrix_df', 'json', 'Desciption Goes Here');

--
-- create table run_results(
--     user_id bigint not null,
--     model_name char(20) not null default 'scotben',
--     model_version char(12) not null default '0.17.0',
--     run_id integer not null,
--     item char(30) not null,
--     datatype char(30) not null default 'json',
--     data text,
--     primary key( user_id, run_id, model_name, model_version, item, datatype ),
--     foreign key( user_id, run_id, model_name, model_version ) references runs on delete cascade on update cascade,
--     foreign key( model_name, model_version, item, datatype ) references result_description );
--

create table run_results_cache(
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17.0',
    param_hash bigint not null,
    datatype char(30) not null default 'json',
    item char(30) not null,
    data text,
    primary key( model_name, model_version, param_hash, item, datatype ),
    foreign key( model_name, model_version, item, datatype ) references result_description );
