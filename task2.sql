drop table if exists project, task, client cascade;

drop table task cascade;

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
    task_num       varchar unique,
    creator        varchar,
    responsible    varchar,
    priority       integer,
    description    varchar,
    condition      varchar check (condition in ('новая', 'закрыта', 'выполняется', 'переоткрыта')) not null,
    data_beginning date,
    mark           integer,
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
values ('СС.Коннект', '1', 'makenroy', 'belova', 30, 'закрыта', '2015-02-23', 56, 56),
       ('РТК', '8', 'kosatka', 'petrova', 10, 'выполняется', '2016-01-31', 31, 78),
       ('Демо-Сибирь', '3', 'ivanova', 'berkut', 87, 'закрыта', '2015-05-11', 128, 192),
       ('МВД-онлайн', '2', 'kosatka', 'drozd', 117, 'закрыта', '2015-05-22', 94, 94),
       ('Поддержка', '6', 'petrova', 'kosatka', 60, 'выполняется', '2015-04-07', 48, 90),
       ('Демо-Сибирь', '4', 'ivanova', 'kosatka', 55, 'выполняется', '2016-01-03', 100, 100),
       ('РТК', '7', 'drozd', 'petrova', 90, 'новая', '2016-10-20', 50, NULL),
       ('Поддержка', '5', 'petrova', 'makenroy', 20, 'переоткрыта', '2015-04-13', 66, 55);

-- 1

select client.login, avg(task.priority) as average
from client,
     task
where task.responsible = client.login
group by login
order by average desc
limit 3;

--2

select concat(count(task_num), ' - MONTH ', extract(MONTH from data_beginning), ' - CREATOR ', login) as status
from task,
     client
where task.creator = client.login
  and data_beginning is not null
  and extract(YEAR from data_beginning) = 2015
group by client.login, extract(MONTH from data_beginning);

--3

select login, sum(over.cost - over.mark), sum(undo.mark - undo.cost)
from client,
     task over,
     task undo
where client.login = over.responsible
  and over.responsible = undo.responsible
  and over.mark < over.cost
  and undo.mark > undo.cost
group by login;

select login, sum(a.undo), sum(b.over)
from client,
     (select (mark - cost) as undo, responsible from task where mark > cost) as a,
     (select (cost - mark) as over, responsible from task where mark < cost) as b
where client.login = a.responsible
and a.responsible = b.responsible
group by login;

--4

     select creator,
     responsible from task
group by creator, responsible;

--5

select login
from client
order by length(login) desc
limit 1;

--6
drop table if exists char_tbl, varchar_tbl;

create table char_tbl
(
    str char(32)
);

create table varchar_tbl
(
    str varchar(32)
);

insert into char_tbl
values ('HELLO WORLD');
insert into varchar_tbl
values ('HELLO WORLD');

select sum(pg_column_size(char_tbl.str)), sum(pg_column_size(varchar_tbl.str))
from char_tbl,
     varchar_tbl;

--7

select responsible, max(priority)
from task
group by responsible;

select login, max(priority)
from client,
     task
where task.responsible = client.login
group by login, responsible;

--8

select responsible, sum(mark)
from task,
     (select avg(mark) from task) as average
where task.mark > average.avg
group by responsible, average.avg;

--9
drop view if exists counter, complete, delayed;

create view counter as
select task.responsible,
       count(task.responsible)
from task
group by task.responsible;


create view complete as
select responsible,
       count(responsible)
from task
where cost <= task.mark
group by responsible;


create view delayed as
select responsible,
       count(responsible)
from task
where task.cost > task.mark
group by responsible;

--10

--inserted
select task.header, client.login, task.responsible
from client,
     task
where client.login = task.creator;

--simple
select task.header, project.header
from task,
     project
where task.header = project.header;

--relation
select login
from client
where login in (select responsible from task where priority > 80);
