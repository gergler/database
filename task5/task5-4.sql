
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
    path     varchar,
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
values ('comp1'),
       ('comp2'),
       ('comp3');

insert into files(nodeID, path, name, depth, size, created, written, modified)
values (1, 'app_data/shadow/pin', 'pin', 2, 100, '2021-05-27', '2021-05-27', '2021-05-27'),
       (1, 'app_data/app', 'app', 1, 200, '2021-03-10', '2021-03-10', '2021-03-17'),
       (2, 'tasks/homework', 'homework', 1, 80, '2021-03-10', '2021-03-10', '2021-03-10'),
       (2, 'tasks/tasks1', 'tasks1', 1, 70, '2021-04-10', '2021-04-10', '2021-05-10'),
       (3, 'article/coarse0', 'coarse0', 1, 200, '2021-07-10', '2021-07-10', '2021-07-17'),
       (3, 'article/coarse/VME', 'VME', 2, 200, '2021-07-10', '2021-07-10', '2021-07-17');

-------------------------------------------------------------------------------------

drop function if exists depth_file(fpath varchar);

create function depth_file(fpath varchar) returns int as
$$
begin
    return length(regexp_replace(fpath, '[^/]', '', 'g'));
end;
$$
    language plpgsql;

select *
from depth_file('tasks/homework');

----------------------------------------------------------------------------------------

drop function if exists create_file(fname varchar, fpath varchar, fnode int, fsize int);

create function create_file(fname varchar, fpath varchar, fnode int, fsize int) returns int as
$$
begin
    if fname is null and fnode is null and fpath not similar to '%/{1,}' and fsize < 0 then
        return -1;
    end if;
    if exists(select *
              from files
              where files.name = fname
                and files.depth = depth_file(fpath)
                and files.nodeID = fnode) then
        return -1;
    end if;
    insert into files(nodeID, path, name, depth, size, created, written, modified)
    values (fnode, concat(fpath, fname), fname, depth_file(concat(fpath, fname)), fsize, now(), now(), now());
    return 1;
end;
$$ language plpgsql;

select *
from create_file('tasks4', 'tasks/', 1, 10);

select *
from files
order by nodeID;

----------------------------------------------------------------------

drop function if exists del_file(fname varchar, fdepth int, fnode int);

create function del_file(fname varchar, fdepth int, fnode int) returns varchar as
$$
declare
begin
    if ((select count(*) from files where files.depth = fdepth and files.name = fname) <> 1) then
        return 'file have depends';
    else
        delete from files cascade where name = fname and nodeID = fnode and depth = fdepth;
        return 'file deleted';
    end if;
end;
$$
    language plpgsql;

select *
from del_file('tasks4', 1, 1);

select *
from files
order by nodeID;

----------------------------------------------------------------------------

drop function if exists change_name_file(fname varchar, fdepth int, fnode int, newfname varchar);

create function change_name_file(fname varchar, fdepth int, fnode int, newfname varchar) returns varchar as
$$
begin
    if newfname ilike '%/%' then
        return 'invalid file name';
    end if;
    if not exists(select name from files where name = fname and depth = fdepth and nodeID = fnode) then
        return 'file does not exist';
    elsif exists(select * from files where files.name = newfname and files.depth = fdepth and nodeID = fnode) then
        return 'file already exists';
    else
        update files set name = newfname, modified = now() where name = fname and depth = fdepth and nodeID = fnode;
        return 'changed file name';
    end if;
end;
$$
    language plpgsql;

select *
from change_name_file('tasks4', 1, 1, 'new');

select *
from files
order by nodeID;

-----------------------------------------------------------------------------

drop function if exists move_file(fname varchar, fpath varchar, fnode int, newfnode int, newfpath varchar);

create function move_file(fname varchar, fpath varchar, fnode int, newfnode int, newfpath varchar) returns varchar as
$$
declare
begin
    if not exists(select name from files where name = fname and depth = depth_file(fpath) and nodeID = fnode) then
        return 'file does not exist';
    elsif exists(select * from files where files.name = fname and files.nodeID = newfnode and files.depth = depth_file(newfpath)) then
        return 'file already exist';
    else
        update files
        set nodeID = newfnode, depth = depth_file(newfpath), path = concat(newfpath, fname), modified = now()
        where name = fname and nodeID = fnode and depth = depth_file(fpath);
        return 'moved file';
    end if;
end;
$$ language plpgsql;

select *
from files;

select *
from move_file('tasks4', 'tasks/', 1, 3, 'article/coarse/');

select *
from files
order by nodeID;

---------------------------------------------------------------------------------------

drop function if exists copy_file(fname varchar, fpath varchar, fnode int, newfnode int, newfname varchar, newfpath varchar);

create function copy_file(fname varchar, fpath varchar, fnode int, newfnode int, newfname varchar,
                          newfpath varchar) returns varchar as
$$
declare
begin
    if not exists(select name from files where name = fname and depth = depth_file(fpath) and nodeID = fnode) then
        return 'file does not exist';
        elsif exists(select * from files where files.name = fname and files.nodeID = newfnode and files.depth = depth_file(newfpath)) then
        return 'file already exist';
    else
        insert into files(nodeID, path, name, depth, size, created, written, modified)
        values (newfnode, concat(newfpath, newfname), newfname, depth_file(newfpath), (select size from files where name = fname and path = fpath and nodeID = fnode), now(), now());
        return 'copy file';
    end if;
end;
$$ language plpgsql;

select *
from files;

select *
from copy_file('new', 'tasks/', 1, 2, 'tasks2', 'article/');

select *
from files
order by nodeID;

---------------------------------------------------------------------------------------

drop function if exists find_file(fmask varchar, fdepth int);

create function find_file(fmask varchar, fdepth int) returns table("name_" varchar, "nodeID_" int, "path_" varchar, "size_" int) as
$$
begin
    return query
        select name, nodeID, path, size
        from files
        where files.name like fmask
          and (select depth_file(path)) = fdepth;
end;
$$
    language plpgsql;

select *
from files;

select *
from find_file('%%', 2);
