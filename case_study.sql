use Zomato;

-- 1. Find customers who have never ordered

select u.user_id,u.name,u.email
from users as u
left join orders as o
on u.user_id = o.user_id
where o.user_id is null ;

-- 2. Average Price/dish

select m.r_id, r.cuisine , avg(m.price) as avg_price
from resturants  as r
join menu as m
on r.r_id = m.r_id
group by r_id, r.cuisine;

-- 3. Find top restautant in terms of number of orders for a given month

SELECT 
    r.r_name,
    COUNT(o.order_id) AS total_orders,
    month(o.date) as month, 
    RANK() OVER (PARTITION BY MONTH(o.date) ORDER BY COUNT(o.order_id) DESC) AS ranks
FROM orders o
JOIN resturants r 
ON o.r_id = r.r_id
GROUP BY r.r_name, month
ORDER BY month, total_orders DESC;

-- after we rank then we can only get the rank 1 by month using with 

with ranked as (
	SELECT 
		r.r_name,
		COUNT(o.order_id) AS total_orders,
		month(o.date) as month, 
		RANK() OVER (PARTITION BY MONTH(o.date) ORDER BY COUNT(o.order_id) DESC) AS ranks
	FROM orders o
	JOIN resturants r 
	ON o.r_id = r.r_id
	GROUP BY r.r_name, month
	ORDER BY month, total_orders DESC
)
select r_name,  month, total_orders
from ranked
where ranks = 1
order by month;

-- 4. restaurants with monthly sales > 400

select r.r_name,
	 sum(o.amount) as total_sales, 
	 month(o.date) as months
from resturants as r
join orders as o 
on  r.r_id = o.r_id
group by r_name, months
HAVING total_sales > 400
order by months, total_sales;

-- 5. Show all orders with order details for a particular customer in a particular date range

with resturant_name as(
select u.user_id,
	u.name, 
	o.order_id, 
	od.f_id,
	o.r_id,
	o.amount, 
	o.date
from orders as o
join users as u
on u.user_id = o.user_id
join order_details as od
on o.order_id = od.order_id
where u.user_id = 1 and o.date between '2022-05-01' and '2022-06-01'
order by o.date)

select r.user_id,
	r.name, 
	r.order_id,
    r.f_id,
	r.r_id , 
    rr.r_name ,
    f.f_name,
	r.amount, 
	r.date
from resturant_name as r
join resturants as rr
on r.r_id = rr.r_id
join food as f
on r.f_id = f.f_id
order by r.date;

-- 6. Find restaurants with max repeated customers

with resturant_order  as(
select r.r_name, 
	o.user_id, 
	o.r_id, 
	count(*) as times
from orders as o 
join resturants as r
on r.r_id = o.r_id
group by r.r_name, o.user_id,o.r_id
order by r_id, times)

select ro.r_name,
	count(r_name) as times
from resturant_order as ro
join users as u
on ro.user_id = u.user_id
group by ro.r_name
order by times desc;


-- 7. Month over month revenue growth of zomato

-- total revenue =  E (price per unit 1 * quantity1)+  (price per unit 2 * quantity2)+......
-- since we have the direct amount we must add all the amounts in a single month to calculate revenue of a month

select month(date) as months, sum(amount) as revenue
from orders
group by months;


-- 8. Customer -> favorite food

with last as 
(
	with name_order as
    (
		select 
			u.user_id,
			u.name,
			o.order_id,
			od.f_id
		from orders as o
		join users as u 
		on  u.user_id = o.user_id
		join order_details as od
		on o.order_id = od.order_id
	)

	select 
		n.user_id,
		n.name,
		f.f_name,
		count(*) as count,
		rank() over(partition by n.user_id order by count(*) desc) as ranking
	from name_order as n
	join food as f
	on n.f_id = f.f_id
	group by n.user_id,f.f_name, n.name
	order by n.user_id,n.name,ranking 
)

select
	l.user_id,
	l.name,
	l.f_name as favourite_food
from last as l
where l.ranking = 1
order by l.user_id;
-- based on the number of orders of a specific food we can say that that particular food is the customers favorite food












