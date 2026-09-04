-- PostgreSQL uses single quotes as string literals.

SELECT 'Hello PostgreSQL';

-- Special commands
-- This will change the connection, which also breaks the preceding transaction status.
-- \c exercises;

SELECT *
FROM cd.facilities;

-- Double quotes tell PostgreSQL it's an identifier, not a keyword.

SELECT "name",
       membercost
FROM cd.facilities;


SELECT *
FROM cd.facilities fc
WHERE fc.membercost > 0;


SELECT facid,
       name,
       membercost,
       monthlymaintenance
FROM cd.facilities
WHERE membercost < monthlymaintenance / 50
    and membercost > 0;

-- String is indxed from 1

SELECT *
FROM cd.facilities
WHERE position('Tennis' IN name) > 0;

-- Row and Array Comparisons.
-- They are not subqueries.

SELECT *
FROM cd.facilities
WHERE facid IN (1,
                5);

-- Array literals is formed of sigle quoted bracket list.

SELECT *
FROM cd.facilities
WHERE facid = Any ('{1, 5}');

-- Conditional expression.

SELECT name,
       CASE
           WHEN monthlymaintenance <= 100 THEN 'cheap'
           ELSE 'expensive'
       END as cost
FROM cd.facilities;

-- PostgreSQL support cross type comparison, which coerces data type into a more compatible type.

SELECT memid,
       surname,
       firstname,
       joindate
FROM cd.members
WHERE joindate >= date '2012-09-01';


SELECT DISTINCT surname
FROM cd.members
ORDER BY surname ASC
LIMIT 10;

-- Combine queries, this is a contrived example.

SELECT DISTINCT surname
FROM cd.members
UNION
SELECT DISTINCT name
FROM cd.facilities;

-- SELECT firstname,
--        surname,
--        joindate
-- FROM cd.members
-- WHERE joindate =
--         (SELECT max(joindate)
--          FROM cd.members);

SELECT firstname,
       surname,
       joindate
FROM cd.members
ORDER BY joindate DESC
LIMIT 1;


SELECT starttime
FROM cd.bookings AS bk
JOIN cd.members AS mem ON bk.memid = mem.memid
WHERE (mem.firstname || ' ' || mem.surname) = 'David Farrell';


SELECT mem.firstname || ' ' || mem.surname AS fullname,
       count(*) AS book_cnt
FROM cd.bookings AS bk
JOIN cd.members AS mem ON bk.memid = mem.memid
GROUP BY fullname,
         bk.memid;

-- Can't collate case_insensitive on UTF-8, can't use LIKE 'tennis%' here, but 'Tennis%' will produce the same result.

SELECT starttime as
start, name
FROM cd.bookings bk
JOIN cd.facilities fac ON bk.facid = fac.facid
WHERE name ~* 'tennis court.*'
    AND starttime >= '2012-09-21'
    AND starttime < '2012-09-22'
ORDER BY starttime;


SELECT DISTINCT lhs.firstname,
                lhs.surname
FROM cd.members lhs
JOIN cd.members rhs ON lhs.memid = rhs.recommendedby
ORDER BY surname,
         firstname;

-- Comparison with NULL must use IS/IS NOT, other comparisons give UNKNOWN, which is false.

SELECT *
FROM cd.members
WHERE recommendedby IS NOT NULL
ORDER BY surname,
         firstname;


SELECT mems.firstname as memfname,
       mems.surname as memsname,
       recommender.firstname as recfname,
       recommender.surname as recsname
FROM cd.members mems
LEFT JOIN cd.members recommender ON mems.recommendedby = recommender.memid
ORDER BY memsname,
         memfname;

-- PostgreSQL does not make SELECT aliases visible to the WHERE clause:
-- psql:/home/rabbit/pglings/exercises.sql:159: ERROR:  column "facility" does not exist
-- LINE 6: WHERE facility LIKE 'Tennis%'
-- WHERE facility LIKE 'Tennis%'
-- Either use the original column or use a subquery which actually output a alias column.

SELECT (mems.firstname || ' ' || mems.surname) as member,
       fac.name as facility
FROM cd.members mems
JOIN cd.bookings bks ON mems.memid = bks.memid
JOIN cd.facilities fac ON bks.facid = fac.facid
WHERE fac.name LIKE 'Tennis%'
GROUP BY member,
         facility;

-- Although this is also a contrived exmaple,
-- but SELECT can be hard to remain consistant among references,
-- if no subquery applied.

SELECT (mems.firstname || ' ' || mems.surname) as member,
       fac.name as facility,
       bks.slots * (CASE
                        WHEN mems.memid = 0 THEN fac.guestcost
                        ELSE fac.membercost
                    END) AS cost
FROM cd.members mems
JOIN cd.bookings bks ON mems.memid = bks.memid
JOIN cd.facilities fac ON bks.facid = fac.facid
WHERE bks.starttime >= '2012-09-14'
    AND bks.starttime < '2012-09-15'
    AND bks.slots * (CASE
                         WHEN mems.memid = 0 THEN fac.guestcost
                         ELSE fac.membercost
                     END) > 30
ORDER BY cost DESC;

-- Scalar sub queries
-- "It is an error to use a query that returns more than one row or more than
--  one column as a scalar subquery. (But if, during a particular execution,
--  the subquery returns no rows, there is no error;
--  the scalar result is taken to be null.)"

SELECT DISTINCT member,

    (SELECT firstname || ' ' || surname
     FROM cd.members mems
     WHERE mems.memid = rec_id) as recommender
FROM
    (SELECT (firstname || ' ' || surname) as member,
            recommendedby as rec_id
     FROM cd.members)
ORDER BY member ASC;


SELECT member,
       facility,
       cost
FROM
    (SELECT (mems.firstname || ' ' || mems.surname) as member,
            fac.name as facility,
            bks.slots * (CASE
                             WHEN mems.memid = 0 THEN fac.guestcost
                             ELSE fac.membercost
                         END) AS cost,
            bks.starttime as starttime
     FROM cd.members mems
     JOIN cd.bookings bks ON mems.memid = bks.memid
     JOIN cd.facilities fac ON bks.facid = fac.facid
     WHERE starttime >= '2012-09-14'
         AND starttime < '2012-09-15')
WHERE cost > 30
ORDER BY cost DESC;

BEGIN;


INSERT INTO cd.facilities (facid, name, membercost, guestcost, initialoutlay, monthlymaintenance)
VALUES (9, 'Spa', 20, 30, 100000, 800);


ROLLBACK;

BEGIN;

-- INSERT VALUES syntax is more ergonomic in comparison with SELECT and UNION as VALUES.

INSERT INTO cd.facilities
VALUES (9, 'Spa', 20, 30, 100000, 800),
       (10, 'Squash Court 2', 3.5, 17.5, 5000, 80);


ROLLBACK;

BEGIN;


INSERT INTO cd.facilities
VALUES ((SELECT max(facid)+1 FROM cd.facilities), 'Spa', 20, 30, 100000, 800);


ROLLBACK;

BEGIN;


UPDATE cd.facilities
SET initialoutlay = 10000
WHERE name = 'Tennis Court 2'
    AND initialoutlay = 8000;


ROLLBACK;

BEGIN;

-- These should be more common: WHERE facid in (0,1)

UPDATE cd.facilities
SET membercost = 6,
    guestcost = 30
WHERE name ~* 'Tennis Court [12]';


ROLLBACK;

BEGIN;


UPDATE cd.facilities
SET (membercost,
     guestcost) =
    (SELECT membercost*1.1,
            guestcost*1.1
     FROM cd.facilities
     WHERE facid = 0)
WHERE facid = 1;


ROLLBACK;

BEGIN;

-- Cavets in TRUNCATE:
-- https://www.postgresql.org/docs/current/mvcc-caveats.html

DELETE
FROM cd.bookings;


ROLLBACK;

BEGIN;


DELETE
FROM cd.members
WHERE memid = 37;


ROLLBACK;

BEGIN;

-- Heavy subquery matching
-- DELETE
-- FROM cd.members
-- WHERE memid NOT IN
--         (SELECT memid
--          FROM cd.bookings);

DELETE
FROM cd.members mems
WHERE NOT EXISTS
        (SELECT 1
         FROM cd.bookings
         WHERE memid = mems.memid);


ROLLBACK;


SELECT COUNT(facid)
FROM cd.facilities;


SELECT COUNT(*)
FROM cd.facilities
WHERE guestcost >= 10;

-- Calculate for each row is less effective.

SELECT *
FROM
    (SELECT memid,

         (SELECT COUNT(*)
          FROM cd.members mems
          WHERE mems.recommendedby = recommender.memid) AS count
     FROM cd.members recommender)
WHERE count > 0
ORDER BY memid;


SELECT recommendedby,
       COUNT(*)
FROM cd.members
WHERE recommendedby IS NOT NULL
GROUP BY recommendedby
ORDER BY recommendedby;


SELECT facid,
       SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid
ORDER BY facid;

-- Aggregate functions can also be used in ORDER BY clause.
-- ORDER BY SUM(slots);

SELECT facid,
       SUM(slots) AS "Total Slots"
FROM cd.bookings
WHERE starttime >= '2012-09-01'
    AND starttime < '2012-10-1'
GROUP BY facid
ORDER BY "Total Slots";


SELECT facid,
       date_part('Month', starttime) AS "month",
       SUM(slots) AS "Total Slots"
FROM cd.bookings
WHERE date_part('Year', starttime) = 2012
GROUP BY facid,
         "month"
ORDER BY facid,
         "month";


SELECT COUNT(*)
FROM
    (SELECT 1
     FROM cd.members mems
     JOIN cd.bookings bks ON mems.memid = bks.memid
     GROUP BY(mems.memid));


SELECT COUNT(DISTINCT memid)
FROM cd.bookings;


SELECT facid,
       SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid
HAVING "Total Slots" > 1000
ORDER BY facid ASC;


SELECT facid,
       SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid
HAVING SUM(slots) > 1000
ORDER BY facid ASC;