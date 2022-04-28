
--------------------------------------------------------DATA CLEANING-----------------------------------------------------------------------
-- 1.  FORMAT STANDARDIZING 
-- 2.  POPULATING WITH RELEVANT DATA 
-- 3.  PARSING DATA FOR BETTER VISUALIZATION 
-- 4.  NORMALISING DATA
-- 5.  DELETING & REMOVING DUPLICATES 






select * from Portfolioprojects..[Nashville Housing] 


-- 1   standardize the date format 


select SaleDate,CONVERT(Date,SaleDate) from Portfolioprojects..[Nashville Housing]

--update Portfolioprojects..[Nashville Housing]
--SET SaleDate = CONVERT(Date,SaleDate)

--since this update is not working , i.e changing the  data of a column , we can use alter and create a new column ,
--later we can use this created one into convert option

alter table Portfolioprojects..[Nashville Housing]

add saledateconverted date

update Portfolioprojects..[Nashville Housing]
SET saledateconverted = CONVERT(Date,SaleDate)




--  2    populate property address data 

-- here we have propertyaddress filed which is null , so take the address from other unique id field with same parcel id 

-- we can take this parcel id  ,  as a basic stuff , so we can do self join using the same parcel id and different unique id 


select  a.[UniqueID ],a.ParcelID,b.[UniqueID ],b.ParcelID ,ISNULL(a.PropertyAddress,b.PropertyAddress) from Portfolioprojects..[Nashville Housing] a
join Portfolioprojects..[Nashville Housing] b
on a.ParcelID = b.ParcelID and a.[UniqueID ]<> b.[UniqueID ]
where a.PropertyAddress is  null


update a
SET a.PropertyAddress =ISNULL(a.PropertyAddress,b.PropertyAddress)
from Portfolioprojects..[Nashville Housing] a 
join Portfolioprojects..[Nashville Housing] b
on a.ParcelID = b.ParcelID and a.[UniqueID ]<> b.[UniqueID ]
where a.PropertyAddress is  null





  --------- 3. seperate the names in address using substring and parse 

select PropertyAddress from Portfolioprojects..[Nashville Housing]
  
-- this address has address together with city name ' so we need to seperate them into two columns 

select PropertyAddress , substring(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as [Corrected Address]
from Portfolioprojects..[Nashville Housing]

 select PropertyAddress , substring(PropertyAddress,CHARINDEX(',',PropertyAddress)+1 , len(PropertyAddress)) as [Corrected city]  
 from Portfolioprojects..[Nashville Housing]


alter table Portfolioprojects..[Nashville Housing]

add Corrected_Address Nvarchar(255);

update Portfolioprojects..[Nashville Housing]
SET Corrected_Address = substring(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)


alter table Portfolioprojects..[Nashville Housing]
add Corrected_city  Nvarchar(255);

update Portfolioprojects..[Nashville Housing]
SET Corrected_city = substring(PropertyAddress,CHARINDEX(',',PropertyAddress)+1 , len(PropertyAddress)) 


select * from Portfolioprojects..[Nashville Housing]



---- now we sue easier method  parse name , which needs   . as delimiter

select PropertyAddress, PARSENAME(REPLACE(PropertyAddress,',','.'),2) from Portfolioprojects..[Nashville Housing]

alter table Portfolioprojects..[Nashville Housing]

add address_parsed Nvarchar(255);

alter table Portfolioprojects..[Nashville Housing]

add address_city_parsed Nvarchar(255);


update Portfolioprojects..[Nashville Housing]

set address_parsed =  PARSENAME(REPLACE(PropertyAddress,',','.'),2);


update Portfolioprojects..[Nashville Housing]

set address_city_parsed = PARSENAME(REPLACE(PropertyAddress,',','.'),1) ;





----------------4.converting y as yes and n as no in sold as vacant 

select distinct(SoldAsVacant) from Portfolioprojects..[Nashville Housing]


select SoldAsVacant , case when SoldAsVacant ='Y'
then 'Yes'
when SoldAsVacant ='N' then 'No'
else SoldAsVacant  end 
from Portfolioprojects
..[Nashville Housing] 

update Portfolioprojects..[Nashville Housing]

set SoldAsVacant = case when SoldAsVacant ='Y'
then 'Yes'
when SoldAsVacant ='N' then 'No'
else SoldAsVacant  end 
 






 ---------5 removing duplicates 

 -- for this we need to make a partition across rows, sucht that when we see a row with same details for almost few columns , we can increment it and delete them 

 -- we create a temp table called cte and do our own partition 


 with RowNumCTE as (
 select * ,
 row_number() over(
 
 partition by parcelID, SaleDate,SalePrice order by uniqueID)row_num 
 from Portfolioprojects..[Nashville Housing]

 )

 select *
 from RowNumCTE 
 where row_num >1




 -- 6.delete the unused columns 



 select * from Portfolioprojects..[Nashville Housing]

 
 alter table Portfolioprojects..[Nashville Housing]
 drop column  SaleDate   


 --Since renaming not working, i have choose to copy content to new table and deleted the old onw-----------------------------

-- select * from Portfolioprojects..[Nashville Housing]
 
 --alter table Portfolioprojects..[Nashville Housing]

 --select * from Portfolioprojects..[Nashville Housing]

-- alter table Portfolioprojects..[Nashville Housing]
-- add Saledate Date

-- alter table Portfolioprojects..[Nashville Housing]
 --sp_rename 'Portfolioprojects..[Nashville Housing].saledateconverted', 'SaleDate', 'COLUMN'

 --EXEC SP_RENAME 'Nashville Housing.saledateconverted' , 'SaleDate'

 update  Portfolioprojects..[Nashville Housing]
 set Saledate  =saledateconverted

 select * from Portfolioprojects..[Nashville Housing]


 alter table  Portfolioprojects..[Nashville Housing] 

 drop column saledateconverted




 ---------- checking the cost level with Average saleprice------------------------

 alter table  Portfolioprojects..[Nashville Housing] 
 add Price_type Nvarchar(255);

 Update Portfolioprojects..[Nashville Housing] 

 set Price_type  = case when SalePrice > (select AVG(SalePrice) from Portfolioprojects..[Nashville Housing]) then 'COSTLY'
 when SalePrice = (select AVG(SalePrice) from Portfolioprojects..[Nashville Housing]) then 'AVERAGE'
 else  'cheap'
 end
 --group by Price_type

