-- Simple SQL Queries
-- PostgreSQL uses single quotes as string literals.

SELECT 'Hello PostgreSQL';

-- Special commands
\c exercises;


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
WHERE membercost < monthlymaintenance/50
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
WHERE facid = Any('{1, 5}');

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
WHERE (mem.firstname || ' ' || mem.surname)= 'David Farrell';


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