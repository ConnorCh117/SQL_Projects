/*
=======================================
        Data Cleaning - Nashville
=======================================
*/

/* 
----------------------------------------
Standardize Date Format
----------------------------------------
*/

SELECT SaleDate, CONVERT(Date, SaleDate) AS SaleDateConverted
FROM Nashville;

UPDATE Nashville
SET SaleDate = CONVERT(Date, SaleDate);


/* 
----------------------------------------
Populate Property Address Data
----------------------------------------
*/

SELECT *
FROM Nashville
ORDER BY ParcelID;

SELECT 
    a.ParcelID, a.PropertyAddress, 
    b.ParcelID, b.PropertyAddress, 
    ISNULL(a.PropertyAddress, b.PropertyAddress) AS UpdatedPropertyAddress
FROM Nashville a
JOIN Nashville b
    ON a.ParcelID = b.ParcelID 
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Nashville a
JOIN Nashville b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;


/* 
----------------------------------------
Break Address into Individual Columns (Address, City, State)
----------------------------------------
*/

SELECT PropertyAddress
FROM Nashville;

-- Extract Address and City from PropertyAddress
SELECT 
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM Nashville;

ALTER TABLE Nashville
ADD Address NVARCHAR(255);

UPDATE Nashville
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE Nashville
ADD City NVARCHAR(255);

UPDATE Nashville
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Extract Owner Address, City, and State using PARSENAME
SELECT OwnerAddress
FROM Nashville;

SELECT 
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerStreet,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM Nashville;

ALTER TABLE Nashville
ADD Owner_Address NVARCHAR(255), Owner_City NVARCHAR(255), Owner_State NVARCHAR(255);

UPDATE Nashville
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

UPDATE Nashville
SET Owner_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE Nashville
SET Owner_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


/* 
----------------------------------------
Convert "Y" and "N" to "Yes" and "No" in "SoldAsVacant" field
----------------------------------------
*/

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS UpdatedSoldAsVacant
FROM Nashville;

UPDATE Nashville
SET SoldAsVacant = CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;


/* 
----------------------------------------
Remove Duplicates
----------------------------------------
*/

WITH RowNum_CTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
            ORDER BY UniqueID
        ) AS row_num
    FROM Nashville
)
SELECT *
FROM RowNum_CTE
WHERE row_num > 1
ORDER BY PropertyAddress;


/* 
----------------------------------------
Delete Unused Columns
----------------------------------------
*/

SELECT *
FROM Nashville;

ALTER TABLE Nashville
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
