-- Cleaning Data in SQL Queries -- 
Select *
From LisaPortfolioProject.dbo.HousingData

-- Standarize Format --
Select *
From LisaPortfolioProject.dbo.HousingData
-- Where PropertyAddress is null --
order by ParcelID

-- Find dupilcate ParcelID that have a property address and those that have a property address that is null
-- Joined tables --
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From LisaPortfolioProject.dbo.HousingData a
JOIN LisaPortfolioProject.dbo.HousingData b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- Update table --
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From LisaPortfolioProject.dbo.Housingdata a
JOIN LisaPortfolioProject.dbo.Housingdata b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- Check update --
Select *
From LisaPortfolioProject.dbo.HousingData

-- Seperate Address into Individual Columns (Address, City, State)  --
Select PropertyAddress
From LisaPortfolioProject.dbo.HousingData

-- Adjusted for new table name --
-- Take out commas between addresses --
-- Create 2 columns (Address and City) --
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM LisaPortfolioProject.dbo.HousingData;

-- Add new columns to store split address and city --
ALTER TABLE LisaPortfolioProject.dbo.HousingData
ALTER COLUMN PropertySplitAddress NVARCHAR(255);

UPDATE LisaPortfolioProject.dbo.HousingData
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE LisaPortfolioProject.dbo.HousingData
ALTER COLUMN PropertySplitCity NVARCHAR(255);

UPDATE LisaPortfolioProject.dbo.HousingData
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Modify and add columns for Owner's split address, city, and state  --
ALTER TABLE LisaPortfolioProject.dbo.HousingData
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(255);

-- Easier way to execute not using substring --
UPDATE LisaPortfolioProject.dbo.HousingData
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Test --
SELECT *
FROM LisaPortfolioProject.dbo.HousingData

-- Change Y and N to Yes and No in "Sold as Vacant" field --
-- Determined 52 at "y", 4623 at "yes", 399 at "n", and 51403 at "no" --
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM LisaPortfolioProject.dbo.HousingData
Group by SoldAsVacant
Order by 2

UPDATE LisaPortfolioProject.dbo.HousingData
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- Test --
SELECT *
FROM LisaPortfolioProject.dbo.HousingData

-- Remove Duplicates Columns --
-- Specify the table name --
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                        PropertyAddress,
                        SalePrice,
                        SaleDate,
                        LegalReference
            ORDER BY
                UniqueID
        ) row_num
    FROM LisaPortfolioProject.dbo.HousingData
)
DELETE FROM RowNumCTE
WHERE row_num > 1;

-- Delete Unused Columns --
ALTER TABLE LisaPortfolioProject.dbo.HousingData
DROP COLUMN OwnerAddress,
            TaxDistrict,
            PropertyAddress,
            SaleDate;

-- Test --
SELECT *
FROM LisaPortfolioProject.dbo.HousingData