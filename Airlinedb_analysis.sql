-- Representing the “book_date” column in “yyyy-mmm-dd” format using Bookings table 
select
    book_ref,
    to_char(book_date, 'yyyy-mmm-dd') as book_date,
    total_amount
from 
    Bookings;

-- Write a query to find the seat number which is least allocated among all the seats
select
    s.seat_no,count(*)
from 
    seats s inner join boarding_passes bp 
    on s.seat_no = bp.seat_no
group by s.seat_no
order by 2 desc
limit 1;

-- In the database, identify the month wise highest paying passenger name and passenger id.
with temp1 as (
select
    to_char(b.book_date,'mmm-yy') as Month_name,
    t.passenger_id,
    t.passenger_name,
    sum(tf.amount) as total_amount
from 
    tickets t inner join bookings b 
    on t.book_ref = b.book_ref
    inner join ticket_flights tf
    on t.ticket_no = tf.ticket_no
group by 1,2,3
),
temp2 as
(
select 
    *,
    rank() over (partition by month_name order by total_amount desc) as passenger_rank
from temp1
)

select 
    Month_name,
    passenger_id,
    passenger_name,
    total_amount 
from 
    temp2 
where 
    passenger_rank = 1;

-- In the database, identify the month wise least paying passenger name and passenger id?
with temp1 as (
select
    to_char(b.book_date,'mmm-yy') as Month_name,
    t.passenger_id,
    t.passenger_name,
    sum(tf.amount) as total_amount
from 
    tickets t inner join bookings b 
    on t.book_ref = b.book_ref
    inner join ticket_flights tf
    on t.ticket_no = tf.ticket_no
group by 1,2,3
),
temp2 as
(
select 
    *,
    rank() over (partition by month_name order by total_amount asc) as passenger_rank
from temp1
)

select 
    Month_name,
    passenger_id,
    passenger_name,
    total_amount 
from 
    temp2 
where 
    passenger_rank = 1 ;

-- Number of tickets without boarding passes
select count(t.ticket_no)
from
    tickets t left join boarding_passes bp 
    on t.ticket_no = bp.ticket_no
where
    bp.ticket_no is null;


-- Identify details of the longest flight 
select
    flight_no,
    departure_airport,
    arrival_airport,
    aircraft_code,
    actual_arrival-actual_departure as durations
from
    flights
where 
    actual_arrival-actual_departure = (   
                                        select
                                            max(actual_arrival-actual_departure)
                                     from 
                                            flights
                                      );

-- Identify details of all the morning flights (morning --> between 6AM to 11 AM)    
select
    flight_id,
    flight_no,
    scheduled_departure,
    scheduled_arrival,
    extract(hour from scheduled_departure) as timings
from
    flights
where
    extract(hour from scheduled_departure) between 6 and 11
order by timings;

-- Earliest morning flight available from every airport.

with temp1 as
(
    select
        *,
        rank() over (
                        partition by departure_airport 
                        order by extract(hour from scheduled_departure) asc,
                        extract(minute from scheduled_departure) asc,
                        extract (second from scheduled_departure) asc
                    ) as timining_rank
    from 
        flights
    where  
        extract(hour from scheduled_departure) between 2 and 6
)

select 
    flight_id,
    flight_no,
    scheduled_departure,
    scheduled_arrival,
    departure_airport,
    to_char(scheduled_departure,'hh24:mi:ss') as timings
from 
    temp1
where 
    timining_rank=1;


--  List of airport codes in Europe/Moscow timezone
select
    Airport_code
from 
    Airports
where
    lower(timezone) = 'europe/moscow' ;


-- Count of seats in various fare conditions for every aircraft code
select
    aircraft_code,
    fare_conditions,
    count(seat_no) as seat_count
from
    seats 
group by 
    aircraft_code,fare_conditions;


-- Name of the airport having maximum number of departure flight
select 
    airport_name 
from 
(
    select
        f.departure_airport,a.airport_name,count(f.flight_id)
    from 
        airports a join flights f  
        on a.airport_code = f.departure_airport
    where 
        actual_departure is not null
    group by 
        f.departure_airport,a.airport_name
    order by 3 desc
    limit 1
) as temp1;


-- Extract flight details having range between 3000 and 6000 and flying from DME airport
select 
    distinct(f.flight_no),f.aircraft_code,a.range,f.departure_airport
from 
    flights f inner join aircrafts a 
    on f.aircraft_code = a.aircraft_code
where 
    upper(f.departure_airport) = 'DME' and (a.range between 3000 and 6000);



-- List of flight ids which are using aircrafts from “Airbus” company and got cancelled or delayed

select 
    f.flight_id, a.model
from 
    flights f inner join aircrafts a 
    on f.aircraft_code = a.aircraft_code
where 
    a.model like '%Airbus%' and (lower(f.status) in ('cancelled','delayed'));

-- Which airport(name) has most cancelled flights (arriving)
with temp1 as 
(
select 
    a.airport_name, count(f.flight_id) as cancelled_count
from 
    flights f inner join airports a 
    on f.arrival_airport = a.airport_code
where 
    lower(f.status)  = 'cancelled'
group by 
    a.airport_name
order by 2 desc
)

select airport_name from temp1
where cancelled_count  in ( select max(cancelled_count) from temp1);


-- Date-wise last flight id flying from every airport
with temp1 as 
( 
select 
*, rank() over (
               partition by departure_airport,to_char(scheduled_departure,'yyyy-mm-dd')
                order by scheduled_departure desc
  		       ) as flying_rank
from  flights
)

select 
flight_id,flight_no,scheduled_departure,departure_airport
from 
temp1
where flying_rank = 1;


-- Identify list of customers who will get the refund due to cancellation of the flights and how much amount they will get?
select 
    t.passenger_name,sum(tf.amount) 
from 
    tickets t inner join ticket_flights tf
    on t.ticket_no = tf.ticket_no
    inner join flights f
    on tf.flight_id = f.flight_id
where 
    lower(f.status) = 'cancelled'
group by 
    t.passenger_name;

-- Identify date wise first cancelled flight id flying for every airport
with temp1 as
(
select 
*, rank() over (
                     	partition by departure_airport,to_char(scheduled_departure,'yyyy-mm-dd')
                     	order by scheduled_departure 
  		          ) as cancellation_rank
from  flights
where lower(status) = 'cancelled'
)

select 
 flight_id,flight_no,scheduled_departure,departure_airport
 from 
 temp1
 where cancellation_rank = 1;


-- Identify list of flight id's having highest range.

with temp1 as
(
select 
    *,
    rank() over (order by a.range desc) as high_range_rank
from 
    flights f inner join aircrafts  a 
    on f.aircraft_code = a.aircraft_code
)

select 
    flight_id 
from 
    temp1
where 
    high_range_rank = 1;
