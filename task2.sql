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
-- cost - затрачено/ mark - оценка, сколько нужно затратить
select login                                          id_executor,
       (sum(mark - cost) + abs(sum(mark - cost))) / 2 "-",
       (sum(cost - mark) + abs(sum(cost - mark))) / 2 "+"
from client,
     task
where client.login = responsible
group by login;

select login id_executor, sum(b.over) "-", sum(a.undo) "+"
from client,
     (select (mark - cost) as undo, responsible from task) as a,
     (select (cost - mark) as over, responsible from task) as b
where client.login = a.responsible
  and a.responsible = b.responsible
group by login;

--4

    (select creator, responsible from task where creator > task.responsible);

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

select sum(pg_column_size(char_tbl.str)) "char", sum(pg_column_size(varchar_tbl.str)) "varchar"
from char_tbl,
     varchar_tbl;

--7

select responsible, max(priority)
from task
group by responsible;

-------------------------------------

select login, max(priority)
from client,
     task
where task.responsible = client.login
group by login, responsible;

---8

select responsible, sum(mark)
from task
group by responsible, mark
having (mark > (select avg(mark) from task));

--9
drop view if exists table_view;

create view table_view as
select task.responsible,
       count(task.responsible) as amount,

       (select count(compl.responsible)
        from (select responsible from task where (mark - task.cost < 0)) as compl where compl.responsible = task.responsible group by compl.responsible) as complite,

       (select count(delay.responsible)
        from (select responsible from task where (mark - task.cost > 0)) as delay where delay.responsible = task.responsible group by delay.responsible) as delay,

       (select count(opn.responsible)
        from (select responsible from task where (condition = 'открыта')) as opn where opn.responsible = task.responsible group by opn.responsible) as open,

       (select count(cls.responsible)
        from (select responsible from task where (condition = 'закрыта')) as cls where cls.responsible = task.responsible group by cls.responsible) as close,

       (select count(prcs.responsible)
        from (select responsible from task where (condition = 'выполняется')) as prcs where prcs.responsible = task.responsible group by prcs.responsible) as in_process,

       (select sum(tsk_cost.cost) from (select cost, responsible from task) as tsk_cost where tsk_cost.responsible = task.responsible group by tsk_cost.responsible) as sum_cost,

       (select sum(more.dif)
        from (select -1 * (mark - cost) as dif, responsible from task where (mark - task.cost) < 0) as more where more.responsible = task.responsible group by more.responsible) as mark_cost,

       (select sum(less.dif)
        from (select -1 * (cost - mark) as dif, responsible from task where (mark - cost) > 0) as less where less.responsible = task.responsible group by less.responsible) as cost_mark,

       (select avg(priority) from (select priority, responsible from task) as average where average.responsible = task.responsible group by average.responsible)
from task
group by responsible;
--10

--inserted
select login
from client
where login in (select responsible from task where priority > 80);

--simple
select task.header, project.header
from task,
     project
where task.header = project.header;

--relation
select login, department
from client
where login in (select responsible from task where client.department = 'администрация');
