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
    model_version char(12) not null default '0.10',
    description text,
    primary key( model_name, model_version ),
    foreign key( model_name ) references models on delete cascade );
insert into model_versions values('scotben', '0.10','');

create table sessions(
    username char(30) not null default 'default',
    session_id int not null default 1,
    creation_time timestamp,
    primary key( username, session_id),
    foreign key( username ) references users on delete cascade);

create table runs(
    username char(30) not null default 'default',
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.10',
    session_id integer not null default 1,
    run_id serial,
    phase text not null,
    completed integer default 0,
    todo integer,
    submission timestamp,
    primary key( username, session_id, run_id, model_name, model_version ),
    foreign key( username, session_id ) references sessions on delete cascade,
    foreign key( model_name, model_version) references model_versions );

create table run_params(
    username char(30) not null default 'default',
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.10',
    session_id integer not null default 1,
    run_id int not null,
    name char(30) not null,
    data text,
    primary key( username, session_id, run_id, model_name, model_version, name ),
    foreign key( username, session_id, run_id, model_name, model_version ) references runs on delete cascade on update cascade,
    foreign key( model_name, model_version) references model_versions );

create table run_results(
    username char(30) not null default 'default',
    model_name char(20) not null default 'scotben',
    model_version char(12) not null default '0.10',
    session_id integer not null default 1,
    run_id int not null,
    name char(30) not null,
    datatype char(30) not null default 'json',
    data text,
    primary key( username, session_id, run_id, model_name, model_version, name ),
    foreign key( username, session_id, run_id, model_name, model_version ) references runs on delete cascade on update cascade,
    foreign key( model_name, model_version) references model_versions );
