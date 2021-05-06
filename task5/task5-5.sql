
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

--дата модификации и что было изменено

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
