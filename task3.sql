---------------------------2
--one to one
create table Doctor
(
    DoctorId   int primary key,
    DoctorName varchar(32) not null
);

insert into Doctor(DoctorId, DoctorName)
values (1, 'Ramzi'),
       (2, 'Rashta'),
       (3, 'Koll');

create table Room
(
    DoctorId int primary key,
    RoomId   int unique,
    foreign key (DoctorId) references Doctor (DoctorId)
);

insert into Room(RoomId, DoctorId)
values (101, 1),
       (220, 3);

--one to many
drop table if exists Doctor, Phone;

create table Doctor
(
    DoctorId   int primary key,
    DoctorName varchar(32) not null
);

insert into Doctor(DoctorId, DoctorName)
values (1, 'Ramzi'),
       (2, 'Rashta'),
       (3, 'Koll');

create table Phone
(
    DoctorId int primary key,
    Phone    varchar(32),
    foreign key (DoctorId) references Doctor (DoctorId)
);

insert into Phone(Phone, DoctorId)
values ('89930055078', 1),
       ('6-355-505', 1),
       ('89930999999', 2),
       ('89888899988', 3),
       ('6-355-509', 3);

--many to many
create table Cooker
(
    CookerId   int primary key,
    CookerName varchar(32) not null
);

insert into Cooker(CookerId, CookerName)
values (1, 'Ramzi'),
       (2, 'Rashta'),
       (3, 'Koll');

create table Dish
(
    DishId   int primary key,
    DishName varchar(32) not null
);

insert into Dish(DishId, DishName)
values (1, 'pasta'),
       (2, 'carry'),
       (3, 'cake');

create table CookerDish
(
    CookerId int,
    DishId   int,
    foreign key (CookerId) references Cooker (CookerId),
    foreign key (DishId) references Dish (DishId),
    primary key (CookerId, DishId)
);

----------------------------3
drop table if exists Menu;

create table Menu
(
    SupplierID int primary key,
    Cooker     varchar(32),
    Dishes     varchar(32),
    Compliment varchar(32)
);

insert into Menu(SupplierID, Cooker, Dishes, Compliment)
values (1, 'Ramzi', 'Cake', 'Coffee'),
       (1, 'Rashta', 'Piza', 'Juice, Coffee'),
       (2, 'Rashta', 'Pasta', 'Juice, Coffee'),
       (2, 'Koll', 'Pizza', 'Tea');

update Menu
set Dishes = 'pizza'
where Compliment = 'Juice';

delete
from Menu
where Menu.Dishes = 'Cake';

select SupplierID
from Menu
where Compliment = 'Juice';
----------------------------4

drop table if exists Restaurant;

create table Restaurant
(
    RestaurantId    int primary key,
    CookerName      varchar(32) primary key,
    Pasta           varchar(32),
    Cost            int,
    Delivery        varchar(32),
    Compliment      varchar(32),
    RestaurantPhone varchar(32),
    DelCost         int
);

--1
insert into Restaurant(RestaurantId, CookerName, Pasta, Cost, Delivery)
values (1, 'Ramzi', 'Cheese, Tomato', 300, 'Yandex'),
       (2, 'Rashta', 'Sea cocktail, Cheese', 400, 'Delivery'),
       (1, 'Martin', 'Black', 500, 'Yandex');

insert into Restaurant(RestaurantId, CookerName, Pasta, Cost, Delivery)
values (1, 'Ramzi', 'Cheese', 300, 'Yandex'),
       (1, 'Ramzi', 'Tomato', 300, 'Yandex'),
       (2, 'Rashta', 'Sea cocktail', 400, 'Delivery'),
       (2, 'Rashta', 'Cheese', 400, 'Delivery'),
       (1, 'Martin', 'Black', 500, 'Yandex');

--2
--Compliment->CookerName-->неполная функциональная зависимость

insert into Restaurant(RestaurantId, CookerName, Pasta, Cost, Compliment)
values (1, 'Ramzi', 'Cheese', 320, 'Coffee'),
       (1, 'Ramzi', 'Tomato', 300, 'Coffee'),
       (2, 'Rashta', 'Sea cocktail', 400, 'Tea'),
       (2, 'Rashta', 'Cheese', 420, 'Tea'),
       (1, 'Martin', 'Black', 500, 'Soda');
--

insert into Restaurant(RestaurantId, CookerName, Pasta, Cost, Delivery)
values (1, 'Ramzi', 'Cheese', 300, 'Yandex'),
       (1, 'Ramzi', 'Tomato', 300, 'Yandex'),
       (2, 'Rashta', 'Sea cocktail', 400, 'Delivery'),
       (2, 'Rashta', 'Cheese', 400, 'Delivery'),
       (1, 'Martin', 'Black', 500, 'Yandex');

create table Compliment
(
    CookerName varchar(32) primary key,
    Compliment varchar(32),
    foreign key (CookerName) references Restaurant (CookerName)
);

insert into Compliment(CookerName, Compliment)
values ('Ramzi', 'Coffee'),
       ('Rashta', 'Tea'),
       ('Martin', 'Soda');

--3
--транзитивная зависимость Rest->Del->Cost
insert into Restaurant(RestaurantId, CookerName, Pasta, Cost, Delivery, DelCost)
values (1, 'Ramzi', 'Cheese', 300, 'Yandex', 80),
       (1, 'Ramzi', 'Tomato', 300, 'Yandex', 80),
       (2, 'Rashta', 'Sea cocktail', 400, 'Delivery', 100),
       (2, 'Rashta', 'Cheese', 400, 'Delivery', 100),
       (1, 'Martin', 'Black', 500, 'Yandex', 80);

--

insert into Restaurant(RestaurantId, CookerName, Pasta, Cost, Delivery)
values (1, 'Ramzi', 'Cheese', 300, 'Yandex'),
       (1, 'Ramzi', 'Tomato', 300, 'Yandex'),
       (2, 'Rashta', 'Sea cocktail', 400, 'Delivery'),
       (2, 'Rashta', 'Cheese', 400, 'Delivery'),
       (1, 'Martin', 'Black', 500, 'Yandex');

create table Del
(
    DelName varchar(32) primary key,
    DElCOst int,
    foreign key (DelName) references Restaurant (Delivery)
);

insert into Del
values ('Yandex', 80),
       ('Delivery', 100);

--4
--многозначная зависимость Rest->Cooker, Rest->Del
--составной первичный ключ: {Ресторан, Повар, Доставка}
insert into Restaurant(RestaurantId, CookerName, Delivery)
values (1, 'Ramzi', 'Yandex'),
       (1, 'Martin', 'Yandex'),
       (2, 'Rashta', 'Delivery');

--

create table RestCook
(
    RestaurantId int primary key,
    Cooker       varchar(32)
);

create table RestDel
(
    RestaurantId int primary key,
    Del          varchar(32)
);
