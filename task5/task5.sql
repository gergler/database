--1
drop table if exists lock1;

create table lock1
(
    id   int,
    name varchar(10)
);

insert into lock1
values (1, 'Coca Cola'),
       (2, 'Pepsi');

--transaction 1
begin;
update lock1
set name = 'Sprite'
where id = 1;

--transaction 2
begin;
update lock1
set name = 'Fanta'
where id = 2;
-- both process 1 and 2 acquired an exclusive lock in
-- their transactions. The lock will be released when
-- the transactions finishes

--transaction 1
update lock1
set name = 'Nesti'
where id = 2;
-- process 1 tries to acquire an exclusive lock, but process 2
-- already holds the lock for the record with id = 2
-- process 1 needs to wait till process 2's transaction ends

--transaction 2
update lock1
set name = 'Milkis'
where id = 1;
-- process 2 tries to acquire an exclusive lock, but process 1
-- already holds the lock for the record with id = 1
-- process 2 needs to wait till process 1's transaction ends

-- at this point process 1 is waiting for process 2,
-- and process 2 is waiting for process 1
-- a deadlock has occurred

--2
--SAVEPOINT, COMMIT, ROLLBACK
drop table if exists users;

create table users
(
    id   int,
    name varchar(12)
);

drop function if exists func();

create function func() returns int as
$$
begin
    insert into users
    values (1, 'Tora');
    savepoint my_savepoint;
    insert into users
    values (2, 'Cat');
    rollback to savepoint my_savepoint;
    insert into users
    values (3, 'Ken');
    return 0;
exception
    when others then return -1;
end;
$$
    language plpgsql;

select *
from func();

insert into users
values (4, 'Lola');

select *
from users;

-- begin;
-- insert into users
-- values (1, 'Tora');
-- savepoint my_savepoint;
-- insert into users
-- values (2, 'Cat');
-- rollback to savepoint my_savepoint;
-- insert into users
-- values (3, 'Ken');
-- end;
--
-- insert into users
-- values (4, 'Lola');
--
-- select *
-- from users;

-- circle
drop table if exists ID1;

create table ID1
(
    id1 serial primary key
);

drop function if exists delete1();

create function delete1() returns trigger as
$$
begin
    delete from ID1 where id1 = old.id1;
    return old;
end;
$$
    language plpgsql;

drop trigger if exists trigger1 on id1;

create trigger trigger1
    before delete
    on ID1
    for each row
execute procedure delete1();

insert into ID1
values (1);

delete
from ID1
where id1 = 1;

select *
from ID1;

--recursion
drop function if exists recursive(n int, f int);

create or replace function recursive(n int, f int)
    returns table
            (
                number    int,
                factorial int
            )
as
$$
begin
    return query select n, f;
    if n < 5 then
        return query select * from recursive(n + 1, f * (n + 1));
    end if;
end;
$$
    language plpgsql;

select *
from recursive(0, 1);

----------------------------------------------------------------------------------------

-- Алгоритм примерно такой:
-- 1)   Берем стартовые данные
-- 2)   подставляем в «рекурсивную» часть запроса.
-- 3)   смотрим что получилось:
-- 3.1) если выхлоп рекурсивной части не пустой, то добавляем его в результирующую выборку,
-- а также используем этот выхлоп как данные для следующего вызова рекурсивной части, т.е. goto 2
-- 3.2) если пусто, то завершаем обработку

drop table if exists recurs;

create table recurs
(
    child_id  int not null primary key,
    parent_id int references recurs (child_id),
    name      varchar(10)
);

insert into recurs (child_id, parent_id, name)
values (1, null, 'Cat'),
       (2, 1, 'Lala'),
       (3, 1, 'Jhon'),
       (4, 2, 'Jin'),
       (5, 4, 'Jojo'),
       (6, 4, 'Gera'),
       (7, 5, 'Tusya'),
       (8, 5, 'Ira'),
       (9, 6, 'Musya');

with recursive rec as (
    select child_id, parent_id, name
    from recurs
    where parent_id = 4
    union
    select recurs.child_id, recurs.parent_id, recurs.name
    from recurs
             join rec on recurs.parent_id = rec.child_id
)

select *
from rec;

--3
drop table if exists Orders;

create table Orders
(
    id         int,
    order_time timestamp
);

insert into Orders(id, order_time)
values (1, '2021-03-22 13:21:11'),
       (2, '2021-11-07 18:09:27'),
       (3, '2021-05-19 14:10:38'),
       (4, '2021-10-01 10:49:31'),
       (5, '2021-09-09 9:17:01'),
       (6, '2021-01-28 9:12:11'),
       (7, '2021-07-16 15:19:21');

with recursive r as
                   (
                       select ('2021-02-01 00:00:00')::timestamp::date
                       union
                       select (order_time)::timestamp::date
                       from Orders
                       where (order_time + interval '1' day)::TIMESTAMP::date < '2021-09-30'
                   )
select *
from r;

--4
drop table if exists files, nodes cascade;

create table nodes
(
    id   serial primary key,
    path varchar
);

create table files
(
    id       serial,
    nodeID   int,
    name     varchar,
    depth    int,
    size     int,
    created  date,
    written  date,
    modified date,
    primary key (id, nodeID, name),
    foreign key (nodeID) references nodes (id)
);

insert into nodes (path)
values ('user'),
       ('local'),
       ('server');

insert into files(nodeID, name, depth, size, created, written, modified)
values (1, 'pin', 1, 100, '2021-05-27', '2021-05-27', '2021-05-27'),
       (2, 'homework', 1, 80, '2021-03-10', '2021-03-10', '2021-03-10'),
       (2, 'tasks', 0, 70, '2021-04-10', '2021-04-10', '2021-05-10'),
       (3, 'article', 0, 200, '2021-07-10', '2021-07-10', '2021-07-17'),
       (1, 'app data', 0, 200, '2021-03-10', '2021-03-10', '2021-03-17');

-------------------------------------------------------------------------------------

drop function if exists id_file(fpath varchar, fdepth int);

create function id_file(fpath varchar, fdepth int) returns int as
$$
declare
    p int;
    r int;
begin
    if fpath = '' then
        return fdepth;
    end if;
    select position('/' in fpath) into p;
    if p = 0 then
        select id from files where files.depth = fdepth and files.name = fpath limit 1 into r;
        return coalesce(r, -1);
    else
        select id
        from files
        where files.depth = fdepth
          and files.name = (select substring(fpath, 1, p, -1))
        limit 1
        into r;
        if r is null then
            return -1;
        else
            return id_file((select substring(fpath, p + 1)), r);
        end if;
    end if;
end;
$$
    language plpgsql;

select *
from id_file('pin', 1);

----------------------------------------------------------------------------------------

drop function if exists create_file(fname varchar, fdir varchar, fnode int, fsize int);

create function create_file(fname varchar, fdir varchar, fnode int, fsize int) returns varchar as
$$
declare
    d int;
begin
    if fname like '%/%' then
        return 'invalid file name';
    end if;
    select id_file(fdir, 0) into d;
    if d = 0 and not exists(select * from files where files.id = d) then
        return 'parent dir does not exist';
    elsif exists(select * from files where files.name = fname and files.depth = d) then
        return 'file already exists';
    else
        if d < 0 then d = d * (-1); end if;
        insert into files(nodeID, name, depth, size, created, written, modified)
        values (fnode, fname, d, fsize, now(), now(), now());
        return 'file created';
    end if;
end;
$$ language plpgsql;

select *
from create_file('tasks4', 'tasks', 2, 10);
select *
from files;

----------------------------------------------------------------------

drop function if exists del_file(fname varchar, fdepth int);

create function del_file(fname varchar, fdepth int) returns varchar as
$$
declare
    i int;
begin
    select id_file(fname, fdepth) into i;
    if i = -1 then
        return 'file does not exist';
    elsif ((select count(*) from files where depth = i) <> 0) then
        return 'file have depends';
    else
        delete from files cascade where id = i;
        return 'file deleted';
    end if;
end;
$$
    language plpgsql;

select *
from files;
select *
from del_file('tasks4', 3);

----------------------------------------------------------------------------

drop function if exists change_name_file(fname varchar, fdepth int, newfname varchar);

create function change_name_file(fname varchar, fdepth int, newfname varchar) returns varchar as
$$
declare
    i int;
begin
    if newfname like '%/%' then
        return 'invalid file name';
    end if;
    select id_file(fname, fdepth) into i;
    if i = -1 then
        return 'file does not exist';
    elsif exists(select *
                 from files
                 where files.name = newfname
                   and files.depth = fdepth) then
        return 'file already exists';
    else
        update files set name = newfname, modified = now() where id = i;
        return 'changed file name';
    end if;
end;
$$
    language plpgsql;

select *
from change_name_file('tasks3', 1, 'new task');
select *
from files;

-----------------------------------------------------------------------------

drop function if exists move_file(fname varchar, fdepth int, newfnode int, newfdepth int);

create function move_file(fname varchar, fdepth int, newfnode int, newfdepth int) returns varchar as
$$
declare
    i int;
    d int;
    n varchar;
begin
    select id_file(fname, fdepth) into i;
    if i = -1 then
        return 'file does not exists';
    elsif exists(
            select * from files where files.name = fname and files.nodeID = newfnode and files.depth = newfdepth) then
        return 'file already exist';
    else
        update files set nodeID = newfnode, depth = newfdepth, modified = now() where id = i;
        return 'moved file';
    end if;
end;
$$ language plpgsql;

select *
from files;
select *
from move_file('new task', 3, 1, 3);
select *
from files;

-------------------------------------------------------------------------------

drop function if exists full_path(fid int);

create function full_path(fid int) returns varchar as
$$
declare
    r files%ROWTYPE;
begin
    if not exists(select * from files where nodeID = (select nodeID from files where id = fid)) then
        return 'file does not exist';
    else
        select * from files where nodeID = (select nodeID from files where id = fid) into r;
        if r.depth = 0 then
            return r.name;
        else
            r.depth = r.depth - 1;
            return concat(full_path(r.depth), '/', r.name);
        end if;
    end if;
end;
$$ language plpgsql;

select *
from files;
select *
from full_path(id_file('pin', 1));

--------------------------------------------------------------------------------------

drop function if exists depth_file(fpath varchar);

create function depth_file(fpath varchar) returns int as
$$
begin
    return length(regexp_replace(fpath, '[^/]', '', 'g'));
end;
$$
    language plpgsql;

select *
from depth_file('a/a/a/');

---------------------------------------------------------------------------------------

drop function if exists find_file(fmask varchar, fdepth int);

create function find_file(fmask varchar, fdepth int) returns setof varchar as
$$
begin
    return query
        select path
        from (select full_path(id) as path from files) as p
        where p.path like fmask
          and (select depth_file(p.path)) < fdepth + 1;
end;
$$
    language plpgsql;

select *
from files;
select *
from find_file('%pin%', 1);

--5
drop table if exists project, task, client cascade;

create table client
(
    name       varchar not null,
    surname    varchar not null,
    department varchar check (department in ('администрация', 'бухгалтерия', 'отдел кадров')),
    login      varchar,
    email      varchar,
    PRIMARY KEY (login)
);

create table project
(
    header         varchar,
    description    varchar,
    data_beginning date not null,
    data_ending    date,
    PRIMARY KEY (header)
);

create table task
(
    header         varchar,
    task_num       int unique,
    creator        varchar,
    responsible    varchar,
    priority       integer,
    description    varchar,
    condition      varchar check (condition in ('новая', 'закрыта', 'выполняется', 'переоткрыта')) not null,
    data_beginning date,
    mark           varchar,
    cost           integer,
    FOREIGN KEY (header) REFERENCES project (header),
    FOREIGN KEY (creator) REFERENCES client (login),
    FOREIGN KEY (responsible) REFERENCES client (login)
);

insert into project (header, data_beginning, data_ending)
values ('РТК', '2016-01-31', NULL),
       ('СС.Коннект', '2015-02-23', '2016-12-31'),
       ('Демо-Сибирь', '2015-05-11', '2016-01-31'),
       ('МВД-онлайн', '2015-05-22', '2016-01-31'),
       ('Поддержка', '2016-06-07', NULL);


insert into client (name, surname, department, login, email)
values ('Артём', 'Касаткин', 'администрация', 'kosatka', 'kosatka@gmail.com'),
       ('София', 'Петрова', 'бухгалтерия', 'petrova', 'petrova@gmail.com'),
       ('Фёдр', 'Дроздов', 'администрация', 'drozd', 'drozd@gmail.com'),
       ('Василина', 'Иванова', 'бухгалтерия', 'ivanova', 'vasilina@gmail.com'),
       ('Алексей', 'Беркут', 'администрация', 'berkut', 'berkut@gmail.com'),
       ('Вера', 'Белова', 'отдел кадров', 'belova', 'belova@gmail.com'),
       ('Алексей', 'Макенрой', 'отдел кадров', 'makenroy', 'makenroy@gmail.com');

insert into task(header, task_num, creator, responsible, priority, condition, data_beginning, mark, cost)
values ('СС.Коннект', 1, 'makenroy', 'belova', 30, 'закрыта', '2015-02-23', 'год', 2920),
       ('РТК', 2, 'kosatka', 'petrova', 10, 'выполняется', '2016-01-31', 'месяц', NULL),
       ('Демо-Сибирь', 3, 'ivanova', 'berkut', 87, 'закрыта', '2015-05-11', '8 месяцев', 1920),
       ('МВД-онлайн', 4, 'kosatka', 'drozd', 117, 'закрыта', '2015-05-22', '8 месяцев', 1920),
       ('Поддержка', 5, 'petrova', NULL, 60, 'выполняется', '2016-06-07', 'год', NULL),
       ('Демо-Сибирь', 6, 'ivanova', 'kosatka', 55, 'выполняется', '2016-01-03', '2 года', NULL),
       ('РТК', 7, 'drozd', NULL, 90, 'новая', '2016-10-20', '3 месяца', NULL),
       ('Поддержка', 8, 'petrova', 'makenroy', 20, 'переоткрыта', '2015-04-13', '5 месяцев', NULL);

---------------------------------------------------------------------------------

drop table if exists task_cache cascade;

create table task_cache
(
    taskID      int,
    modified    timestamp                                                                       not null,
    header      varchar,
    creator     varchar,
    responsible varchar,
    priority    int,
    condition   varchar check (condition in ('новая', 'закрыта', 'выполняется', 'переоткрыта')) not null,
    mark        varchar,
    cost        integer,
    exist       bool,
    foreign key (header) references project (header),
    foreign key (responsible) references client (login),
    foreign key (creator) references client (login)
);

----------------------------------------------------------------------------------

drop trigger if exists modif_tr on task;
drop function if exists modif() cascade;

create function modif() returns trigger as
$$
begin
    if lower(tg_op) = 'insert'
    then
        insert into task_cache(taskID, modified, header, creator, responsible, priority, condition,
                               mark, cost, exist)
        values (new.task_num, now(), new.header, new.creator, new.responsible, new.priority,
                new.condition, new.mark, new.cost, true);
    end if;
    if lower(tg_op) = 'update'
    then
        insert into task_cache(taskID, modified, header, creator, responsible, priority, condition,
                               mark, cost, exist)
        values (new.task_num, now(), new.header, new.creator, new.responsible, new.priority,
                new.condition, new.mark, new.cost, true);
    end if;
    if lower(tg_op) = 'delete'
    then
        insert into task_cache(taskID, modified, header, creator, responsible, priority, condition,
                               mark, cost, exist)
        values (old.task_num, now(), old.header, old.creator, old.responsible, old.priority,
                old.condition, old.mark, old.cost, false);
    end if;
    return new;
end;
$$ language plpgsql;

create trigger modif_tr
    after insert or update or delete
    on task
    for each row
execute procedure modif();

insert into task(header, task_num, creator, responsible, priority, condition, data_beginning, mark, cost)
values ('МВД-онлайн', '19', 'kosatka', 'petrova', 100, 'выполняется', '2015-05-30', '5 месяцев', 1990);

update task
set condition = 'выполняется'
where cost is null;

delete
from task
where cost = 1920;

select *
from task;
select *
from task_cache;

---------------------------------------------------------------------------------------------

drop function if exists history(h varchar, c varchar, r varchar);

create function history(h varchar, c varchar, r varchar) returns setof task_cache as
$$
begin
    return query select * from task_cache where h = header and c = creator and r = responsible;
end;
$$
    language plpgsql;

select *
from history('МВД-онлайн', 'kosatka', 'petrova');

---------------------------------------------------------------------------------------------

drop function if exists revert(tsk_num int);

create function revert(tsk_num int) returns varchar as
$$
declare
    new task_cache%ROWTYPE;
    old task_cache%ROWTYPE;
begin
    select * from task_cache where taskID = tsk_num into new;
    select *
    from task_cache
    where header = new.header
      and creator = new.creator
      and responsible = new.responsible
      and modified <= new.modified
    order by modified desc
    limit 1
    into old;
    if new is null then
        return 'nothing to be update';
    end if;
    if old is null then
        delete
        from task
        where header = new.header
          and creator = new.creator
          and responsible = new.responsible;
        return 'revert failed';
    end if;
    if old.exist and not new.exist then
        insert into task(header, task_num, creator, responsible, priority, condition, mark, cost)
        values (old.header, old.taskID, old.creator, old.responsible, old.priority, old.condition, old.mark, old.cost);
    elsif not old.exist and new.exist then
        delete from task where header = old.header and task_num = old.taskID;
    elsif old.exist and new.exist then
        update task
        set header      = old.header,
            task_num    = old.taskID,
            creator     = old.creator,
            responsible = old.responsible,
            priority    = old.priority,
            mark        = old.mark,
            cost        = old.cost
        where task_num = new.taskID;
    else
        return 'revert failed';
    end if;
    return 'revert succeed';
end;
$$
    language plpgsql;

select *
from task_cache;

update task
set priority = 150
where task_num = 19;

delete
from task
where priority = 150;

select *
from task_cache;

select *
from revert(19);

select *
from task_cache;

select *
from task;
