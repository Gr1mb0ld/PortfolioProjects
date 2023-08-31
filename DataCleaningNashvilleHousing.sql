/*

Cleaning Data in SQL Queries

*/

select *
from PortfolioProject..NashvilleHousing


------------------- Standardize Date Format

select SaleDate, CONVERT(date,SaleDate)
from PortfolioProject..NashvilleHousing


update PortfolioProject..NashvilleHousing
set SaleDate = CONVERT(date, SaleDate)
---------------------------------------------------- it didn't work somehow

alter table PortfolioProject..NashvilleHousing
Add SaleDateConverted Date;

update PortfolioProject..NashvilleHousing
set SaleDateConverted = CONVERT(date, SaleDate)

select SaleDateConverted
from PortfolioProject..NashvilleHousing


------------------- Populate Property Address Data

select *
from PortfolioProject..NashvilleHousing
where PropertyAddress is null

select *
from PortfolioProject..NashvilleHousing
order by ParcelID
-- Rows with the same ParcelID has the same PropertyAddress that way can fill the null values in PropertyAddress with self join

select nullvalue.ParcelID, nullvalue.PropertyAddress, withvalue.ParcelID, withvalue.PropertyAddress, ISNULL(nullvalue.PropertyAddress, withvalue.PropertyAddress)
from PortfolioProject..NashvilleHousing nullvalue
join PortfolioProject..NashvilleHousing withvalue
	on nullvalue.ParcelID = withvalue.ParcelID
	and nullvalue.[UniqueID ] <> withvalue.[UniqueID ]
where nullvalue.PropertyAddress is null


update nullvalue
set PropertyAddress = ISNULL(nullvalue.PropertyAddress, withvalue.PropertyAddress)
from PortfolioProject..NashvilleHousing nullvalue
join PortfolioProject..NashvilleHousing withvalue
	on nullvalue.ParcelID = withvalue.ParcelID
	and nullvalue.[UniqueID ] <> withvalue.[UniqueID ]
where nullvalue.PropertyAddress is null

------------------ Breaking out Address into Individual Columns (Address, City, State)

-- PropertyAddress

select PropertyAddress
from PortfolioProject..NashvilleHousing

select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address,
CHARINDEX(',', PropertyAddress) -- in its own shows the ',' character place of number
from PortfolioProject..NashvilleHousing

select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
from PortfolioProject..NashvilleHousing

select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) as City		-- starting position after the ',' and 'space'
from PortfolioProject..NashvilleHousing

-- can't separate 2 values from 1 column -> need to create new column

Alter Table PortfolioProject..NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

update NashvilleHousing
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

Alter Table PortfolioProject..NashvilleHousing
Add PropertySplitCity Nvarchar(255)

update NashvilleHousing
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, len(PropertyAddress))

select *
from PortfolioProject..NashvilleHousing

-- OwnerAddress

select OwnerAddress
from PortfolioProject..NashvilleHousing
where OwnerAddress is not null


select 
Parsename(replace(OwnerAddress, ',', '.'), 3),  
Parsename(replace(OwnerAddress, ',', '.'), 2),
Parsename(replace(OwnerAddress, ',', '.'), 1)		-- parsname ranking positions backward so 1st is last
from PortfolioProject..NashvilleHousing
where OwnerAddress is not null


Alter Table PortfolioProject..NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

update NashvilleHousing
set OwnerSplitAddress = Parsename(replace(OwnerAddress, ',', '.'), 3)

Alter Table PortfolioProject..NashvilleHousing
Add OwnerSplitCity Nvarchar(255)

update NashvilleHousing
set OwnerSplitCity = Parsename(replace(OwnerAddress, ',', '.'), 2)

Alter Table PortfolioProject..NashvilleHousing
Add OwnerSplitState Nvarchar(255)

update NashvilleHousing
set OwnerSplitState = Parsename(replace(OwnerAddress, ',', '.'), 1)



----------------------- Change Y and N to Yes and NO in "Sold as Vacant" field

select distinct(SoldAsVacant), COUNT(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2

select SoldAsVacant
, case when SoldAsVacant = 'Y' then 'Yes'
	   when SoldAsVacant = 'N' then 'No'
	   else SoldAsVacant
	   end
from PortfolioProject..NashvilleHousing

update NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
	   when SoldAsVacant = 'N' then 'No'
	   else SoldAsVacant
	   end




------------- Remove Duplicates

select *,
	ROW_NUMBER() over (
	partition by parcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by
					uniqueID
				 ) row_num
from PortfolioProject..NashvilleHousing
--where row_num > 1							--cant use where for row_num so need to put it into a CTE
order by ParcelID


with RowNumCTE AS(
select *,
	ROW_NUMBER() over (
	partition by parcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by
					uniqueID
				 ) row_num
from PortfolioProject..NashvilleHousing
--order by ParcelID
)

select *
from RowNumCTE
where row_num > 1
order by PropertyAddress


with RowNumCTE AS(
select *,
	ROW_NUMBER() over (
	partition by parcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by
					uniqueID
				 ) row_num
from PortfolioProject..NashvilleHousing
--order by ParcelID
)

Delete
from RowNumCTE
where row_num > 1


select *
from PortfolioProject..NashvilleHousing



--------------Delete Unused Columns

select *
from PortfolioProject..NashvilleHousing


Alter Table PortfolioProject..NashvilleHousing
drop column PropertyAddress, OwnerAddress, TaxDistrict, SaleDate



--------------Calculating avg prices and number of sold properties by cities


select Distinct(PropertySplitCity), COUNT(PropertySplitCity)
from PortfolioProject..NashvilleHousing
group by PropertySplitCity
order by 2 desc

select Distinct(PropertySplitCity), sum(TotalValue)/count(ParcelID) AVGPrice, count(ParcelID)SoldProperties
from PortfolioProject..NashvilleHousing
where TotalValue is not null
group by PropertySplitCity
order by 2 desc

select PropertySplitCity, TotalValue
from NashvilleHousing 
where PropertySplitCity = 'Nolensville' and TotalValue is not null

--and by streets

select Distinct(PropertySplitAddress), sum(TotalValue)/count(ParcelID) AVGPrice
from PortfolioProject..NashvilleHousing
where TotalValue is not null
group by PropertySplitAddress
order by 2 desc

create view PropertyCountAndAVGPrices as
select Distinct(PropertySplitCity), sum(TotalValue)/count(ParcelID) AVGPrice, count(ParcelID) SoldProperties
from PortfolioProject..NashvilleHousing
where TotalValue is not null
group by PropertySplitCity
--order by 2 desc

select *
from PropertyCountAndAVGPrices
