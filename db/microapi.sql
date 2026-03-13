-- psql -h /var/run/postgresql/ -U postgres
-- pg_lsclusters

drop database microapi;
create database microapi;
\c microapi

create table users(
    username char(30) not null,
    email text default '',
    password text default '',
    created timestamp,
    is_temp boolean default true,
    primary key(username));
insert into users values
( 'default', '', md5('anything'), now(), false ),
( 'archive', '', md5('anything'), now(), false );

create table models(
    model_name char(20) not null primary key,
    description text );
insert into models values( 'scotben', '');

create table model_versions(
    model_name char(20) not null,
    model_version char(12) not null default '0.17',
    description text,
    primary key( model_name, model_version ),
    foreign key( model_name ) references models on delete cascade );
insert into model_versions values('scotben', '0.17','');

create table runs(
    username char(30) not null default 'default',
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17',
    run_id char(32) not null, -- actually, a uuid
    submission timestamp,
    is_displayed boolean default false,
    is_edited boolean default false,
    primary key( username, run_id, model_name, model_version ),
    foreign key( username ) references users on delete cascade,
    foreign key( model_name, model_version) references model_versions );

create table run_state(
    username char(30) not null default 'default',
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17',
    run_id char(32) not null, -- actually, a uuid
    thread_no int default 1,
    phase text not null,
    completed integer default 0,
    todo integer,
    primary key( username, run_id, model_name, model_version, thread_no ),
    foreign key( username, run_id, model_name, model_version) references runs );

create table param_page_description(
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17',
    name  char(30) not null,
    info text,
    primary key( model_name, model_version, name ),
    foreign key( model_name, model_version) references model_versions );

create table run_params(
    username char(30) not null default 'default',
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17',
    run_id char(32) not null,
    name char(30) not null,
    data text,
    primary key( username, run_id, model_name, model_version, name ),
    foreign key( username, run_id, model_name, model_version ) references runs on delete cascade on update cascade,
    foreign key( model_name, model_version, name) references param_page_description );

create table result_description(
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17',
    item char(30) not null,
    datatype char(30) not null default 'json',
    info text,
    primary key( model_name, model_version, item, datatype ),
    foreign key( model_name, model_version) references model_versions );

insert into result_description values
-- graphics
('scotben', '0.17', 'summmary_graphs', 'svg', 'draw_summary_graphs( settings, results, summary ),'),
('scotben', '0.17', 'summary_graphs_v2 ', 'svg', 'draw_summary_graphs_v2( settings, results, summary ),'),
('scotben', '0.17', 'taxable_graph ', 'svg', 'draw_taxable_graph( settings, results, summary, sys ),'),
('scotben', '0.17', 'hbai ', 'svg', 'draw_hbai_graphs( settings, results, summary ),'),
('scotben', '0.17', 'lorenz_curve = draw_lorenz_curve( summary.quantiles[1][:,1], summary.quantiles[1][:,2], summary.quantiles[2][:,2]; thumbnail', 'svg', 'false ),'),
('scotben', '0.17', 'lorenz_curve_thumb = draw_lorenz_curve( summary.quantiles[1][:,1], summary.quantiles[1][:,2], summary.quantiles[2][:,2]; thumbnail', 'svg', 'false ),'),
('scotben', '0.17', 'deciles = draw_deciles_barplot( summary; thumbnail', 'svg', 'false ),'),
('scotben', '0.17', 'deciles_thumb = draw_deciles_barplot( summary; thumbnail', 'svg', 'true ),'),
('scotben', '0.17', 'metrs_hist = draw_metrs_hist( results; thumbnail', 'svg', 'false ),'),
('scotben', '0.17', 'metrs ', 'svg', 'draw_metrs( settings, results ),'),
('scotben', '0.17', 'metrs2 ', 'svg', 'draw_metrs2( settings, results ),'),
('scotben', '0.17', 'metrs_hist_thumb = draw_metrs_hist( results; thumbnail', 'svg', 'true ))'),
-- tables
('scotben', '0.17', 'overall_cost_table ', 'html'', 'format_overall_cost('),
('scotben', '0.17', 'costs_table ', 'html'', 'format_costs_table('),
('scotben', '0.17', 'hhtype_gl ', 'html'', 'format_gainlose("By Household Size",summary.gain_lose[2].hhtype_gl ),'),
('scotben', '0.17', 'ten_gl ', 'html'', 'format_gainlose("By Tenure Type",summary.gain_lose[2].ten_gl ),'),
('scotben', '0.17', 'dec_gl ', 'html'', 'format_gainlose("By Decile",summary.gain_lose[2].dec_gl ),'),
('scotben', '0.17', 'children_gl ', 'html'', 'format_gainlose("By Numbers of Children",summary.gain_lose[2].children_gl ),'),
('scotben', '0.17', 'reg_gl ', 'html'', 'format_gainlose("By Region",summary.gain_lose[2].reg_gl ),'),
('scotben', '0.17', 'sfc ', 'html'', 'format_sfc("SFC Behavioral Corrections", results.behavioural_results[2]),'),
('scotben', '0.17', 'gain_lose_summary ', 'html'', 'format_gain_lose_table_v2( summary.gain_lose[2] ),'),
('scotben', '0.17', 'inequality_summary ', 'html'', 'format_ineq_table('),
('scotben', '0.17', 'metrs_table ', 'html'', 'format_mr_table( summary.metrs[1], summary.metrs[2] ),'),
('scotben', '0.17', 'poverty_summary ', 'html'', 'format_pov_table( summary.poverty[1],'),
('scotben', '0.17', 'poverty_transitions ', 'html'', 'format_pov_transitions( summary.povtrans_matrix[2]),'),
('scotben', '0.17', 'run_settings_summary ', 'html'', 'format_run_settings_summary( settings ),'),
('scotben', '0.17', 'detailed_costs ', 'html'', 'costs_frame_to_table(detailed_cost_dataframe('),
('scotben', '0.17', 'headline_figures','json', 'Desciption Goes Here'),

('scotben', '0.17', 'quantiles', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'quantiles_df', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'deciles', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'deciles_df', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'income_summary', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'poverty', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'inequality', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'metrs', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'metrs_df', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'child_poverty', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'gain_lose', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'poverty_lines', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'short_income_summary', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'very_short_income_summary', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'income_hists', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'income_hists_df', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'taxable_income_hists', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'povtrans_matrix', 'json', 'Desciption Goes Here'),
('scotben', '0.17', 'povtrans_matrix_df', 'json', 'Desciption Goes Here');


create table run_results(
    username char(30) not null default 'default',
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.17',
    run_id char(32) not null,
    item char(30) not null,
    datatype char(30) not null default 'json',
    data text,
    primary key( username, run_id, model_name, model_version, item, datatype ),
    foreign key( username, run_id, model_name, model_version ) references runs on delete cascade on update cascade,
    foreign key( model_name, model_version, item, datatype ) references result_description );
