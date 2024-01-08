/*  --------------------
    Case Study Questions
    --------------------*/
-- Phu Nguyen
-- PostgreSQL

-- Part I --
-- Q1. How many pizzas were ordered?
select 
	count(*) as pizza_ordered_count
from
	pizza_runner.customer_orders_clean;
    
-- Q2. How many unique customer orders was made?
select
	count(distinct order_id) as unique_order_count
from 
	pizza_runner.customer_orders_clean;
    
-- Q3. How many successful orders was delivered by each runner?
select
	runner_id,
    count(order_id) as successful_order_delivered
from 
	pizza_runner.runner_orders_clean
where 
	cancellation is null
group by 
	runner_id;

-- Q4. How many of each type of pizza was delivered?
select
	p.pizza_name,
    count(o.pizza_id) as total_pizza_delivered
from 
	pizza_runner.customer_orders_clean o
left join 
	pizza_runner.runner_orders_clean r
	on o.order_id = r.order_id
left join 
	pizza_runner.pizza_names as p
	on o.pizza_id = p.pizza_id
where 
	r.cancellation is null
group by 
	p.pizza_name;

-- Q5. How many Vegetarian and Meatlovers were ordered by each customer?
select
	o.customer_id,
    p.pizza_name,
    count(p.pizza_name) as total_orders
from 
	pizza_runner.customer_orders_clean o
left join 
	pizza_runner.pizza_names p
	on o.pizza_id = p.pizza_id
group by 
	o.customer_id,
    p.pizza_name
order by
	o.customer_id ASC,
    count(p.pizza_name) DESC;

-- Q6. What was the maximum number of pizzas delivered in a single orders?
with pizza_per_orders as (
select
	o.order_id,
    count(o.pizza_id) as pizza_per_orders
from 
	pizza_runner.customer_orders_clean o
left join 
	pizza_runner.runner_orders_clean r
    on o.order_id = r.order_id
where r.cancellation is null
group by o.order_id
)
select 
	max(pizza_per_orders) as max_pizza_delivered
from
	pizza_per_orders;

-- Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select
	o.customer_id,
    sum(
    case when o.exclusions is not null or o.extras is not null then 1 else 0 end
    ) as at_least_1_change,
    sum(
    case when o.exclusions is null and o.extras is null then 1 else 0 end
    ) as no_change
from 
	pizza_runner.customer_orders_clean o
left join 
	pizza_runner.runner_orders_clean r
    on o.order_id = r.order_id
where 
	r.cancellation is null
group by
	o.customer_id
order by
	o.customer_id ASC;

-- Q8. How many pizzas were delivered that had both exclusions and extras?
select
	sum(
    case when o.exclusions is not null and o.extras is not null then 1 else 0 end
    ) as pizza_count_with_both_change
from 
	pizza_runner.customer_orders_clean o
left join 
	pizza_runner.runner_orders_clean r
    on o.order_id = r.order_id
where 
	r.cancellation is null;

-- Q9. What was the total volume of pizzas ordered for each hour of the day?
select
	date_part('hour', order_time) as hour_of_the_day,
    count(order_id) as pizza_ordered_count
from
	pizza_runner.customer_orders_clean
group by
	date_part('hour', order_time)
order by
	date_part('hour', order_time) ASC;

-- Q10. What was the volume of orders for each day of the week?
select
	to_char(order_time, 'day') as day_of_week,
    count(order_id) as pizza_ordered_count
from
	pizza_runner.customer_orders_clean
group by
	to_char(order_time, 'day')
order by
	to_char(order_time, 'day') ASC;

-- Part II --
-- Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select 
	'W' || to_char(registration_date, 'WW') || '- 2023' as registration_week,
    count(runner_id) as runner_registered
from
	pizza_runner.runners
group by
	('W' || to_char(registration_date, 'WW') || '- 2023')
order by ('W' || to_char(registration_date, 'WW') || '- 2023') ASC;

-- Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select
	runner_id,
	round(avg(date_part('minute', pickup_time - c.order_time))) as average_pickup_time_in_minutes
from
	pizza_runner.runner_orders_clean r,
	pizza_runner.customer_orders_clean c
where
	c.order_id = r.order_id
	and pickup_time is not null
	and distance is not null
	and duration is not null
group by
	runner_id
order by
	runner_id;
-- Q3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
select
	c.order_id,
	count(pizza_id) as pizzas_in_orders,
    round(avg(date_part('minute', pickup_time - c.order_time))) as average_pickup_time_in_minutes,
    round(avg(date_part('minute', pickup_time - c.order_time))/count(pizza_id)) as average_time_per_pizza
from
	pizza_runner.runner_orders_clean r,
	pizza_runner.customer_orders_clean c
where
	c.order_id = r.order_id
	and pickup_time is not null
	and distance is not null
	and duration is not null
group by
	c.order_id
order by
	c.order_id;
    
-- Q4. What was the average distance travelled for each customer?
select
	customer_id,
    round(avg(distance)::numeric,2) as average_distance_km
from
	pizza_runner.runner_orders_clean r,
	pizza_runner.customer_orders_clean c
where
	c.order_id = r.order_id
	and pickup_time is not null
	and distance is not null
	and duration is not null
group by
	customer_id
order by
	customer_id;

-- Q5. What was the difference between the longest and shortest delivery times for all orders?
select
	max(duration) - min(duration) as delivery_time_difference_in_minutes
from
	pizza_runner.runner_orders_clean 
where
	pickup_time is not null
	and distance is not null
	and duration is not null;
    
-- Q6. What was the average speed for each runner for each delivery and do you notice any trend for these value?
select
	order_id,
    runner_id,
    round((avg(distance/duration)*60)::numeric,2) as runner_average_speed
from
	pizza_runner.runner_orders_clean
where
	pickup_time is not null
	and distance is not null
	and duration is not null
group by
	order_id,
    runner_id
order by
	order_id;
-- order_id 8, and runner_id 2 has avg speed is 93.60 km/h, which is extremely high when compare to others.

-- Q7. What is the successful delivery percentage for each runner?
with delivered_status AS
(select
	runner_id,
	(case when pickup_time is not NULL then 1 else 0 end)::numeric as successful_times,
	(case when pickup_time is NULL then 1 else 0 end)::numeric as unsuccessful_times
from
	pizza_runner.runner_orders_clean
group by
	runner_id,
	pickup_time
)
select
    runner_id,
    round(1 - sum(unsuccessful_times) / (sum(unsuccessful_times) + sum(successful_times)),2) * 100 AS successful_rate
from 
    delivered_status
group by
	runner_id;
-- Part II --

-- Q1. What are the standard ingredients for each pizza?
with topping_extract as(
select 
	pizza_id, 
	unnest(string_to_array(toppings, ', ')::int[]) AS topping_id
from 
	pizza_runner.pizza_recipes)
, pizza_info as(
select
	pizza_name,
	topping_name
from
	topping_extract te
left join
	pizza_runner.pizza_names pn
	on te.pizza_id = pn.pizza_id
left join
	pizza_runner.pizza_toppings pt
	on te.topping_id = pt.topping_id
)
select
	pizza_name,
    string_agg(topping_name, ', ') as topping
from
	pizza_info
group by
	pizza_name;
    
-- Q2. What was the most commonly added extra?
select
	extra_topping,
    number_of_pizzas
from(
with extras_extract as(
select
	order_id,
	pizza_id,
	unnest(string_to_array(extras, ',') :: int[]) as topping_id
from
	pizza_runner.customer_orders_clean
where extras is not null
)
select
	topping_name as extra_topping,
    count((order_id, pizza_id, topping_name)) as number_of_pizzas,
    rank() over(order by count(distinct (order_id, pizza_id, topping_name)) desc) as rank_topping
from 
	extras_extract ee
left join 
	pizza_runner.pizza_toppings pt
	on ee.topping_id = pt.topping_id
group by 
	topping_name
) a
where
	rank_topping = 1;

-- Q3. What was the most common exclusion
select
	excluded_topping,
    number_of_pizzas
from(
with exclusions_extract as(
select
	order_id,
	pizza_id,
	unnest(string_to_array(exclusions, ',') :: int[]) as topping_id
from
	pizza_runner.customer_orders_clean
where exclusions is not null
)
select
	topping_name as excluded_topping,
    count((order_id, pizza_id, topping_name)) as number_of_pizzas,
    rank() over(order by count(distinct (order_id, pizza_id, topping_name)) desc) as rank_topping
from 
	exclusions_extract ee
left join 
	pizza_runner.pizza_toppings pt
	on ee.topping_id = pt.topping_id
group by 
	topping_name
) a
where
	rank_topping = 1;

/*
-- Q4. Generate an order item for each record in the customers_orders table in the format of one of the following:
  * Meat Lovers
  * Meat Lovers - Exclude Beef
  * Meat Lovers - Extra Bacon
  * Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/
with add_row_num as(
	select
		*,
		row_number() over() as row_num
	from pizza_runner.customer_orders_clean
),
agg_table as(
	select
		row_num,
		rn.order_id,
		pizza_name,
		case
			when exclusions is not null
			and topping_id in (select unnest(string_to_array(exclusions, ',') :: int[])) then topping_name
		end as exclusions,
		case
			when extras is not null
			and topping_id in (select unnest(string_to_array(extras, ',') :: int[])) then topping_name
		end as extras
	from pizza_runner.pizza_toppings as pt
		, add_row_num as rn
		join pizza_runner.pizza_names as pn on
		rn.pizza_id = pn.pizza_id
	group by
		row_num,
		rn.order_id,
		pizza_name,
		exclusions,
		extras,
		topping_id,
		topping_name
)
select
	order_id,
	concat(
    pizza_name,
    ' ',
    case
		when count(exclusions) > 0 then '- Exclude '
		else ''
    end,
    STRING_AGG(exclusions, ', '),
    case
		when count(extras) > 0 then ' - Extra '
		else ''
    end,
    STRING_AGG(extras, ', ')
	) as pizza_name_exclusions_and_extras
from agg_table
group by
	pizza_name,
	row_num,
	order_id
order by
	row_num;
/*
-- Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients

For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
*/
with add_row_num as(
	select
		*,
		row_number() over() as row_num
	from pizza_runner.customer_orders_clean
),
agg_table as(
	select
		row_num,
		rn.order_id,
		pizza_name,
		topping_name,
	case
		when exclusions is not null
		and pt.topping_id in (select unnest(string_to_array(exclusions, ',') :: int[]))
		then 0
		else
			case
				when pt.topping_id in (select unnest(string_to_array(pr.toppings, ',') :: int[]))
				then count(topping_name)
				else 0
			end
    end as count_toppings,
	case
		when extras is not null
		and pt.topping_id in (select unnest(string_to_array(extras, ',') :: int[]))
		then count(topping_name)
		else 0
	end as count_extras
	from
		add_row_num rn,
		pizza_runner.pizza_toppings pt,
		pizza_runner.pizza_recipes pr
		join pizza_runner.pizza_names pn on pr.pizza_id = pn.pizza_id
    where
		rn.pizza_id = pn.pizza_id
	group by
		pizza_name,
		row_num,
		rn.order_id,
		topping_name,
		toppings,
		exclusions,
		extras,
		pt.topping_id                                                          
),
topping_multipile as(
	select
		row_num,
		order_id,
		pizza_name,
		concat(
		case 
			when (sum(count_toppings) + sum(count_extras)) > 1 
			then (sum(count_toppings) + sum(count_extras)) || 'x'
		end,
		topping_name         
        ) as topping_name
	from agg_table
	where count_toppings > 0
	or count_extras >0
	group by
		row_num,
		order_id,
		pizza_name,
		topping_name
)
select 
	order_id,
    concat(
		pizza_name,
		': ',
		string_agg(topping_name, ',' order by topping_name) 
    ) as all_ingredient
from topping_multipile
group by 
	order_id,
    row_num,
    pizza_name
order by
	row_num;

-- Q6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with add_row_num as(
	select
		*,
		row_number() over() as row_num
	from pizza_runner.customer_orders_clean
),
agg_table as(
	select
		row_num,
		rn.order_id,
		topping_name,
	case
		when exclusions is not null
		and pt.topping_id in (select unnest(string_to_array(exclusions, ',') :: int[]))
		then 0
		else
			case
            when pt.topping_id in (select unnest(string_to_array(pr.toppings, ',') :: int[]))
            then count(topping_name)
            else 0
			end
    end as count_toppings,
	case
		when extras is not null
		and pt.topping_id in (select unnest(string_to_array(extras, ',') :: int[]))
		then count(topping_name)
		else 0
	end as count_extras
	from
		add_row_num rn,
		pizza_runner.runner_orders_clean ro, 
		pizza_runner.pizza_toppings pt,
		pizza_runner.pizza_recipes pr
		join pizza_runner.pizza_names pn on pr.pizza_id = pn.pizza_id
    where
        rn.pizza_id = pn.pizza_id			
		and rn.order_id = ro.order_id
		and ro.cancellation is null
	group by
		row_num,
		rn.order_id,
		topping_name,
		toppings,
		exclusions,
		extras,
		pt.topping_id                                                           
)
select
	topping_name,
    (sum(count_toppings) + sum(count_extras)) as total_ingredients
from agg_table
group by topping_name
order by total_ingredients desc;

-- Part IV

-- Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

with profit_table as
(select
	pizza_name,
	case
				when pizza_name = 'Meatlovers' THEN COUNT(pizza_name)*12
				else count(pizza_name)*10
	end as profit
from
	pizza_runner.customer_orders_clean as co
	join pizza_runner.pizza_names as pn on co.pizza_id = pn.pizza_id
	join pizza_runner.runner_orders_clean as ro on co.order_id = ro.order_id
where
	cancellation is null
group by
pizza_name)
select sum(profit) as profit
from profit_table;

-- Q2. What if there was an additional $1 charge for any pizza extras?

with profit_table as
(select
	pizza_name,
	case
	when pizza_name = 'Meatlovers' THEN COUNT(pizza_name)*12
	else count(pizza_name)*10
	end as profit
from
	pizza_runner.customer_orders_clean as co
	join pizza_runner.pizza_names as pn on co.pizza_id = pn.pizza_id
	join pizza_runner.runner_orders_clean as ro on co.order_id = ro.order_id
where
	cancellation is null
group by
	pizza_name),
	extras_table as(
	select
	count(topping_id) as extras
	from
	(select
			unnest(string_to_array(extras, ',') :: int[]) as topping_id
	from
		pizza_runner.customer_orders_clean co
		join pizza_runner.runner_orders_clean ro on co.order_id = ro.order_id
	where cancellation is null
	and extras is not null
	)e
)
select
	sum(profit) + extras as profit
    from profit_table, extras_table
group by extras;

-- Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

SET
	search_path = pizza_runner;
DROP TABLE IF EXISTS runner_rating;
CREATE TABLE runner_rating (
    "id" SERIAL PRIMARY KEY,
    "order_id" INTEGER,
    "customer_id" INTEGER,
    "runner_id" INTEGER,
    "rating" INTEGER,
    "rating_time" TIMESTAMP
);
INSERT INTO
	runner_rating (
    "order_id",
    "customer_id",
    "runner_id",
    "rating",
    "rating_time"
	)
VALUES
	('1', '101', '1', '4', '2020-01-01 19:35:42'),
	('2', '101', '1', '4', '2020-01-01 21:45:12'),
	('3', '102', '1', '5', '2020-01-03 08:15:23'),
	('4', '103', '2', '2', '2020-01-04 16:17:36'),
	('5', '104', '3', '5', '2020-01-08 22:15:34'),
	('7', '105', '2', '4', '2020-01-08 22:50:55'),
	('8', '102', '2', '4', '2020-01-10 08:45:15'),
	('10', '104', '1', '5', '2020-01-11 21:23:25');

/*
-- Q4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas

*/
select
	co.customer_id,
    ro.order_id,
    ro.runner_id,
    rating,
    co.order_time,
    ro.pickup_time,
    date_part('minute', ro.pickup_time - co.order_time) as time_between_order_and_pickup,
    duration as delivery_duration,
    round(avg(distance*60/duration)) as average_speed_kmph,
    count(ro.order_id) as number_of_pizzas
from
	pizza_runner.customer_orders_clean co
    join pizza_runner.runner_orders_clean ro on co.order_id = ro.order_id
    join pizza_runner.runner_rating rr on rr.order_id = co.order_id
where
	ro.cancellation is null
group by
	co.customer_id,
    ro.order_id,
    ro.runner_id,
    rating,
    co.order_time,
    ro.pickup_time,
    distance,
	duration
order by co.customer_id;

-- Q5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
with profit_table as
(select
	pizza_name,
	case
				when pizza_name = 'Meatlovers' THEN COUNT(pizza_name)*12
				else count(pizza_name)*10
	end as profit
from
	pizza_runner.customer_orders_clean as co
	join pizza_runner.pizza_names as pn on co.pizza_id = pn.pizza_id
	join pizza_runner.runner_orders_clean as ro on co.order_id = ro.order_id
where
	cancellation is null
group by
	pizza_name),
expense_table as(
select
	sum(distance*0.3) as expense
from pizza_runner.runner_orders_clean
where cancellation is null
)
select sum(profit) - expense as net_profit_in_dollars
from profit_table, expense_table
group by expense;

-- E. Bonus Questions
-- Q1. If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
select
	pr.pizza_id,
	pn.pizza_name,
	pr.toppings
from  
	pizza_runner.pizza_names pn
	join pizza_runner.pizza_recipes pr on pn.pizza_id = pr.pizza_id;

-- Part V

-- Q1. If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO
	pizza_runner.pizza_names ("pizza_id", "pizza_name")
VALUES
	(3, 'Supreme');
INSERT INTO
	pizza_runner.pizza_recipes ("pizza_id", "toppings")
VALUES
	(3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');