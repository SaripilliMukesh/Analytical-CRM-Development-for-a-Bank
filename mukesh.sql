create database CRM;
use CRM;
show tables from crm;
desc activecustomer;
desc bank_churn;
desc creditcard;
desc customerinfo;
desc exitcustomer;
desc gender;
desc geography;


ALTER TABLE customerinfo
RENAME COLUMN `Bank DOJ` TO DateOfJoining;
select *  from customerinfo
ALTER TABLE customerinfo DROP COLUMN DateOfJoining

ALTER TABLE customerinfo ADD DateofJoining DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE Customerinfo set DateOfJoining= STR_TO_DATE(DateOfJoining, '%d/%m/%Y') ;
select * from customerinfo

#Objective Questions:

# 2.Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
select customerId, EstimatedSalary, year(DateOfJoining) as transaction_year
from customerinfo
where (year(DateOfJoining) = 2019 and quarter(DateOfJoining) = 4)
   or (year(DateOfJoining) = 2018 and quarter(DateOfJoining) = 4)
   or (year(DateOfJoining) = 2017 and quarter(DateOfJoining) = 4)
   or (year(DateOfJoining) = 2016 and quarter(DateOfJoining) = 4)
order by EstimatedSalary desc
limit 5;

# 3.Calculate the average number of products used by customers who have a credit card. (SQL)
select avg(NumOfProducts) as AvgProductsWithCard
from bank_churn 
where HasCrCard=1;

# 5.Compare the average credit score of customers who have exited and those who remain. (SQL)
select avg(if(Exited=1,CreditScore,NULL)) as ExitedAvg, avg(if(Exited=0,CreditScore,NULL)) RetainedAvg from bank_churn B; 

# 6.Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)------------------
SELECT  (SELECT GenderCategory FROM Gender G WHERE G.GenderId= C.GenderId LIMIT 1) Gender, AVG(EstimatedSalary) as Avg_estimated_salary
	,SUM(CASE WHEN IsActiveMember=1 THEN 1 ELSE 0 END) AS NoOfActiveMembers
FROM CustomerInfo C LEFT JOIN  bank_churn G ON C.CustomerId= G.CustomerId
GROUP BY GenderId 
ORDER BY AVG(EstimatedSalary) DESC;
#LIMIT 1;
# 7.Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
WITH credit_score_segment AS (
	SELECT
        CASE
            WHEN CreditScore <= 599 THEN 'Poor'
            WHEN CreditScore > 599 AND CreditScore <= 700 THEN 'Low'
            WHEN CreditScore > 700 AND CreditScore <= 749 THEN 'Fair'
            WHEN CreditScore > 749 AND CreditScore < 799 THEN 'Good'
            ELSE 'Excellent'
        END AS Credit_Segment,
        Exited
    FROM bank_churn
)
SELECT
    Credit_Segment,
    SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS Total_exited_Cust,
    COUNT(*) AS Total_customers,
    ROUND(SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) / COUNT(*), 3) AS Exit_rate
FROM credit_score_segment
GROUP BY Credit_Segment
ORDER BY Exit_rate DESC
LIMIT 1;


# 8.Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)
select (select GeographyLocation from geography G where G.GeographyID= C.GeographyID limit 1) as Geography
from customerinfo C join bank_churn B on C.CustomerId= B.CustomerId
where IsActiveMember=1 and DATEDIFF(CURDATE(), DateOfJoining)>5
group by GeographyID
order by COUNT(C.CustomerId) desc
limit 1;


# 11.Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.

select year(DateOfJoining) `year`, COUNT(CustomerId) as CntCustomer
from CUstomerInfo 
group by  year(DateOfJoining);

# 15.Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. Also, rank the gender according to the average value. (SQL)
select round(avg(ci.EstimatedSalary), 2) as Avg_income,ci.GeographyID,gd.GenderCategory as Gender,
    rank() over (partition by ci.GeographyID order by round(avg(ci.EstimatedSalary), 2) desc) as Gender_rank
from customerinfo ci
left join gender gd on ci.GenderID = gd.GenderID 
group by ci.GeographyID, gd.GenderCategory;


# 16.Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).
WITH CTE AS(
	SELECT CASE WHEN Age BETWEEN 18 AND 30 THEN '18-30' WHEN AGE BETWEEN 31 AND 50 THEN '30-50' ELSE '50+' END  AS AgeBracket,Tenure
	FROM CustomerInfo C
	JOIN bank_churn B ON C.CustomerId= B.CustomerId
	WHERE Exited=1 AND Age>=18)
SELECT AgeBracket, round(AVG(Tenure),1) AvgTenure
FROM CTE
GROUP BY AgeBracket;

# 18.Is there any correlation between the salary and the Credit score of customers?
SELECT CORR(CI.EstimatedSalary, BC.CreditScore) AS Correlation
FROM CustomerInfo CI
INNER JOIN Bank_Churn BC ON CI.CustomerId = BC.CustomerId;

# 19.Rank each bucket of credit score as per the number of customers who have churned the bank.
with churned_customers as (
    select
        case
            when CreditScore <= 599 then 'Poor'
            when CreditScore > 599 and CreditScore <= 700 then 'Low'
            when CreditScore > 700 and CreditScore <= 749 then 'Fair'
            when CreditScore > 749 and CreditScore <= 799 then 'Good'
            else 'Excellent'
        end as Credit_Score_Bucket,
        count(*) as Churned
    from bank_churn
    where Exited = 1
    group by
        case
            when CreditScore <= 599 then 'Poor'
            when CreditScore > 599 and CreditScore <= 700 then 'Low'
            when CreditScore > 700 and CreditScore <= 749 then 'Fair'
            when CreditScore > 749 and CreditScore <= 799 then 'Good'
            else 'Excellent'
        end
),
ranked_bucket as (
    select Credit_Score_Bucket,Churned,
		rank() over (order by Churned desc) as BucketRank
    from churned_customers
)
select Credit_Score_Bucket,Churned, BucketRank
from ranked_bucket;

# 20.According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets that have lesser than average number of credit cards per bucket.
WITH AgeBucket AS (
    SELECT 
        CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 50 THEN '31-50'
            ELSE '51+'
        END AS Age_Group,
        COUNT(*) AS Num_Customers,
        SUM(HasCrCard) AS Num_Customers_With_Credit_Card
    FROM CustomerInfo as c join bank_churn b on c.customerId= b.customerId
    GROUP BY Age_Group ),
AverageCreditCards AS (
    SELECT AVG(Num_Customers_With_Credit_Card) AS Avg_Credit_Cards
    FROM AgeBucket)
SELECT Age_Group, Num_Customers, Num_Customers_With_Credit_Card
FROM AgeBucket
CROSS JOIN AverageCreditCards
WHERE Num_Customers_With_Credit_Card < Avg_Credit_Cards;

# 21.Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
select GT.GeographyLocation,count(BC.CustomerId) as Churned,round(avg(BC.Balance),1) as Avg_Balance,
    RANK() over (order by count(BC.CustomerId) desc, avg(BC.Balance) desc) as GeoRank
from CustomerInfo CI
left join Bank_Churn BC on CI.CustomerId = BC.CustomerId
left join Geography GT on CI.GeographyID = GT.GeographyID
where BC.Exited = 1
group by CI.GeographyID, GT.GeographyLocation
order by Churned desc, Avg_Balance desc;

# 22.As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.
select concat(CustomerID, '_', Surname) as CustomerID_Surname
from CustomerInfo;

# 23.Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.
select BC.*,
(select ExitCategory from ExitCustomer EC 
where EC.ExitID = BC.Exited) as ExitCategory
from Bank_Churn BC;

# 25.Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.
select CI.CustomerId, CI.Surname, BC.IsActiveMember
from CustomerInfo CI 
join Bank_Churn BC on CI.CustomerId = BC.CustomerId 
where CI.Surname like '%on';