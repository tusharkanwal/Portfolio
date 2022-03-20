-- Query to view the whole dataset to get a general overview about the data

select * from portfolio.public.housing;


-- Checking how many Property Addresses are NULL/have no value

select count(*)
from portfolio.public.housing 
where propertyaddress is null;
--there were total 29 null entries 


-- Finding fields based on which Property Address field can be populated

select *
from portfolio.public.housing 
order by ParcelID,propertyaddress desc;
-- Here we could conclude that identical Property Addresses have the same ParcelID hence, ParcelID can be used to refer and fill in the Property Addresses


-- Performing a self-join to confirm the above statement

select a.parcelid,a.propertyaddress,b.parcelid,b.propertyaddress
from portfolio.public.housing  a 
join portfolio.public.housing  b 
on a.parcelid=b.parcelid 
and a.uniqueid<>b.uniqueid 
where a.propertyaddress is null;


-- Populating the NULL values with Property Address

Update housing 
set PropertyAddress=coalesce(a.PropertyAddress,b.PropertyAddress)
from portfolio.public.housing  a 
join housing b 
on a.ParcelID = b.ParcelID 
and a.uniqueid<>b.uniqueid 
where a.PropertyAddress is null;


Select PropertyAddress
From portfolio.public.housing;


-- Sample query to view how the Property Address will be split

select 
substring(PropertyAddress, 1, position(',' in PropertyAddress)-1 ) as address,
substring(PropertyAddress, position(',' in PropertyAddress) + 1) as address, 
length(PropertyAddress) 
from portfolio.public.housing;


-- Altering/Updating the table with split Property Address

alter table portfolio.public.housing 
add column splitaddress varchar(255);

alter table portfolio.public.housing 
add column city varchar(255);

update portfolio.public.housing  
set splitaddress=substring(PropertyAddress, 1, position(',' in PropertyAddress)-1 );

update portfolio.public.housing  set city=substring(PropertyAddress, position(',' in PropertyAddress) + 1);


select * from portfolio.public.housing; 

select OwnerAddress
from portfolio.public.housing;


-- Splitting the Owner Address into different columns

select
split_part(OwnerAddress, ',', 1)as address
,split_part(OwnerAddress, ',', 2) as city
,split_part(OwnerAddress, ',', 3)as state
from portfolio.public.housing;


-- Entring the split data into the table in different columns

alter table portfolio.public.housing 
add column OwnerSplitAddress varchar(255);

update portfolio.public.housing 
set OwnerSplitAddress = split_part(OwnerAddress, ',', 1);


alter table portfolio.public.housing 
add column OwnerSplitCity varchar(255);

update portfolio.public.housing 
set OwnerSplitCity = split_part(OwnerAddress, ',', 2);


alter table portfolio.public.housing 
add OwnerSplitState varchar(255);

update portfolio.public.housing 
set OwnerSplitState = split_part(OwnerAddress, ',', 3);

select * from portfolio.public.housing;


-- Viewing the split data enter to ensure correct entries

select ownersplitstate, ownersplitcity, ownersplitaddress 
from portfolio.public.housing
order by ownersplitcity;


-- Viewing the distinct entries in SoldAsVacant column

select distinct(SoldAsVacant), count(SoldAsVacant)
From portfolio.public.housing 
group by SoldAsVacant
order by 2;
-- 4 distinct entries: Y, N, Yes and No


-- Running sample query to ensure correct entries in the table

select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
end
from portfolio.public.housing;


-- Updating column entries

update portfolio.public.housing 
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
end;


-- Checking for duplicate entries in the data

WITH RowNumCTE as(
select *,
row_number() over (
partition by ParcelID,
PropertyAddress,
SalePrice,
SaleDate,
LegalReference
order by
UniqueID
) 
row_num
from portfolio.public.Housing
)
select *
from RowNumCTE
where row_num > 1
order by PropertyAddress;


-- Deleting obsolete columns

select *
from PortfolioProject.dbo.NashvilleHousing;


alter table portfolio.public.housing 
drop column OwnerAddress,
drop column propertyaddress;