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
-- There are not subqueries.

SELECT *
FROM cd.facilities
WHERE facid IN (1,
                5);


SELECT *
FROM cd.facilities
WHERE facid = Any (1,
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

