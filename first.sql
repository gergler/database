drop table if exists project, task, client;

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

select *
from task;

select name, surname, department
from client;

select login, email
from client;

select *
from task
where priority > 50;

select creator, responsible
from task
where responsible is not null;

select DISTINCT creator, responsible
from task
where responsible is not null;

select header, creator, responsible
from task
where creator != 'petrova'
  and (responsible in ('ivanova', 'berkut'));

select *
from task
where responsible like '%kosatka%'
  and data_beginning between '%2016-01-01%' and '%2016-01-03%';

select tsk.header, tsk.creator, tsk.responsible, clnt.department
from task tsk,
     client clnt
where tsk.responsible like '%petrova%'
  and tsk.creator = clnt.login
  and clnt.department in ('бухгалтерия', 'администрация');

-- select *
-- from task
-- where responsible is NULL;
update task
set responsible = 'petrova'
where responsible is NULL;

drop table if exists task2;
create table task2 as
select *
from task;

select *
from client
where name not like ('%а')
  and surname not like ('а%');

select *
from client
where login like ('p%')
  and login like ('%r%');
