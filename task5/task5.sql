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
select pg_sleep(20);
--выполнится по одному разу для каждой строки набора данных
--from - функция выполнится всего один раз и общее время исполнения будет около N секунд

--transaction 1
update lock1
set name = 'Nesti'
where id = 2;
select pg_sleep(20);
-- process 1 tries to acquire an exclusive lock, but process 2
-- already holds the lock for the record with id = 2
-- process 1 needs to wait till process 2's transaction ends

--transaction 2
begin;
update lock1
set name = 'Fanta'
where id = 2;
-- both process 1 and 2 acquired an exclusive lock in
-- their transactions. The lock will be released when
-- the transactions finishes

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

drop function if exists func() cascade;

--PostgreSQL functions is running inside outer transaction,
--and this outer transaction should be committed or rollback outside

create function func() returns void as
$$
begin
    --transaction begin diff from code block
    insert into users values (1, 'Lola');
    insert into users values (2, 'Cat');
    insert into users values (3, 'Ken');
exception
    when others then rollback;
end;
$$
    language plpgsql;

select func();

insert into users
values (4, 'Lola');

select *
from users;

-----------------------------------------------------------------------

begin;
insert into users
values (1, 'Tora');
savepoint my_savepoint;
insert into users
values (2, 'Cat');
rollback to savepoint my_savepoint;
insert into users
values (3, 'Ken');
end;

insert into users
values (4, 'Lola');

select *
from users;

------------------------------------------------------------------------
begin transaction;
insert into users
values (1, 'Lola');
savepoint my_savepoint;
insert into users
values (2, 'Cat');
rollback to my_savepoint;
insert into users
values (3, 'Ken');
commit;
end;

select *
from users;

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
                       select (order_time)
                       from Orders
                       where (order_time) < '2021-06-01 0:0:0'
                       order by order_time
                   )
select *
from r;
