select * from athlete_events;
select * from noc_regions;

--Query 1
select count(distinct games) from athlete_events;

--Query 2
select distinct year,season,city
from athlete_events;

--Query 3
select games, count(distinct nr.region) as no_of_nations_participated
from athlete_events ae
join noc_regions nr on ae.noc=nr.noc
group by games;

--Query 4.
with first_query as (
select games, count(distinct nr.region) as max_and_min_no_of_nations_participated
from athlete_events ae
join noc_regions nr on ae.noc=nr.noc
group by games
order by max_and_min_no_of_nations_participated desc
limit 1
),
second_query as ( select games, count(distinct nr.region) as least_no_of_nations_participated
from athlete_events ae
join noc_regions nr on ae.noc=nr.noc
group by games
order by least_no_of_nations_participated 
limit 1
) select * from first_query
union
select * from second_query;

--Query 5.
with t_games as (select count(distinct games) as total_games
from athlete_events
),
countries as (
select games, nr.region as country
from athlete_events ae
join noc_regions nr on nr.noc=ae.noc
group by games, nr.region
),
countries_participated as(
select country, count(1) as total_participated_games
from countries
group by country)
select cp.*
from countries_participated cp
join t_games tg on tg.total_games=cp.total_participated_games
order by 1;

--Query 6.
with t1 as ( select count(distinct games) as total_summer_games
from athlete_events
where season ='Summer'),
t2 as (
select distinct sport, games
from athlete_events
where season ='Summer'
order by games),
t3 as (
select sport, count(games) as no_of_games
from t2
group by sport)
select * from t3
join t1 on t1.total_summer_games=t3.no_of_games;

--Query 7.
with t1 as ( select distinct games,sport
from athlete_events),

    t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where t2.no_of_games = 1
      order by t1.sport;

--Query 8
with t1 as (select distinct games, sport
from athlete_events),
t2 as (
select games, count(*) as no_of_games
from t1
group by games
)
select * from t2
order by no_of_games desc;

--Query 9
with temp as (select name, sex,cast(case when age='NA' then '0' else age end as int)as age, team,noc
,games,year,season,city,sport,event,medal
from athlete_events),
ranking as(
select *,rank() over(order by age desc) as rnk
from temp
where medal='Gold'
)
select * from ranking
where rnk=1;

--Query 10
with t1 as
        	(select sex, count(1) as cnt
        	from athlete_events
        	group by sex),
        t2 as
        	(select *, row_number() over(order by cnt) as rn
        	 from t1),
        min_cnt as
        	(select cnt from t2	where rn = 1),
        max_cnt as
        	(select cnt from t2	where rn = 2)
    select concat('1 : ', round(max_cnt.cnt::decimal/min_cnt.cnt, 2)) as ratio
    from min_cnt, max_cnt;

--Query 11
with t1 as(select name, count(1) as total_medals
from athlete_events
where medal='Gold'
group by name
order by count(1) desc),

t2 as (select *, dense_rank() over(order by total_medals desc ) as rnk
from t1)
select *
from t2
where rnk<= 5;

--Query 12

with t1 as (select name, team, count(*) as total_medals
from athlete_events
where medal in ('Gold','Silver','Bronze')
group by name, team
order by total_medals desc),

t2 as (select *, dense_rank() over(order by total_medals desc) as rnk
from t1)
select name,team,total_medals
from t2
where rnk <=5;

--Query 13
select nr.region, count(*) as total_medals
from athlete_events ae
join noc_regions nr on nr.noc=ae.noc
where medal != 'NA'
group by nr.region
order by total_medals desc
limit 5;

--Query 14
select country, coalesce(gold,0) as gold,coalesce(silver,0) as silver, coalesce(bronze,0) as bronze
from crosstab('select nr.region as country, medal ,count(1) as total_medals
from athlete_events ae
join noc_regions nr on nr.noc=ae.noc
where medal <> ''NA''
group by country, medal
order by country, medal',
'values (''Bronze''), (''Gold''), (''Silver'')')
as result(country varchar, bronze bigint, gold bigint, silver bigint)
order by gold desc, silver desc, bronze desc ;

--Query 15
select concat(games, ' - ', nr.region) as games,
medal, count(1) as total_medals
from athlete_events ae
join noc_regions nr on nr.noc=ae.noc
where medal <> 'NA'
group by games,nr.region,medal
order by games, medal;

--Query 16
 WITH temp as
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    	 	, substring(games, position(' - ' in games) + 3) as country
            , coalesce(gold, 0) as gold
            , coalesce(silver, 0) as silver
            , coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    				  	, count(1) as total_medals
    				  FROM athlete_events ae
    				  JOIN noc_regions nr ON nr.noc = ae.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint))
    select distinct games
    	, concat(first_value(country) over(partition by games order by gold desc)
    			, ' - '
    			, first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc)
    			, ' - '
    			, first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc)
    			, ' - '
    			, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
    from temp
    order by games;

--Query 17
 with t1 as
        	(select sport, count(1) as total_medals
        	from athlete_events
        	where medal <> 'NA'
        	and team = 'India'
        	group by sport
        	order by total_medals desc),
        t2 as
        	(select *, rank() over(order by total_medals desc) as rnk
        	from t1)
    select sport, total_medals
    from t2
    where rnk = 1;

--Query 18
   select team, sport, games, count(1) as total_medals
    from athlete_events
    where medal <> 'NA'
    and team = 'India' and sport = 'Hockey'
    group by team, sport, games
    order by total_medals desc;




			