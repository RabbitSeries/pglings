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
UNION ALL
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

-- Unfortunately, Postgres, unlike some other RDBMSs like SQL Server and MySQL,
-- doesn't support putting column names in the HAVING clause.
-- So, reference to alias is not allowed in neither WHERE and HAVING clause, in which
-- HAVING clause filters result after GROUP BY while WHERE clause filters the input.
-- Both HAVING and WHERE clause are evaluated before SELECT's alias statement.
-- Note that ORDER BY can also use other comparable expressions and aggregate functions
-- if there is a aggregation statement in the query.

SELECT facid,
       SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid
HAVING SUM(slots) > 1000 -- HAVING "Total Slots" > 1000
ORDER BY facid ASC;

-- Yet, it seems to be undocumented that whether non-volatile functions'
-- result is cached or not,
-- Just use another subquery or use the power of CTEs (Common Table Expressions).

SELECT *
FROM
    (SELECT facid,
            SUM(slots) AS "Total Slots"
     FROM cd.bookings
     GROUP BY facid)
WHERE "Total Slots" > 1000
ORDER BY facid ASC;

-- Guest when mems.memid = 0.

SELECT
    (SELECT name
     FROM cd.facilities fac
     WHERE fac.facid = expenses.facid), SUM(expense) AS revenue
FROM
    (SELECT bks.facid as facid,
            SUM(bks.slots) * (
                                  (SELECT CASE
                                              WHEN mems.memid = 0 THEN "guestcost"
                                              ELSE "membercost"
                                          END
                                   FROM cd.facilities fac
                                   WHERE fac.facid = bks.facid)) as expense
     FROM cd.members mems
     JOIN cd.bookings bks ON mems.memid = bks.memid
     GROUP BY mems.memid,
              bks.facid) expenses
GROUP BY facid
ORDER BY revenue; -- This also works: ORDER BY SUM(expense);

-- Can be simplified into the following query. If no extra columns from cd.member
-- besides the constraints are needed, don't reference it.
-- This is not allowed, ungrouped column nust be used in aggregator functions.
--    SUM(slots) * CASE
--                    WHEN memid = 0 THEN guestcost
--                    ELSE membercost
--                END

SELECT name,
       SUM(slots * CASE
                       WHEN memid = 0 THEN guestcost
                       ELSE membercost
                   END) revenue
FROM cd.facilities fac
JOIN cd.bookings bks ON fac.facid = bks.facid
GROUP BY name
ORDER BY revenue;


SELECT *
FROM
    (SELECT name,
            SUM(slots * CASE
                            WHEN memid = 0 THEN guestcost
                            ELSE membercost
                        END) revenue
     FROM cd.facilities fac
     JOIN cd.bookings bks ON fac.facid = bks.facid
     GROUP BY name)
WHERE revenue < 1000
ORDER BY revenue;


SELECT facid,
       "Total Slots"
FROM
    (SELECT facid,
            SUM(slots) AS "Total Slots"
     FROM cd.bookings
     GROUP BY facid)
WHERE "Total Slots" =
        (SELECT MAX("Total Slots")
         FROM
             (SELECT facid,
                     SUM(slots) AS "Total Slots"
              FROM cd.bookings
              GROUP BY facid));

-- Can be simplified into

SELECT facid,
       SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid
ORDER BY "Total Slots" DESC
LIMIT 1;

-- Or in a CTE approach:
WITH totalslots AS
    (SELECT facid,
            SUM(slots) AS "Total Slots"
     FROM cd.bookings
     GROUP BY facid)
SELECT facid,
       "Total Slots"
FROM totalslots
WHERE "Total Slots" =
        (SELECT MAX("Total Slots")
         FROM totalslots);

-- Don't look at this shithole.
WITH totalslots AS 
    (SELECT facid, 
            date_part('Month', starttime) AS "month", 
            SUM(slots) AS "Total Slots" 
     FROM cd.bookings 
     WHERE date_part('Year', starttime) = 2012
     GROUP BY facid,
              "month"
     ORDER BY facid,
              "month"),
     maxfacid AS
    (SELECT (MAX(facid) + 1) as facid,
            NULL as "month",
            SUM("Total Slots")
     FROM totalslots)
SELECT (CASE
            WHEN facid =
                     (SELECT facid
                      FROM maxfacid) THEN NULL
            ELSE facid
        END) AS facid,
       (CASE
            WHEN "month" = 255 THEN NULL
            ELSE "month"
        END) AS "month",
       "Total Slots"
FROM
    (SELECT *
     FROM totalslots
     UNION
         (SELECT facid,
                 255 AS "month",
                 SUM("Total Slots")
          FROM totalslots
          GROUP BY facid)
     UNION
         (SELECT
              (SELECT facid
               FROM maxfacid) as facid,
                 NULL as "month",
                 SUM("Total Slots")
          FROM totalslots)
     ORDER BY facid,
              "month");

-- This is better, NULL will be ranked as the last element.
WITH totalslots AS
    (SELECT facid,
            date_part('Month', starttime) AS "month",
            SUM(slots) AS "Total Slots"
     FROM cd.bookings
     WHERE date_part('Year', starttime) = 2012
     GROUP BY facid,
              "month")
SELECT *
FROM totalslots
UNION ALL
    (SELECT facid,
            null,
            SUM("Total Slots")
     FROM totalslots
     GROUP BY facid)
UNION ALL
    (SELECT NULL,
            NULL,
            SUM("Total Slots")
     FROM totalslots)
ORDER BY facid,
         "month";

-- This is the best.
-- Empty list will aggregate all the rows.
-- NULL for ungrouped and unaggregated columns.

SELECT facid,
       date_part('Month', starttime) AS "month",
       SUM(slots) AS "Total Slots"
FROM cd.bookings
WHERE date_part('Year', starttime) = 2012
GROUP BY GROUPING
SETS ((facid,
       "month"), (facid), ())
ORDER BY facid,
         "month";

-- Which is equivalent to the following query.
-- ROLLUP represents the given list of expressions and all prefixes of the list
-- including the empty list

SELECT facid,
       date_part('Month', starttime) AS "month",
       SUM(slots) AS "Total Slots"
FROM cd.bookings
WHERE date_part('Year', starttime) = 2012
GROUP BY ROLLUP (facid,
                 "month")
ORDER BY facid,
         "month";


SELECT bks.facid,
       "name",
       round(SUM(slots) * 0.5, 2) as "Total Hours"
FROM cd.bookings bks
JOIN cd.facilities facs ON bks.facid = facs.facid
GROUP BY bks.facid,
         "name"
ORDER BY bks.facid;

-- Removing "name" also works if facs.facid is used.
-- Other database management system might not support this.
-- Don't use this for cross-platform compatability.

SELECT facs.facid,
       "name",
       trunc(SUM(slots) * 0.5, 2) as "Total Hours"
FROM cd.bookings bks
JOIN cd.facilities facs ON bks.facid = facs.facid
GROUP BY facs.facid
ORDER BY facs.facid;


SELECT mems.surname,
       mems.firstname,
       mems.memid,
       MIN(starttime) AS starttime
FROM cd.members mems
JOIN cd.bookings bks ON mems.memid = bks.memid
WHERE starttime >= '2012-9-1'
GROUP BY mems.memid,
         mems.surname,
         mems.firstname
ORDER BY mems.memid;


SELECT COUNT(*) OVER(),
                firstname,
                surname
FROM cd.members
ORDER BY joindate;


SELECT row_number() OVER(
                         ORDER BY joindate),
                    firstname,
                    surname
FROM cd.members;

-- An aggregate used with ORDER BY and the default window frame definition
-- produces a “running sum” type of behavior,
-- which may or may not be what's wanted.
-- So this will produce the same result as above, which is counter-intuitive.
-- In this example the window is the same for each row, but each row's window
-- frame is restricted into start row to current row.

SELECT COUNT(*) OVER(
                     ORDER BY joindate) AS row_number,
       firstname,
       surname
FROM cd.members;


SELECT facid,
       total_slots
FROM
    (SELECT facid,
            total_slots,
            rank() OVER (
                         ORDER BY total_slots DESC) "rank"
     FROM
         (SELECT facid,
                 SUM(slots) total_slots
          FROM cd.bookings
          GROUP BY facid))
WHERE "rank" = 1;

-- Or resue the sum, as column number or name can't be referenced in OVER expression:

SELECT facid,
       total_slots
FROM
    (SELECT facid,
            SUM(slots) total_slots,
            rank() OVER (
                         ORDER BY SUM(slots))
     FROM cd.bookings
     GROUP BY facid)
WHERE "rank" = 1;

-- The final result is sorted according to one of the ORDER BY statement
-- in the OVER window expressions if no ORDER BY is specified in the
-- outmost SELECT clause.

SELECT *,
       rank() OVER (
                    ORDER BY "hours" DESC) "rank"
FROM
    (SELECT firstname,
            surname,
            round(SUM(slots) / 2.0, -1) "hours"
     FROM cd.members mems
     JOIN cd.bookings bks ON mems.memid = bks.memid
     GROUP BY firstname,
              surname,
              mems.memid)
ORDER BY "rank",
         surname,
         firstname;


SELECT *
FROM
    (SELECT name,
            rank() OVER (
                         ORDER by revenue DESC) "rank"
     FROM
         (SELECT "name",
                 SUM(slots * CASE
                                 WHEN memid = 0 THEN guestcost
                                 ELSE membercost
                             END) AS revenue
          FROM cd.bookings bks
          JOIN cd.facilities fac ON bks.facid = fac.facid
          GROUP BY "name"))
WHERE "rank" <= 3
ORDER BY name;

-- OVER windows is also allowed to access grouped rows.
-- The over window can also contain calculations.
-- Thus the above query can be simplified into:

SELECT *
FROM
    (SELECT name,
            rank() OVER (
                         ORDER by SUM(slots * CASE
                                                  WHEN memid = 0 THEN guestcost
                                                  ELSE membercost
                                              END) DESC) "rank"
     FROM cd.facilities fac
     JOIN cd.bookings bks ON fac.facid = bks.facid
     GROUP BY name)
WHERE "rank" <= 3
ORDER BY name;


SELECT *
FROM
    (SELECT name,
            ntile(3) OVER (
                           ORDER by SUM(slots * CASE
                                                    WHEN memid = 0 THEN guestcost
                                                    ELSE membercost
                                                END) DESC) "rank"
     FROM cd.facilities fac
     JOIN cd.bookings bks ON fac.facid = bks.facid
     GROUP BY name)
ORDER BY rank,
         name;


SELECT fac.name,
       initialoutlay / (SUM(slots * CASE
                                        WHEN memid = 0 THEN guestcost
                                        ELSE membercost
                                    END) / 3 - monthlymaintenance) AS revenue
FROM cd.bookings bks
JOIN cd.facilities fac ON bks.facid = fac.facid
GROUP BY fac.facid,
         name
ORDER BY name;