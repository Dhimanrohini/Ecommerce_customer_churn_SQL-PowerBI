 /*****
 DATA CLEANING
 ******/
 
 -- 1. Finding the total number of customers

SELECT DISTINCT
    COUNT(CustomerID) AS Total_customers
FROM
    ecomm.eccomchurn;
-- Answer = There are 5630 customers in the dataset.

-- 2. Checking for duplicate rows 

SELECT 
    CustomerID, COUNT(CustomerID)
FROM
    ecomm.eccomchurn
GROUP BY CustomerID
HAVING COUNT(CustomerID) > 1;
-- Answer = There are no duplicates values present in the data.

-- 3. Checking for null values

SELECT 
    'Tenure' AS ColumnName, COUNT(*) AS NullCount
FROM
    ecomm.eccomchurn
WHERE
    Tenure IS NULL OR Tenure = '' 
UNION SELECT 
    'WarehouseToHome' AS ColumnName, COUNT(*) AS NullCount
FROM
    ecomm.eccomchurn
WHERE
    warehousetohome IS NULL
        OR WarehouseToHome = '' 
UNION SELECT 
    'HourSpendonApp' AS ColumnName, COUNT(*) AS NullCount
FROM
    ecomm.eccomchurn
WHERE
    hourspendonapp IS NULL
        OR HourSpendOnApp = '' 
UNION SELECT 
    'OrderAmountHikeFromLastYear' AS ColumnName,
    COUNT(*) AS NullCount
FROM
    ecomm.eccomchurn
WHERE
    orderamounthikefromlastyear IS NULL
        OR OrderAmountHikeFromlastYear = '' 
UNION SELECT 
    'CouponUsed' AS ColumnName, COUNT(*) AS NullCount
FROM
    ecomm.eccomchurn
WHERE
    CouponUsed = 0 OR CouponUsed = '' 
UNION SELECT 
    'OrderCount' AS ColumnName, COUNT(*) AS NullCount
FROM
    ecomm.eccomchurn
WHERE
    ordercount IS NULL OR OrderCount = '' 
UNION SELECT 
    'DaySinceLastOrder' AS ColumnName, COUNT(*) AS NullCount
FROM
    ecomm.eccomchurn
WHERE
    DaySinceLastOrder = '';
-- Answer = There are null values present in the data.

-- 3.1 Dealing with null values.

SET SQL_SAFE_UPDATES = 0;

UPDATE ecomm.eccomchurn
SET Hourspendonapp = (SELECT average_value FROM (SELECT AVG(Hourspendonapp) AS average_value FROM ecomm.eccomchurn) AS temp_table)
WHERE Hourspendonapp IS NULL or Hourspendonapp = ''
AND CustomerID > 0;

UPDATE ecomm.eccomchurn
SET Tenure = (SELECT average_value FROM (SELECT AVG(Tenure) AS average_value FROM ecomm.eccomchurn) AS temp_table)
WHERE Tenure IS NULL or Tenure = ''
AND CustomerID > 0;

UPDATE ecomm.eccomchurn
SET WarehouseToHome = (SELECT average_value FROM (SELECT AVG(WarehouseToHome) AS average_value FROM ecomm.eccomchurn) AS temp_table)
WHERE WarehouseToHome IS NULL or WarehouseToHome = ''
AND CustomerID > 0;

UPDATE ecomm.eccomchurn
SET OrderAmountHikeFromLastYear = (SELECT average_value FROM (SELECT AVG(OrderAmountHikeFromLastYear) AS average_value FROM ecomm.eccomchurn) AS temp_table)
WHERE OrderAmountHikeFromLastYear IS NULL or OrderAmountHikeFromLastYear = ''
AND CustomerID > 0;

UPDATE ecomm.eccomchurn
SET CouponUsed = (SELECT average_value FROM (SELECT AVG(CouponUsed) AS average_value FROM ecomm.eccomchurn) AS temp_table)
WHERE CouponUsed IS NULL or CouponUsed = ''
AND CustomerID > 0;

UPDATE ecomm.eccomchurn
SET OrderCount = (SELECT average_value FROM (SELECT AVG(OrderCount) AS average_value FROM ecomm.eccomchurn) AS temp_table)
WHERE OrderCount IS NULL or OrderCount = ''
AND CustomerID > 0;

UPDATE ecomm.eccomchurn
SET DaySinceLastOrder = (SELECT average_value FROM (SELECT AVG(DaySinceLastOrder) AS average_value FROM ecomm.eccomchurn) AS temp_table)
WHERE DaySinceLastOrder IS NULL or DaySinceLastOrder = ''
AND CustomerID > 0;

-- Check for the Null values.
select * from ecomm.eccomchurn
where Hourspendonapp = '' and WarehouseToHome = '' and DaySinceLastOrder = '' and OrderCount = '' and CouponUsed = '' and OrderAmountHikeFromLastYear = '';

-- Answer = Null values have been removed.

-- 4. Creating a new column from an already existing “churn” column.

ALTER TABLE ecomm.eccomchurn
ADD CustomerStatus NVARCHAR(50);

UPDATE ecomm.eccomchurn
SET CustomerStatus = 
CASE
	WHEN Churn = 0 THEN 'Stayed'
    WHEN Churn = 1 THEN 'Churned'
END;

-- 5. Creating a new column from an already existing “complain” column.

ALTER TABLE ecomm.eccomchurn
ADD ComplainRecieved NVARCHAR(50);

UPDATE ecomm.eccomchurn
SET ComplainRecieved =
CASE
	WHEN complain = 0 THEN 'No'
    WHEN complain = 1 THEN 'Yes'
END;

-- 6. Checking values in each column for correctness and accuracy.

/**After going through each column, we noticed some redundant values in some columns 
and a wrongly entered value. This will be explored and fixed.**/

-- 6.1 Fixing redundancy in “PreferedLoginDevice” Column

select distinct preferredlogindevice 
from ecomm.eccomchurn;

-- As Phone and Mobile Phone are same, so we will update it.

UPDATE ecomm.eccomchurn
SET preferredlogindevice = 'Phone'
WHERE preferredlogindevice = 'Mobile Phone';

-- 6.2 Fixing redundancy in “PreferedOrderCat” Column

select distinct PreferedOrderCat
from ecomm.eccomchurn;

-- As Phone and Mobile Phone are same, so we will update it.

UPDATE ecomm.eccomchurn
SET PreferedOrderCat = 'Mobile Phone'
WHERE  PreferedOrderCat = 'Mobile';

-- 6.3 Fixing redundancy in “PreferredPaymentMode” Column

select distinct preferredpaymentmode
from ecomm.eccomchurn;

UPDATE ecomm.eccomchurn
SET preferredpaymentmode = 'Cash on Delivey'
WHERE preferredpaymentmode = 'COD';

-- 6.4 Fixing wrongly entered values in “WarehouseToHome” column

select distinct WarehouseToHome
from ecomm.eccomchurn;

-- We have noticed that there are values present 126 and 127 which are creating skewness in data. It can be possible that these values are wrongly entered.
-- So, to deal with this we will update 126 to 26 and 127 to 27.

UPDATE ecomm.eccomchurn
SET WarehouseToHome = 26
WHERE WarehouseToHome = 126;

UPDATE ecomm.eccomchurn
SET WarehouseToHome = 27
WHERE WarehouseToHome = 127;

/** Our values have been replaced and are now all in the same range.

Our data has been cleaned and is now ready to be explored for insight generation.**/

 /*****
 DATA EXPLORATION
 ******/
 
 -- 1. What is the overall customer churn rate?
 
 SELECT 
    TotalNumberofCustomers,
    TotalNumberofChurnedCustomers,
    CAST((TotalNumberofChurnedCustomers * 1.0 / TotalNumberofCustomers * 1.0) * 100
        AS DECIMAL (10 , 2 )) AS ChurnRate
FROM
    (SELECT 
        COUNT(*) AS TotalNumberofCustomers
    FROM
        ecomm.eccomchurn) AS Total,
    (SELECT 
        COUNT(*) AS TotalNumberofChurnedCustomers
    FROM
        ecomm.eccomchurn
    WHERE
        CustomerStatus = 'churned') AS Churned;

/* The churn rate of 16.84% indicates that a significant portion of customers in the 
dataset have ended their association with the company.*/

-- 2. How does the churn rate vary based on the preferred login device?

SELECT 
    PreferredLoginDevice,
    COUNT(*) AS TotalCustomers,
    SUM(churn) AS ChurnedCustomers,
    CAST(SUM(churn) * 1.0 / COUNT(*) * 100 AS DECIMAL (10 , 2 )) AS ChurnRate
FROM
    ecomm.eccomchurn
GROUP BY PreferredLoginDevice;

/*The preferred login device appears to have some influence on customer churn rates. 
Customers who prefer logging in using a computer have a slightly higher churn rate compared 
to customers who prefer logging in using their phones. This may indicate that customers who 
access the platform via a computer might have different usage patterns, preferences, or 
experiences that contribute to a higher likelihood of churn. Understanding these preferences 
can help businesses optimize their platform and user experience for different login devices, 
ensuring a seamless and engaging experience for customers.*/

-- 3.What is the distribution of customers across different city tiers?

SELECT 
    CityTier,
    COUNT(*) AS TotalCustomers,
    SUM(churn) AS ChurnedCustomers,
    CAST(SUM(churn) * 1.0 / COUNT(*) * 100 AS DECIMAL (10 , 2 )) AS ChurnRate
FROM
    ecomm.eccomchurn
GROUP BY CityTier
ORDER BY Churnrate DESC;

/* City Tier 1 is typically a major metropolitan area with the highest level of economic development and 
infrastructure. These cities are usually the most populous and have significant commercial and business centers.

City Tier 2 is considered smaller or secondary urban centers compared to Tier 1 cities.

City Tier 3 is further down the hierarchy and generally refers to smaller towns or cities with a smaller 
population and less developed infrastructure compared to Tier 1 and 2 cities.

The result suggests that the city tier has an impact on customer churn rates. Tier 1 cities have a relatively 
lower churn rate compared to Tier 2 and Tier 3 cities. This could be attributed to various factors such as 
competition, customer preferences, or the availability of alternatives in different city tiers.*/

-- 4. Is there any correlation between the warehouse-to-home distance and customer churn?

/*In order to answer this question, we will create a new column called “WarehouseToHomeRange” 
that groups the distance into very close, close, moderate, and far using the CASE statement.*/

ALTER TABLE ecomm.eccomchurn
ADD warehousetohomerange NVARCHAR(50);

UPDATE ecomm.eccomchurn
SET warehousetohomerange =
CASE 
    WHEN warehousetohome <= 10 THEN 'Very close distance'
    WHEN warehousetohome > 10 AND warehousetohome <= 20 THEN 'Close distance'
    WHEN warehousetohome > 20 AND warehousetohome <= 30 THEN 'Moderate distance'
    WHEN warehousetohome > 30 THEN 'Far distance'
END;

-- Finding a correlation between warehouse to home and churn rate.

SELECT 
    warehousetohomerange,
    COUNT(*) * 1.0 AS TotalCustomer,
    SUM(churn) AS ChurnedCustomers,
    CAST(SUM(churn) * 1.0 / COUNT(*) * 1.0 * 100 AS DECIMAL (10 , 2 )) AS ChurnRate
FROM
    ecomm.eccomchurn
GROUP BY warehousetohomerange
ORDER BY ChurnRate DESC;

/*The distance between the warehouse and the customer’s home seems to have some influence on customer 
churn rates. Customers residing in closer proximity to the warehouse tend to have lower churn rates, 
while customers living at further distances are more likely to churn. This suggests that factors such 
as delivery times, shipping costs, or convenience may play a role in customer retention. The company can 
utilize these insights to optimize its logistics and delivery strategies, ensuring better service for 
customers residing at further distances and implementing retention initiatives for customers in higher 
churn rate categories.*/

-- 5. Which is the most preferred payment mode among churned customers?

SELECT 
    PreferredPaymentMode,
    COUNT(*) * 1.0 AS TotalCustomer,
    SUM(churn) AS ChurnedCustomers,
    CAST(SUM(churn) * 1.0 / COUNT(*) * 1.0 * 100 AS DECIMAL (10 , 2 )) AS ChurnRate
FROM
    ecomm.eccomchurn
GROUP BY PreferredPaymentMode
ORDER BY ChurnRate DESC;

/*The most preferred payment mode among churned customers is cash on delivery. The preferred payment mode 
seems to have some influence on customer churn rates. Payment modes such as “Cash on Delivery” and “E-wallet” 
show higher churn rates, indicating that customers using these payment modes are more likely to churn. On the 
other hand, payment modes like “Credit Card” and “Debit Card” have relatively lower churn rates.*/

-- 6. What is the typical tenure for churned customers?

/* First, we will create a new column called “TenureRange” that groups the customer tenure into 6 months, 
1 year, 2 years, and more than 2 years using the CASE statement.*/

Alter table ecomm.eccomchurn
add TenureRange NVARCHAR(50);

UPDATE ecomm.eccomchurn 
SET 
    TenureRange = CASE
        WHEN tenure <= 6 THEN '6 Months'
        WHEN tenure > 6 AND tenure <= 12 THEN '1 Year'
        WHEN tenure > 12 AND tenure <= 24 THEN '2 Years'
        WHEN tenure > 24 THEN 'more than 2 years'
    END;
    
Select TenureRange, COUNT(*) * 1.0 AS TotalCustomer,
    SUM(churn) AS ChurnedCustomers,
    CAST(SUM(churn) * 1.0 / COUNT(*) * 1.0 * 100 AS DECIMAL (10 , 2 )) AS ChurnRate
FROM
    ecomm.eccomchurn
GROUP BY TenureRange
ORDER BY ChurnRate DESC;

/* This shows that customers who have been with the company for longer periods, specifically more than 
2 years in this case, have shown a lower likelihood of churn compared to customers in shorter tenure groups.*/

-- 7. Is there any difference in churn rate between male and female customers?

Select Gender, COUNT(*) * 1.0 AS TotalCustomer,
    SUM(churn) AS ChurnedCustomers,
    CAST(SUM(churn) * 1.0 / COUNT(*) * 1.0 * 100 AS DECIMAL (10 , 2 )) AS ChurnRate
FROM
    ecomm.eccomchurn
GROUP BY Gender
ORDER BY ChurnRate DESC;

/*Both male and female customers exhibit churn rates, with males having a slightly higher churn rate compared 
to females. However, the difference in churn rates between the genders is relatively small. This suggests that 
gender alone may not be a significant factor in predicting customer churn.*/

-- 8. How does the average time spent on the app differ for churned and non-churned customers?

Select CustomerStatus, avg(HourSpendOnApp) AS AverageHourSpentOnApp
from ecomm.eccomchurn
group by CustomerStatus;

/*Both churned and staying customers have the same average hours spent on the app; this indicates that the average app usage 
time does not seem to be a differentiating factor between customers who churned and those who stayed.*/

-- 9. Does the number of registered devices impact the likelihood of churn?

Select NumberOfDeviceRegistered, COUNT(*) * 1.0 AS TotalCustomer,
    SUM(churn) AS ChurnedCustomers,
    CAST(SUM(churn) * 1.0 / COUNT(*) * 1.0 * 100 AS DECIMAL (10 , 2 )) AS ChurnRate
FROM
    ecomm.eccomchurn
GROUP BY NumberOfDeviceRegistered
ORDER BY ChurnRate DESC;

/* There seems to be a correlation between the number of devices registered by customers and the likelihood of churn. 
Customers with a higher number of registered devices, such as 6 or 5, exhibit higher churn rates. On the other hand, 
customers with fewer registered devices, such as 2 or 1, show relatively lower churn rates.*/

-- 10. Which order category is most preferred among churned customers?

SELECT preferedordercat,
       COUNT(*) AS TotalCustomer,
       SUM(Churn) AS CustomerChurn,
       CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS Churnrate
FROM ecomm.eccomchurn
GROUP BY preferedordercat
ORDER BY Churnrate DESC;

/*The analysis suggests that different order categories have varying impacts on customer churn rates. Customers who 
primarily order items in the “Mobile Phone” category have the highest churn rate, indicating a potential need for 
targeted retention strategies for this group. On the other hand, the “Grocery” category exhibits the lowest churn rate, 
suggesting that customers in this category may have higher retention and loyalty.*/

-- 11. Is there any relationship between customer satisfaction scores and churn?

SELECT satisfactionscore,
       COUNT(*) AS TotalCustomer,
       SUM(Churn) AS CustomerChurn,
       CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS Churnrate
FROM ecomm.eccomchurn
GROUP BY satisfactionscore
ORDER BY Churnrate DESC;

/* The result indicates that customers with higher satisfaction scores, particularly those who rated their satisfaction 
as 5, have a relatively higher churn rate compared to other satisfaction score categories. This suggests that even highly 
satisfied customers may still churn, highlighting the importance of proactive customer retention strategies across all satisfaction levels.*/

-- 12. Does the marital status of customers influence churn behavior?

SELECT maritalstatus,
       COUNT(*) AS TotalCustomer,
       SUM(Churn) AS CustomerChurn,
       CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS Churnrate
FROM ecomm.eccomchurn
GROUP BY maritalstatus
ORDER BY Churnrate DESC;

/* Single customers have the highest churn rate compared to customers with other marital statuses. This indicates that single 
customers may be more likely to discontinue their relationship with the company. On the other hand, married customers have the 
lowest churn rate, followed by divorced customers.*/

-- 13. How many addresses do churned customers have on average?

SELECT AVG(numberofaddress) AS Averagenumofchurnedcustomeraddress
FROM ecomm.eccomchurn
WHERE customerstatus = 'stayed';

/* On average, customers who churned had four addresses associated with their accounts.*/

-- 14. Do customer complaints influence churned behavior?

SELECT complainrecieved,
       COUNT(*) AS TotalCustomer,
       SUM(Churn) AS CustomerChurn,
       CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS Churnrate
FROM ecomm.eccomchurn
GROUP BY complainrecieved
ORDER BY Churnrate DESC;

/*The fact that a larger proportion of customers who stopped using the company’s services registered 
complaints indicates the importance of dealing with and resolving customer concerns. This is vital for 
decreasing the number of customers who leave and building lasting loyalty. By actively listening to customer 
feedback, addressing their issues, and consistently working on improving the quality of their offerings, 
companies can create a better overall experience for customers. This approach helps to minimize the chances 
of customers leaving and fosters stronger relationships with them in the long run.*/

-- 15. How does the use of coupons differ between churned and non-churned customers?

SELECT customerstatus, SUM(couponused) AS SumofCouponUsed
FROM ecomm.eccomchurn
GROUP BY customerstatus;

/* The higher coupon usage among stayed customers indicates their higher level of loyalty and engagement with the company. 
By implementing strategies to reward loyalty, provide personalized offers, and maintain continuous engagement, the company 
can further leverage coupon usage as a tool to strengthen customer loyalty and increase overall customer retention.*/

-- 16. What is the average number of days since the last order for churned customers?

SELECT AVG(daysincelastorder) AS AverageNumofDaysSinceLastOrder
FROM ecomm.eccomchurn
WHERE customerstatus = 'churned';

/* The fact that churned customers have, on average, only had a short period of time since their last order indicates that 
they recently stopped engaging with the company. By focusing on enhancing the overall customer experience, implementing targeted 
retention initiatives, and maintaining continuous engagement, the company can work towards reducing churn and increasing customer loyalty.*/

-- 17. Is there any correlation between cashback amount and churn rate?

/*First, we will create a new column called “CashbackAmountRange” that groups the cashbackamount into low 
(less than 100), moderate (between 100 and 200), high( between 200 and 300), and very high (more than 300) using the CASE statement.*/

ALTER TABLE ecomm.eccomchurn
ADD cashbackamountrange NVARCHAR(50);

UPDATE ecomm.eccomchurn
SET cashbackamountrange =
CASE 
    WHEN cashbackamount <= 100 THEN 'Low Cashback Amount'
    WHEN cashbackamount > 100 AND cashbackamount <= 200 THEN 'Moderate Cashback Amount'
    WHEN cashbackamount > 200 AND cashbackamount <= 300 THEN 'High Cashback Amount'
    WHEN cashbackamount > 300 THEN 'Very High Cashback Amount'
END;

-- Finding the correlation between cashback amount range and churned rate

SELECT cashbackamountrange,
       COUNT(*) AS TotalCustomer,
       SUM(Churn) AS CustomerChurn,
       CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS Churnrate
FROM ecomm.eccomchurn
GROUP BY cashbackamountrange
ORDER BY Churnrate DESC;

/* Customers who received moderate cashback amounts had a relatively higher churn rate, while those who 
received higher and very high cashback amounts exhibited lower churn rates. Customers who received lower 
cashback amounts also had a 100% retention rate. This suggests that offering higher cashback amounts can positively influence 
customer loyalty and reduce churn.*/


/***

Thank you

              ***/
