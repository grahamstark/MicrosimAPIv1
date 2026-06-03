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
    output_in_sync boolean default true,
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
    foreign key( user_id, run_id, model_name, model_edition) references runs );

create table param_page_description(
    model_name char(20) not null default 'scotben',
    model_edition char(24) not null default 'simple-2026a',
    name  char(30) not null,
    info text,
    primary key( model_name, model_edition, name ),
    foreign key( model_name, model_edition) references model_editions );

insert into param_page_description values
('scotben', 'simple-2026a', 'SimpleParams', 'Basic Set of SB Parameters' ),
('scotben', 'simple-2026a', 'BIParams','Basic Income Simulation Parameters'),
('scotben', 'simple-2026a', 'RunSettings',  'Default Run Settings' );

create table run_params(
    user_id bigint not null,
    model_name char(20) not null default 'scotben',
    model_edition char(24) not null default 'simple-2026a',
    run_id integer not null,
    name char(30) not null,
    data text,
    errors text,
    primary key( user_id, run_id, model_name, model_edition, name ),
    foreign key( user_id, run_id, model_name, model_edition ) references runs on delete cascade on update cascade,
    foreign key( model_name, model_edition, name) references param_page_description );

create table result_description(
    model_name char(20) not null default 'scotben',
    model_edition char(24) not null default 'simple-2026a',
    datatype char(30) not null default 'json',
    item char(30) not null,
    info text,
    primary key( model_name, model_edition, item, datatype ),
    foreign key( model_name, model_edition) references model_editions );

insert into result_description( model_name, model_edition, item, datatype, info ) values -- note: wrong way round item, datatype
('scotben', 'simple-2026a', 'summary_graphs', 'img', 'A set of four summary graphs'),
('scotben', 'simple-2026a', 'summary_graphs_v2 ', 'img', 'A set of four summary graphs'),
('scotben', 'simple-2026a', 'taxable_graph', 'img', 'Chart of taxable income, in bands, with marginal tax rates.'),
('scotben', 'simple-2026a', 'hbai', 'img', 'Reproduction of the standard HBAI diagram, with income in bands and deciles.'),
('scotben', 'simple-2026a', 'lorenz_curve', 'img', 'A standard Lorenz Curve'),
('scotben', 'simple-2026a', 'lorenz_curve_thumb','img', 'Thumbnail verison of a standard Lorenz Curve'),
('scotben', 'simple-2026a', 'deciles','img', 'Average Gains by income decile.'),
('scotben', 'simple-2026a', 'deciles_thumb', 'img', 'Average Gains by income decile, Thumbnail edition.'),
('scotben', 'simple-2026a', 'metrs_hist', 'img', 'Histogram of Marginal Effective Tax Rates (METRs)'),
('scotben', 'simple-2026a', 'metrs', 'img', 'Bar Chart of Marginal Effective Tax Rates (METRs)'),
('scotben', 'simple-2026a', 'metrs2', 'img', 'Bar Chart of Marginal Effective Tax Rates (METRs)'),
('scotben', 'simple-2026a', 'metrs_hist_thumb', 'img', 'Bar Chart of Marginal Effective Tax Rates (METRs), thumbnail'),

('scotben', 'simple-2026a', 'overall_cost_table', 'html', 'format_overall_cost('),
('scotben', 'simple-2026a', 'costs_table', 'html', 'format_costs_table('),
('scotben', 'simple-2026a', 'hhtype_gl', 'html', 'format_gainlose("By Household Size",summary.gain_lose[2].hhtype_gl ),'),
('scotben', 'simple-2026a', 'ten_gl', 'html', 'format_gainlose("By Tenure Type",summary.gain_lose[2].ten_gl ),'),
('scotben', 'simple-2026a', 'dec_gl', 'html', 'format_gainlose("By Decile",summary.gain_lose[2].dec_gl ),'),
('scotben', 'simple-2026a', 'children_gl', 'html', 'format_gainlose("By Numbers of Children",summary.gain_lose[2].children_gl ),'),
('scotben', 'simple-2026a', 'reg_gl', 'html', 'format_gainlose("By Region",summary.gain_lose[2].reg_gl ),'),
('scotben', 'simple-2026a', 'sfc', 'html', 'format_sfc("SFC Behavioral Corrections", results.behavioural_results[2]),'),
('scotben', 'simple-2026a', 'gain_lose_summary', 'html', 'format_gain_lose_table_v2( summary.gain_lose[2] ),'),
('scotben', 'simple-2026a', 'inequality_summary', 'html', 'format_ineq_table('),
('scotben', 'simple-2026a', 'metrs_table', 'html', 'format_mr_table( summary.metrs[1], summary.metrs[2] ),'),
('scotben', 'simple-2026a', 'poverty_summary', 'html', 'format_pov_table( summary.poverty[1],'),
('scotben', 'simple-2026a', 'poverty_transitions', 'html', 'format_pov_transitions( summary.povtrans_matrix[2]),'),
('scotben', 'simple-2026a', 'run_settings_summary', 'html', 'format_run_settings_summary( settings ),'),
('scotben', 'simple-2026a', 'detailed_costs', 'html', 'costs_frame_to_table(detailed_cost_dataframe('),

('scotben', 'simple-2026a', 'overall_cost_table', 'typst', 'format_overall_cost('),
('scotben', 'simple-2026a', 'costs_table', 'typst', 'format_costs_table('),
('scotben', 'simple-2026a', 'hhtype_gl', 'typst', 'format_gainlose("By Household Size",summary.gain_lose[2].hhtype_gl ),'),
('scotben', 'simple-2026a', 'ten_gl', 'typst', 'format_gainlose("By Tenure Type",summary.gain_lose[2].ten_gl ),'),
('scotben', 'simple-2026a', 'dec_gl', 'typst', 'format_gainlose("By Decile",summary.gain_lose[2].dec_gl ),'),
('scotben', 'simple-2026a', 'children_gl', 'typst', 'format_gainlose("By Numbers of Children",summary.gain_lose[2].children_gl ),'),
('scotben', 'simple-2026a', 'reg_gl', 'typst', 'format_gainlose("By Region",summary.gain_lose[2].reg_gl ),'),
('scotben', 'simple-2026a', 'sfc', 'typst', 'format_sfc("SFC Behavioral Corrections", results.behavioural_results[2]),'),
('scotben', 'simple-2026a', 'gain_lose_summary', 'typst', 'format_gain_lose_table_v2( summary.gain_lose[2] ),'),
('scotben', 'simple-2026a', 'inequality_summary', 'typst', 'format_ineq_table('),
('scotben', 'simple-2026a', 'metrs_table', 'typst', 'format_mr_table( summary.metrs[1], summary.metrs[2] ),'),
('scotben', 'simple-2026a', 'poverty_summary', 'typst', 'format_pov_table( summary.poverty[1],'),
('scotben', 'simple-2026a', 'poverty_transitions', 'typst', 'format_pov_transitions( summary.povtrans_matrix[2]),'),
('scotben', 'simple-2026a', 'run_settings_summary', 'typst', 'format_run_settings_summary( settings ),'),
('scotben', 'simple-2026a', 'detailed_costs', 'typst', 'costs_frame_to_table(detailed_cost_dataframe('),

('scotben', 'simple-2026a', 'headline_figures','json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'quantiles', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'quantiles_df', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'deciles', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'deciles_df', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'income_summary', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'poverty', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'inequality', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'metrs', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'metrs_df', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'child_poverty', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'ten_gl', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'dec_gl', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'reg_gl', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'children_gl', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'hhtype_gl', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'poverty_lines', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'short_income_summary', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'very_short_income_summary', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'income_hists', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'income_hists_df', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'taxable_income_hists', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'povtrans_matrix', 'json', 'Desciption Goes Here'),
('scotben', 'simple-2026a', 'povtrans_matrix_df', 'json', 'Desciption Goes Here');

--
-- create table run_results(
--     user_id bigint not null,
--     model_name char(20) not null default 'scotben',
--     model_edition char(24) not null default 'simple-2026a',
--     run_id integer not null,
--     item char(30) not null,
--     datatype char(30) not null default 'json',
--     data text,
--     primary key( user_id, run_id, model_name, model_edition, item, datatype ),
--     foreign key( user_id, run_id, model_name, model_edition ) references runs on delete cascade on update cascade,
--     foreign key( model_name, model_edition, item, datatype ) references result_description );
--

create table run_results_cache(
    model_name char(20) not null default 'scotben',
    model_edition char(24) not null default 'simple-2026a',
    param_hash bigint not null,
    datatype char(30) not null default 'json',
    item char(30) not null,
    data text,
    primary key( model_name, model_edition, param_hash, item, datatype ),
    foreign key( model_name, model_edition, item, datatype ) references result_description );
