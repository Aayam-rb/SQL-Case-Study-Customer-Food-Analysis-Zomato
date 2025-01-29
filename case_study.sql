use Zomato;

-- 1. Find customers who have never ordered

select u.user_id,u.name,u.email
from users as u
left join orders as o
on u.user_id = o.user_id
where o.user_id is null ;

output:
| user_id | name    | email              |  
|---------|---------|--------------------|  
| 6       | Anupama | anupama@gmail.com  |  
| 7       | Rishabh | rishabh@gmail.com  |  


-- 2. Average Price/dish

select m.r_id, r.cuisine , avg(m.price) as avg_price
from resturants  as r
join menu as m
on r.r_id = m.r_id
group by r_id, r.cuisine;

output:
| r_id | cuisine      | avg_price |  
|------|--------------|-----------|  
| 1    | Italian      | 316.6667  |  
| 2    | American     | 215.0000  |  
| 3    | North Indian | 126.6667  |  
| 4    | South Indian | 176.6667  |  
| 5    | Chinese      | 216.6667  |  


-- 3. Find top restautant in terms of number of orders for a given month

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

output:
| r_name     | month | total_orders |  
|------------|-------|--------------|  
| Dosa Plaza | 5     | 3            |  
| kfc        | 6     | 3            |  
| kfc        | 7     | 3            |  


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

output:
| r_name     |total_sales | months |  
|------------|------------|--------|  
| kfc        | 645        | 5      |  
| Dosa Plaza | 780        | 5      |  
| dominos    | 1000       | 5      |  
| box8       | 480        | 6      |  
| dominos    | 950        | 6      |  
| kfc        | 990        | 6      |  
| box8       | 460        | 7      |  
| China Town | 1050       | 7      |  
| dominos    | 1100       | 7      |  
| kfc        | 1935       | 7      |  

	
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

output:
| user_id | name   | order_id | f_id | r_id | r_name  | f_name          | amount | date       |  
|---------|--------|----------|------|------|---------|-----------------|--------|------------|  
| 1       | Nitish | 1001     | 1    | 1    | dominos | Non-veg Pizza   | 550    | 2022-05-10 |  
| 1       | Nitish | 1001     | 3    | 1    | dominos | Choco Lava Cake | 550    | 2022-05-10 |  
| 1       | Nitish | 1002     | 3    | 2    | kfc     | Choco Lava Cake | 415    | 2022-05-26 |  
| 1       | Nitish | 1002     | 4    | 2    | kfc     | Chicken Wings   | 415    | 2022-05-26 |  


-- 6. Find restaurants with max repeated customers

with resturant_order  as(
select r.r_name, 
	o.user_id, 
	o.r_id, 
	count(*) as times
from orders as o 
join resturants as r
on r.r_id = o.r_id
group by r.r_name, o.user_id, o.r_id)

select ro.r_name,
	count(distinct ro.user_id) as repeated_customers
from resturant_order as ro
join users as u
on ro.user_id = u.user_id
group by ro.r_name
order by repeated_customers desc;

output:
| r_name     | repeated_customers|  
|------------|-------------------|  
| dominos    | 4                 |  
| kfc        | 4                 |  
| Dosa Plaza | 3                 |  
| box8       | 2                 |  
| China Town | 2                 |  


-- 7. Month over month revenue growth of zomato

select 
    t.months,
    t.revenue,
    ((t.revenue - t.neww) / t.neww) * 100 as revenue_growth
from (
    select
        month(date) as months,
        SUM(amount) as revenue,
        lag (SUM(amount)) over (order by month(date)) as neww
    from orders
    group by month(date)
) as t;

output:
| months | revenue | revenue_growth|  
|--------|---------|---------------|  
| 5      | 2425    |               |  
| 6      | 3220    | 32.7835       |  
| 7      | 4845    | 50.4658       |  

	
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
-- Based on the number of orders for a specific food item, we can say that, that food item is the customers favorite food

output:
| user_id | name    | favourite_food    |  
|---------|---------|-------------------|  
| 1       | Nitish  | Choco Lava Cake   |  
| 2       | Khushboo | Choco Lava Cake  |  
| 3       | Vartika | Chicken Wings     |  
| 4       | Ankit   | Schezwan Noodles  |  
| 4       | Ankit   | Veg Manchurian    |  
| 5       | Neha    | Choco Lava Cake   |  












