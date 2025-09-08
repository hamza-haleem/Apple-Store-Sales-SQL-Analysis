select * from category;
select * from products;
select * from sales;
select * from stores;
select * from warranty;


-- improving query performance


-- execution time - 112ms
-- after creating index execution time - 15ms
explain analyze
select * from sales
where store_id = 'ST-55';

create index sales_store_id on sales(store_id);


-- execution time - 117ms
-- after creating index execution time - 10ms
explain analyze
select * from sales
where product_id = 'P-59';

create index sales_product_id on sales(product_id);


-- execution time - 90ms
-- after creating index execution time - 2ms
explain analyze
select * from sales
where sale_date = '2023-06-16';

create index sales_sale_date on sales(sale_date);



-- Q1 Find the number of stores in each country.
select count(*) as No_of_Stores, country from stores
group by country
order by No_of_Stores desc;


-- Q2 Calculate the total number of units sold by each store.
select s.store_id, st.store_name, sum(s.quantity) as total_units_sold
from sales as s
	join stores as st
	on s.store_id = st.store_id
group by s.store_id, st.store_name
order by total_units_sold desc;


-- Q3 Identify how many sales occurred in December 2023.
select sale_date, count(sale_id) as total_sales 
from sales
where sale_date between '2023-12-01' and '2023-12-31'
group by sale_date
order by sale_date;


-- Q4 What is the distribution of warranty claims across different repair statuses.
select repair_status, count(claim_id) as Total_claims
from warranty
group by repair_status;


-- Q5 How are warranty claims distributed across stores by repair status.
select st.store_id, st.store_name, w.repair_status, count(w.claim_id) as no_of_claims
from warranty as w
	join sales as s on w.sale_id = s.sale_id
	join stores as st on st.store_id = s.store_id
group by st.store_id, st.store_name, w.repair_status;


-- Q6 Identify top 10 stores had the highest total units sold in the last year.
select s.store_id, st.store_name, sum(s.quantity) as total_units_sold
from sales as s
	join stores as st
	on s.store_id = st.store_id
where sale_date > '2023-12-31'
group by s.store_id, st.store_name
order by total_units_sold desc
limit 10;

/* Insights:
	1. Apple Fukuoka (Japan) leads with 14,497 units sold.
	2. Close competition from North Michigan Avenue (Chicago) & Union Square (San Francisco).
	3. Strong performance across Asia, North America, and Europe (Japan, USA, France, UK).
	4. Narrow gap (~560 units) between #1 and #10 → shows consistent sales among top stores.
	5. Top stores are mainly in flagship, premium shopping locations. */


-- Q7 Which products are the most sold, and how many units of each were sold.
select p.product_name, count(s.product_id) as total_sold_prod
from sales as s
	join products as p
	on s.product_id = p.product_id
group by p.product_id
order by total_sold_prod desc;


-- Q8 Which products generate the highest total sales revenue.
select p.product_id, p.product_name, sum(s.quantity * p.price) as total_sales
from sales as s
	join products as p on p.product_id = s.product_id
group by p.product_id, p.product_name
order by total_sales desc;


-- Q9 Which countries contribute most to overall sales, and how many stores do they operate.
select st.country, count(distinct st.store_id) as no_of_stores,
sum(s.quantity * p.price) as country_sales,
	round(sum(s.quantity * p.price)::numeric/
		(select sum(s.quantity * p.price)::numeric
		from sales as s join products as p on s.product_id = p.product_id) * 100,
	2) || '%' as sales_contribution
from sales as s 
	join stores as st on st.store_id = s.store_id
	join products as p on s.product_id = p.product_id
group by st.country
order by no_of_stores desc;

/* Insights:
	1. United States dominates with 20.03% of global sales from 15 stores,
	making it the largest contributor by far.
	2. Australia (9.36%) and China (9.33%) follow closely, despite each having
	only 7 stores, showing high productivity per store.
	3. Japan (8.04%) also contributes strongly with just 6 stores.
	4. European countries like the UK (5.33%), France (5.28%), and Germany (4.04%)
	maintain solid contributions with fewer stores.
	5. Several countries with only 1–3 stores (e.g., Singapore, Thailand, Taiwan,
	Netherlands, Spain) still contribute meaningfully, proving the strength
	of Apple’s flagship locations. */


/* Q10 Which product categories contribute the most to total sales,
and how many products are offered in each category. */
select c.category_name, count(distinct p.product_id) as no_of_products,
sum(s.quantity * p.price) as category_sales,
	round(sum(s.quantity * p.price)::numeric/
		(select sum(s.quantity * p.price)::numeric
		from sales as s join products as p on s.product_id = p.product_id) * 100,
	2) || '%' as sales_contribution
from sales as s 
	join products as p on s.product_id = p.product_id
	join category as c on c.category_id = p.category_id
group by c.category_name
order by no_of_products desc;


-- Q11 For each store, identify the best-selling day based on highest quantity sold.
with best_selling_day as
(
	select s.store_id, st.store_name, to_char(s.sale_date, 'day') as day_name,
	sum(s.quantity) as total_units_sold,
	row_number() over(partition by s.store_id order by sum(s.quantity) desc) as row_no
	from sales as s
		join stores as st
		on s.store_id = st.store_id
	group by s.store_id, day_name, st.store_name
	order by total_units_sold desc
)
select * from best_selling_day
where row_no = 1;


/* Q12 Identify the least selling product in each country for each year
based on total units sold. */
with least_selling_products as
(
	select st.country, s.product_id, p.product_name, sum(s.quantity) as total_units_sold,
	to_char(s.sale_date, 'YYYY') as extracted_year,
	row_number() over(partition by st.country, to_char(s.sale_date, 'YYYY')
	order by sum(s.quantity)) as row_no
	from sales as s
		join stores as st
		on s.store_id = st.store_id
		join products as p
		on p.product_id = s.product_id
	group by st.country, extracted_year, s.product_id, p.product_name
	order by extracted_year
)
select * from least_selling_products
where row_no = 1;


-- Q13 Calculate how many warranty claims were filed within 180 days of a product sale.
select count(*) as total_claims
from warranty as w
	join sales as s
	on w.sale_id = s.sale_id
where w.claim_date BETWEEN s.sale_date AND s.sale_date + INTERVAL '180 days';


-- Q14 Among products, which ones are generating the most warranty claims compared to sales.
select 
	p.product_id, 
	p.product_name,
	count(w.claim_id) as total_claims,
	count(s.sale_id) as total_sales
from warranty as w
	right join sales as s
	on s.sale_id = w.sale_id
	join products as p
	on p.product_id = s.product_id
group by p.product_id
order by total_claims desc;

/* Insights:
	1. Products like MacBook Pro (Touch Bar), iPhone 13 Pro Max,
	and Beats Fit Pro are among the highest in warranty claims,
	each recording over 370 claims.
	2. Accessories such as the Smart Cover for iPad, MagSafe Charger,
	and Magic Mouse also appear in the high-claims list, showing that
	smaller add-ons face frequent warranty issues.
	3. Despite high claim counts, sales volumes are also very close across
	these products (11k–12k range), suggesting claims are proportional to sales
	scale rather than isolated product failures.
	4. The tight range between top products (381 vs. 297 claims) indicates that
	warranty claims are fairly evenly spread across Apple’s portfolio,
	with no single product dominating defects. */


/* Q15 Identify the product category with the most warranty claims filed
in the last two years. */
select c.category_name, count(w.claim_id) as total_claims
from sales as s
	join warranty as w
	on w.sale_id = s.sale_id
	join products as p
	on p.product_id = s.product_id
	join category as c
	on c.category_id = p.category_id
WHERE w.claim_date >= current_date - interval '2 years'
group by c.category_name
order by total_claims desc;


-- Q16 Which month generated the highest sales annually in each country.
with best_selling_months_for_each_year as
(
	SELECT 
    st.country,
    TO_CHAR(s.sale_date, 'FMMonth') AS month_name,
    DATE_PART('year', s.sale_date) AS extracted_year,
    SUM(s.quantity*p.price) AS total_sales,
	row_number() over(partition by st.country, DATE_PART('year', s.sale_date)
	order by sum(s.quantity*p.price) desc) as row_no
	FROM sales as s
		join stores as st on s.store_id = st.store_id
		join products as p on p.product_id = s.product_id
	GROUP BY st.country, extracted_year, month_name, DATE_TRUNC('month', s.sale_date)
	ORDER BY st.country, extracted_year, DATE_TRUNC('month', s.sale_date)
)
select * from best_selling_months_for_each_year
where row_no = 1;


-- Q17 Analyze the year-by-year growth ratio for each store.
WITH yearly_sales AS 
(
    SELECT 
    store_id,
    extract(year from s.sale_date) AS extracted_year,
    SUM(p.price * s.quantity)::numeric AS total_sales
    FROM sales as s
		join products as p
		on s.product_id = p.product_id
    GROUP BY store_id, extracted_year
),
growth as
(
	select
    store_id,
    extracted_year,
    total_sales,
    LAG(total_sales) OVER(PARTITION BY store_id ORDER BY extracted_year) AS prev_year_sales
	from yearly_sales
)
select store_id, extracted_year, prev_year_sales, total_sales as current_year_sales,
    ROUND(((total_sales - prev_year_sales)/
	(prev_year_sales)) * 100, 2) AS year_over_year_growth
FROM growth
where prev_year_sales is not null
ORDER BY store_id, extracted_year;

/* Insights:
	📉 Most stores experienced consistent decline in 2024, with
	drops ranging -7% to -22%, showing a broad market slowdown.
	📊 2021–2023 had mixed performance: some stores grew steadily
	(e.g., ST-14 +5.15% in 2023) while others declined.
	🏆 Top growth years were seen in 2021–2022 transitions,
	where many stores had +2% to +6% increases.
	⚠️ Biggest losses in 2024: ST-14 (-21.83%), ST-58 (-21.07%),
	ST-9 (-18.62%), ST-30 (-17.42%).
	💡 Stores with strong resilience (slower decline in 2024)
	include ST-40 (-7.40%) and ST-70 (-9.60%).
	📌 Overall trend: short-term gains (2021–2022) followed by sharp contraction in 2024. */


-- Q18 How many warranty claims are associated with products in different price ranges.
WITH product_claims AS 
(
    SELECT 
    p.product_id,
    p.price,
    COUNT(w.claim_id) AS total_claims
    FROM products p
    	JOIN sales as s 
        ON p.product_id = s.product_id
		join warranty as w
		on w.sale_id = s.sale_id
    GROUP BY p.product_id, p.price
)
SELECT 
    CASE 
        WHEN price < 500 THEN 'Less expensive products'
        WHEN price BETWEEN 500 AND 1000 THEN 'Medium range products'
        ELSE 'Highly expensive products'
    END AS price_range,
    SUM(total_claims) AS No_of_claims
FROM product_claims
GROUP BY price_range;


/* Q19 What are the yearly sales and cumulative running totals of sales
for each country over time. */
WITH yearly_country_sales AS 
(
    SELECT 
    st.country, 
    TO_CHAR(s.sale_date, 'YYYY') AS extracted_year,
    SUM(s.quantity * p.price) AS total_sales
    FROM sales s
    	JOIN stores st ON st.store_id = s.store_id
    	JOIN products p ON p.product_id = s.product_id
    GROUP BY st.country, extracted_year
)
SELECT 
    country,
    extracted_year,
    total_sales,
    SUM(total_sales) OVER (
        PARTITION BY country 
        ORDER BY extracted_year
    ) AS cumulative_sales
FROM yearly_country_sales
ORDER BY country, extracted_year;


/* Q20 Determine the percentage chance of receiving warranty claims
after each purchase for each country. */
with risk_of_getting_claim as
(
	select st.country, sum(s.quantity) as totla_units_sold, count(w.claim_id) No_of_Claims,
		round((count(w.claim_id)::numeric/
		sum(s.quantity)::numeric * 100), 2) || '%' as percentage_of_getting_claim
	from sales as s
		join warranty as w on s.sale_id = w.sale_id
		join stores as st on st.store_id = s.store_id
	group by st.country
	order by percentage_of_getting_claim desc
)
select * from risk_of_getting_claim;

/* Insights:
	1. Taiwan, Netherlands, Austria, and Spain have the highest claim rates (~18.5–19%),
	despite lower total units sold.
	2. The United States sold the most units (33K+) but had a slightly
	lower claim rate (18.3%), showing better reliability at scale.
	3. The UK, Canada, and UAE are mid-volume sellers but still have
	above-average claim percentages (~18.4–18.5%).
	4. South Korea had the lowest claim percentage (17.87%),
	indicating stronger product reliability.
	5. Overall, claim percentages are closely clustered (17.8%–19%),
	suggesting a consistent global warranty claim pattern across markets. */


-- Q21 How do product sales evolve over their lifecycle (from launch to 4+ years).
select p.product_id, p.product_name,
	case
		when s.sale_date between p.launch_date and
		p.launch_date + interval '6 months' then '0-6 months'
		when s.sale_date between p.launch_date + interval '6 months' and
		p.launch_date + interval '1 year'  then '1st year'
		when s.sale_date between p.launch_date + interval '1 year' and
		p.launch_date + interval '2 years'  then '2nd year'
		when s.sale_date between p.launch_date + interval '2 years' and
		p.launch_date + interval '3 years'  then '3rd year'
		when s.sale_date between p.launch_date + interval '3 years' and
		p.launch_date + interval '4 years'  then '4th year'
		else 'after four years' 
	end as time_period,
	sum(s.quantity) as total_units_sold,
	sum(s.quantity * p.price) as total_sales
from sales as s 
	join products as p on p.product_id = s.product_id
group by p.product_id, p.product_name, time_period
order by p.product_name, time_period;