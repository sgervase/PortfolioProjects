/*

Data Cleaning in SQL Server

*/

SELECT *
FROM Nashville

---------------------------------------------------------------------------------

-- Change the date format of the SaleDate column.

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM Nashville

UPDATE Nashville
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE Nashville
ADD SaleDateConverted Date;

UPDATE Nashville
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDateConverted
FROM Nashville

---------------------------------------------------------------------------------

-- Populate the Property Address data where there is a "null."

SELECT *
FROM Nashville
WHERE PropertyAddress is null

SELECT *
FROM Nashville
--WHERE PropertyAddress is null
ORDER BY ParcelID

-- The Parcel ID is unique to Property Address, so use the parcel ID to help fill in missing Property Address values.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Nashville a
JOIN Nashville b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Nashville a
JOIN Nashville b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

---------------------------------------------------------------------------------

-- Separating PropertyAddress into individual columns (city and state separate from address)

SELECT PropertyAddress
FROM Nashville

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address
FROM Nashville

ALTER TABLE Nashville
ADD PropertySplitAddress Nvarchar(255);

UPDATE Nashville
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE Nashville
ADD PropertySplitCity Nvarchar(255);

UPDATE Nashville
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


SELECT *
FROM Nashville

---------------------------------------------------------------------------------

-- Separating Owner Address into columns (Address, City, State)

SELECT OwnerAddress
FROM Nashville

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Nashville


ALTER TABLE Nashville
ADD OwnerSplitAddress Nvarchar(255);

UPDATE Nashville
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE Nashville
ADD OwnerSplitCity Nvarchar(255);

UPDATE Nashville
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE Nashville
ADD OwnerSplitState Nvarchar(255);

UPDATE Nashville
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


SELECT *
FROM Nashville;

---------------------------------------------------------------------------------

-- Changing "Y" and "N" to "Yes" and "No", respectively

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM Nashville

UPDATE Nashville
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

---------------------------------------------------------------------------------

-- Removing Duplicate Values in data
-- Use CTE

WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num

FROM Nashville
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1

---------------------------------------------------------------------------------

-- Go back and remove unused columns

SELECT *
FROM Nashville

ALTER TABLE Nashville
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE Nashville
DROP COLUMN SaleDate