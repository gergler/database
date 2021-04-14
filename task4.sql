----------------------------------------------4
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
    task_num       varchar unique,
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
values ('СС.Коннект', '1', 'makenroy', 'belova', 30, 'закрыта', '2015-02-23', 'год', 2920),
       ('РТК', '8', 'kosatka', 'petrova', 10, 'выполняется', '2016-01-31', 'месяц', NULL),
       ('Демо-Сибирь', '3', 'ivanova', 'berkut', 87, 'закрыта', '2015-05-11', '8 месяцев', 1920),
       ('МВД-онлайн', '2', 'kosatka', 'drozd', 117, 'закрыта', '2015-05-22', '8 месяцев', 1920),
       ('Поддержка', '6', 'petrova', NULL, 60, 'выполняется', '2016-06-07', 'год', NULL),
       ('Демо-Сибирь', '4', 'ivanova', 'kosatka', 55, 'выполняется', '2016-01-03', '2 года', NULL),
       ('РТК', '7', 'drozd', NULL, 90, 'новая', '2016-10-20', '3 месяца', NULL),
       ('Поддержка', '5', 'petrova', 'makenroy', 20, 'переоткрыта', '2015-04-13', '5 месяцев', NULL);

--1

--FULL OUTER JOIN
select *
from task t
         full outer join client c on t.responsible = c.login
where c.login is null
   or t.responsible is null;

select header, creator, responsible
from task t
         full outer join client c on t.responsible = c.login;

--INNER JOIN
select header, creator, responsible
from task t
         inner join client c on t.responsible = c.login;

--LEFT OUTER JOIN
select login
from client c
         left outer join task t on t.responsible = c.login;

select login
from client c
         left outer join task t on t.responsible = c.login
where t.responsible is null;

--RIGHT OUTER JOIN
select login
from task t
         right outer join client c on t.responsible = c.login;

select login
from task t
         right outer join client c on t.responsible = c.login
where t.responsible is null;

--2
SELECT task_num, header
FROM task As out
WHERE priority = (SELECT MAX(priority)
                  FROM task As int
                  WHERE int.creator = out.creator);

select t1.task_num, t1.header
from task as t1
         right join (select creator, max(priority) as t from task group by creator) as t2 on t1.priority = t2.t
    and t1.creator = t2.creator;

--3
--IN
select login
from client
where login in (select responsible from task where responsible is not null);

--простое объединение (объединение по условию)
select c.login
from client as c, task as t
where t.responsible = c.login and responsible is not null;

--JOIN
select c.login
from client as c
         left outer join task t on c.login = t.responsible
where t.responsible is not null;

--4
select creator, responsible
from task
where responsible is not null
union
select creator, responsible
from task
where responsible is not null;

(select creator, responsible from task where creator > task.responsible) union
(select creator,  responsible from task where creator < task.responsible) union
(select creator, responsible from task where creator = task.responsible);

--5
SELECT p.header, t.header
FROM task as t,
     project as p;

select p.header, t.header
from task as t
         join
     project as p on true;


