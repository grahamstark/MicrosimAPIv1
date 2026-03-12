-- psql -h /var/run/postgresql/ -U postgres

drop database microapi;
create database microapi;
\c microapi


create table users(
    username char(20) not null,
    email text,
    password text,
    creation timestamp,
    is_temp boolean default true,
    primary key(username));
insert into users values( 'default', '', md5('anything'), now(), false ) ;

create table models(
    model_name char(20) not null primary key,
    description text );
insert into models values( 'scotben', '');

create table model_versions(
    model_name char(20) not null,
    model_version decimal(4,2) default 0.10,
    description text,
    primary key( model_name, model_version ),
    foreign key( model_name ) references models on delete cascade );
insert into model_versions values('scotben',0.10,'');

create table sessions(
    username char(20) not null default 'default',
    session_id serial,
    creation_time timestamp,
    primary key( username, session_id),
    foreign key( username ) references users on delete cascade);

create table runs(
    username char(20) not null default 'default',
    model_name char(20) not null default 'scotben',
    model_version decimal(4,2) not null default 0.10,
    session_id integer not null,
    run_id serial,
    phase text not null,
    completed integer default 0,
    todo integer,
    submission timestamp,
    params_json text not null,
    settings_json text not null,
    primary key( username, session_id, run_id, model_name, model_version ),
    foreign key( username, session_id ) references sessions on delete cascade,
    foreign key( model_name, model_version) references model_versions );

create table cached_results(
    params_json text not null,
    settings_json text not null,
    result_type char(20) not null,
    model_name char(20) not null default 'scotben',
    model_version decimal(4,2) not null default 0.10,
    result text,
    primary key( params_json, settings_json, model_version),
    foreign key( model_name, model_version) references model_versions on delete cascade)
