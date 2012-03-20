BEGIN TRANSACTION;
CREATE TABLE firsttable (
id integer primary key,
intfield integer,
charfield char(10),
varfield varchar(100)
);
INSERT INTO "firsttable" VALUES(1,1,'aaa','This is the first row');
INSERT INTO "firsttable" VALUES(2,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(3,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(4,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(5,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(6,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(7,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(8,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(9,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(10,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(11,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(12,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(13,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(14,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(15,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(16,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(17,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(18,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(19,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(20,1,'aaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO "firsttable" VALUES(21,9999,'aaa','This is the row with the biggest int');
INSERT INTO "firsttable" VALUES(22,0,'aaa','This is the row with the smallest int');
INSERT INTO "firsttable" VALUES(23,1,'bbb','aaaaaaaaaaaaaaaaaaaaaaaaaaaa');
CREATE TABLE secondtable(
id integer primary key,
firstableid integer,
charfield char(10),
foreign key (firstableid) references firsttable(id)
);
INSERT INTO "secondtable" VALUES(1,1,'bbb');
INSERT INTO "secondtable" VALUES(2,1,'bbb');
INSERT INTO "secondtable" VALUES(3,1,'bbb');
INSERT INTO "secondtable" VALUES(4,1,'bbb');
INSERT INTO "secondtable" VALUES(5,1,'bbb');
INSERT INTO "secondtable" VALUES(6,1,'bbb');
INSERT INTO "secondtable" VALUES(7,1,'bbb');
INSERT INTO "secondtable" VALUES(8,1,'bbb');
INSERT INTO "secondtable" VALUES(9,1,'bbb');
INSERT INTO "secondtable" VALUES(10,1,'bbb');
INSERT INTO "secondtable" VALUES(11,2,'aaa');
INSERT INTO "secondtable" VALUES(12,3,'aaa');
INSERT INTO "secondtable" VALUES(13,4,'aaa');
CREATE TABLE usr(
id serial primary key
);
CREATE TABLE bookmark(
id serial primary key,
usr integer,
foreign key (usr) references usr(id)
);
CREATE TABLE composed_key(
    id1 int,
    id2 int,
    value varchar(32),
    primary key (id1, id2)
);
INSERT INTO "composed_key" VALUES(1,1,'bbb');

COMMIT;
