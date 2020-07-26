/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

select distinct name 
from Facilities 
where membercost!=0.0;

/* Q2: How many facilities do not charge a fee to members? */
select count(distinct name) 
from Facilities 
where membercost=0.0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost != 0.0
AND membercost < 0.20 * monthlymaintenance;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid IN ( 1, 5 );

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT DISTINCT name, monthlymaintenance, 
	(CASE WHEN monthlymaintenance >=100 THEN 'expensive'
	      WHEN monthlymaintenance <100 THEN 'cheap'END) AS label
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
ORDER BY joindate DESC

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT CONCAT( m.firstname, ' ', m.surname, ' ', 'has used a tennis court ', f.name ) AS tennis_court_users
FROM Facilities AS f
LEFT JOIN Bookings AS b ON f.facid = b.facid
LEFT JOIN Members AS m ON b.memid = m.memid
WHERE f.name LIKE 'Tennis%'
ORDER BY m.firstname;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT b.bookid, CONCAT( m.firstname, ' ', m.surname, ' has booked ', f.name ) AS booking_detail, 
	(CASE WHEN b.memid=0 AND (b.slots * f.guestcost *2)>30 THEN b.slots * f.guestcost *2
	      WHEN b.memid!=0 AND (b.slots * f.membercost *2)>30 THEN b.slots * f.membercost *2 END) AS cost
FROM Facilities AS f
LEFT JOIN Bookings AS b ON f.facid = b.facid
LEFT JOIN Members AS m ON b.memid = m.memid
WHERE b.starttime LIKE '2012-09-14%'
HAVING cost IS NOT NULL
ORDER BY cost


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

select booking, booking_detail, cost
from (select b.bookid as booking, CONCAT(m.firstname, ' ', m.surname, ' has booked ', f.name) AS booking_detail, 2*f.guestcost*b.slots as cost
      from Facilities as f
      left join Bookings as b
      on f.facid=b.facid
      left join Members as m
      on b.memid=m.memid
      where b.memid=0 and b.starttime LIKE '2012-09-14%') as guest
union all
select member.booking, member.booking_detail, member.cost
from (select b.bookid as booking, CONCAT(m.firstname, ' ', m.surname, ' has booked ', f.name) AS booking_detail, 2*f.membercost*b.slots as cost
      from Facilities as f
      left join Bookings as b
      on f.facid=b.facid
      left join Members as m
      on b.memid=m.memid
      where b.memid!=0 and b.starttime LIKE '2012-09-14%') as member
having cost>30
order by cost desc

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

select subquery.facility, subquery.revenue
from (select g.facility as facility, (guest_revenue+member_revenue) as revenue
      from (select f.facid as facid, f.name as facility, sum(2*b.slots*f.guestcost) as guest_revenue  
                       from Facilities as f
                       left join Bookings as b
                       on f.facid=b.facid
                       where b.memid=0
                       group by facility) as g
      left join (select f.facid as facid, f.name as facility, sum(2*b.slots*f.membercost) as member_revenue  
                       from Facilities as f
                       left join Bookings as b
                       on f.facid=b.facid
                       where b.memid!=0
                       group by facility) as m
      on g.facid=m.facid
      group by facility) as subquery
where subquery.revenue<1000

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

select concat(m1.firstname, ' ' ,m1.surname, ' is recommended by ', m2.firstname, ' ',m2.surname) as recommended
from Members as m1
left join Members as m2
on m1.recommendedby=m2.memid
where m2.memid!=0
order by m1.surname, m1.firstname


/* Q12: Find the facilities with their usage by member, but not guests */

select f.name as facility, round((count(b.bookid)/(select count(bookid) from Bookings))*100, 2) as usage_percent 
from Facilities as f
left join Bookings as b
on f.facid=b.facid
-- members only therefore exclude the memid=0 which are guests
where b.memid!=0 
group by f.name

/* Q13: Find the facilities usage by month, but not guests */

select f.name as facility, round((count(b.bookid)/(select count(bookid) from Bookings))*100, 2) as usage_percent, extract(month from b.starttime) as month 
from Facilities as f
left join Bookings as b
on f.facid=b.facid
-- members only therefore exclude the memid=0 which are guests
where b.memid!=0 
group by month, f.name