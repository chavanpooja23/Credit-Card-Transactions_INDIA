select * from credit_card_transactions
--=================================================================================================================================
--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
--=================================================================================================================================


with cte1 as (
    select top 5 cct_city, sum(cct_amount) as city_sum_amount 
    from credit_card_transactions
    group by cct_city
    order by city_sum_amount desc
),
cte2 as (
    select sum(cast(cct_amount as bigint)) as total_sum 
    from credit_card_transactions
)

select cte1.*, 
format((city_sum_amount * 1.0) / total_sum * 100, '0.00') as perc_city 
from cte1 
inner join cte2 on 1=1;


--=================================================================================================================================
--2- write a query to print highest spend month and amount spent in that month for each card type
--=================================================================================================================================


with cte as
(
	select datepart(MONTH, cct_date) as trans_month, sum(cct_amount) trans_amount_month, cct_card_type 
	from credit_card_transactions
	group by datepart(MONTH, cct_date), cct_card_type
)

select * from (
	select *,
	RANK() over( partition by cct_card_type order by trans_amount_month desc) as rn
	from cte
) a 
where rn = 1


--=================================================================================================================================
--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
--=================================================================================================================================


with cte as
(
	select *, 
	sum(cct_amount) over(partition by cct_card_type order by cct_amount) as total_spends 
	from credit_card_transactions
)

select * 
from ( 
	select *, RANK() over(partition by cct_card_type order by total_spends) as rn 
	from cte where total_spends >= 1000000
) a 
where rn = 1


--=================================================================================================================================
--4- write a query to find city which had lowest percentage spend for gold card type
--=================================================================================================================================


with cte1 as (
    select cct_city, sum(cct_amount) as city_sum_amount 
    from credit_card_transactions
	where cct_card_type = 'Gold'
    group by cct_city
),
cte2 as (
    select sum(cast(cct_amount as bigint)) as total_sum 
    from credit_card_transactions
	where cct_card_type = 'Gold'
)

select top 1 cte1.*, 
format((city_sum_amount * 1.0) / total_sum * 100, '0.00') as perc_city 
from cte1 
inner join cte2 on 1=1
order by cte1.city_sum_amount;


--=================================================================================================================================
--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
--=================================================================================================================================


with cte1 as
(
	select cct_city, cct_exp_type as highest_expense_type, cct_amount,
	row_number() over(partition by cct_city order by cct_amount desc) as rn1
	from credit_card_transactions
),
cte2 as
(
	select cct_city, cct_exp_type as lowest_expense_type, cct_amount,
	row_number() over(partition by cct_city order by cct_amount) as rn2
	from credit_card_transactions
)

select cte1.cct_city, highest_expense_type, lowest_expense_type 
from cte1, cte2 
where cte1.cct_city = cte2.cct_city 
and rn1=1 and rn2=1


--=================================================================================================================================
--6- write a query to find percentage contribution of spends by females for each expense type
--=================================================================================================================================


with cte1 as (
    select cct_exp_type, sum(cct_amount) as female_sum_amount 
    from credit_card_transactions
	where cct_gender = 'F'
    group by cct_exp_type
),
cte2 as (
    select sum(cast(cct_amount as bigint)) as total_sum 
    from credit_card_transactions
)

select cte1.cct_exp_type, 
format((female_sum_amount * 1.0) / total_sum * 100, '0.00') as perc_city 
from cte1 
inner join cte2 on 1=1;


--=================================================================================================================================
--7- which card and expense type combination saw highest month over month growth in Jan-2014
--=================================================================================================================================


with cte as
(
select cct_card_type, cct_exp_type, sum(cct_amount) as total_spend, datepart(month,cct_date) as cct_month, datepart(year,cct_date) as cct_year
from credit_card_transactions
group by cct_card_type, cct_exp_type, cct_amount, datepart(month,cct_date), datepart(year,cct_date)
) 

select top 1 *, 
(total_spend-previous_month_spend) as prev_month from
(
	select *,
	lag(total_spend,1) over(partition by cct_card_type, cct_exp_type order by cct_month, cct_year) as previous_month_spend
	from cte 
) a
where isnull(previous_month_spend,'') <> '' and cct_month = 1 and cct_year = 2014
order by total_spend desc


--=================================================================================================================================
--8- during weekends which city has highest total spend to total no of transcations ratio 
--=================================================================================================================================


select top 1 cct_city, 
format(sum(cct_amount)*1.0/ count(*), '0.00') as trans_ratio 
from credit_card_transactions
where datename(WEEKDAY,cct_date) in ('Saturday','Sunday')
group by cct_city
order by trans_ratio desc;


--=================================================================================================================================
--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
--=================================================================================================================================


with cte as (
    select cct_city, cct_date,
	min(cct_date) over(partition by cct_city) as first_transaction_date,
    row_number() over (partition by cct_city order by cct_date) as rn
    from credit_card_transactions
)

select cct_city, datediff(day, first_transaction_date, cct_date) as no_of_days
from cte
where rn = 500
order by no_of_days;


--=================================================================================================================================