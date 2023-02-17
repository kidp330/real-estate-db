-- Setup
IF EXISTS(select * from sys.databases where name='RealEstateDatabase')
	DROP DATABASE RealEstateDatabase
CREATE DATABASE RealEstateDatabase

DROP VIEW [Active Offers], [Recent Price Changes], [Owners By Houses Sold], [Districts By Listed Locations]
DROP FUNCTION [Time Window Price Changes]
DROP TABLE [Closed Offers], [Price Changes], Basements, Garages, Offers, Houses, Owners, Locations, Districts, Cities
-- Table creation
CREATE TABLE Owners (
	Owner_id INT PRIMARY KEY,
	Phone NVARCHAR(12),
	Email NVARCHAR(50),
)

CREATE TABLE Cities (
	City_id INT PRIMARY KEY,
	[City Name] NVARCHAR(50) NOT NULL,
)

CREATE TABLE Districts (
	District_id INT PRIMARY KEY,
	City_id INT REFERENCES Cities (City_id),
	[District Name] NVARCHAR(50) NOT NULL,
)

CREATE TABLE Locations (
	Location_id INT PRIMARY KEY,
	District_id INT REFERENCES Districts (District_id),
	Longtitude FLOAT NOT NULL,
	Latitude FLOAT NOT NULL,
)

CREATE TABLE Houses (
	House_id INT PRIMARY KEY,
	[Number of rooms] INT NOT NULL,
	[Number of bedrooms] INT,
	[Number of kitchens] INT,
	[Area] FLOAT NOT NULL,
	[Lot Area] FLOAT NOT NULL,
	[Year Built] INT NOT NULL,
	Location_id INT REFERENCES Locations (Location_id),
	Condition NVARCHAR(1),
)

CREATE TABLE Offers (
	Offer_id INT PRIMARY KEY,
	House_id INT REFERENCES Houses (House_id), -- ON DELETE CASCADE ON UPDATE CASCADE
	Owner_id INT REFERENCES Owners (Owner_id),
	Open_dt DATE NOT NULL,
	Price MONEY NOT NULL,
)

CREATE TABLE [Closed Offers] (
	Offer_id INT REFERENCES Offers (Offer_id),
	Close_dt DATE NOT NULL,
	Reason NVARCHAR(5) -- Sold, Owner deleted, etc.
	CONSTRAINT CO_COMPOSITE PRIMARY KEY (Offer_id, Close_dt)
)

CREATE TABLE [Price Changes] (
	Offer_id INT REFERENCES Offers (Offer_id),
	Modification_ts DATE NOT NULL,
	Price MONEY NOT NULL,
	CONSTRAINT PC_COMPOSITE PRIMARY KEY (Offer_id, Modification_ts)
)

CREATE TABLE Basements (
	House_id INT PRIMARY KEY REFERENCES Houses (House_id),
	Condition NVARCHAR(2) NOT NULL,
	Area FLOAT NOT NULL
)

CREATE TABLE Garages (
	House_id INT PRIMARY KEY REFERENCES Houses (House_id),
	[Garage Type] NVARCHAR(20) NOT NULL,
	[Car Capacity] INT NOT NULL,
	Area INT NOT NULL,
	Condition NVARCHAR(2) NOT NULL
)

-- Views
GO
CREATE VIEW [Active Offers]
AS
	SELECT *
	FROM Offers
	WHERE Offer_id NOT IN (
		SELECT Offer_id FROM [Closed Offers]
	)

GO
CREATE VIEW [Recent Price Changes] (Offer_id, [Last Price Change])
AS
	SELECT PC.Offer_id, MAX(PC.Modification_ts)
	FROM [Price Changes] AS PC
	JOIN [Active Offers] AS AO
	ON PC.Offer_id = AO.Offer_id
	GROUP BY PC.Offer_id

-- Meant to be ordered, but ordered views are not supported
GO
CREATE VIEW [Owners By Houses Sold] (Owner_id, [Number of Houses Sold])
AS
	SELECT Owners.Owner_id,
	CASE WHEN cnt IS NULL THEN 0 ELSE cnt END AS cnt_with_zero
	FROM
	(
		SELECT Owners.Owner_id,
		COUNT(*) AS cnt
		FROM Owners
		LEFT JOIN Offers
		ON Owners.Owner_id = Offers.Owner_id
		LEFT JOIN [Closed Offers] AS CO
		ON CO.Offer_id = Offers.Offer_id
		WHERE Reason = 'S'
		GROUP BY Owners.Owner_id
	) AS Counted
	RIGHT JOIN Owners
	ON Counted.Owner_id = Owners.Owner_id
-- Functions

GO
CREATE VIEW [Districts By Listed Locations] ([District Name], [City Name], [Number of locations])
AS
	WITH distr_to_num_locs (District_id, [Number of locations]) AS (
		SELECT Districts.District_id,
		CASE WHEN cnt IS NULL THEN 0 ELSE cnt END
		FROM Districts
		LEFT JOIN (
			SELECT D.District_id, COUNT(*) AS cnt
			FROM Districts AS D
			JOIN Locations
			ON D.District_id = Locations.District_id
			GROUP BY D.District_id
		) AS Naive_Cnt
		ON Districts.District_id = Naive_Cnt.District_id
	)
	SELECT [District Name], [City Name], [Number of locations]
	FROM Districts
	JOIN Cities
	ON Districts.City_id = Cities.City_id
	JOIN distr_to_num_locs
	ON distr_to_num_locs.District_id = Districts.District_id
GO
CREATE FUNCTION [Time Window Price Changes]
	( @start DATE,
	  @end   DATE
	)
RETURNS TABLE
AS
RETURN (
	WITH [Last Price Change Before start] AS (
		SELECT Offer_id, MAX(Modification_ts) AS [Price Change]
		FROM [Price Changes]
		WHERE Modification_ts <= @start
		GROUP BY Offer_id
	)
	SELECT *
	FROM [Price Changes] AS PC
	WHERE Modification_ts <= @end
	AND Modification_ts >= (
		SELECT [Price Change] 
		FROM [Last Price Change Before start] AS CTE
		WHERE CTE.Offer_id = PC.Offer_id
	)
)

-- Triggers
GO
CREATE TRIGGER [Validate Owner Data]
ON Owners
AFTER INSERT, UPDATE
AS
	IF EXISTS (
				SELECT *
				FROM INSERTED
				WHERE (Phone IS NULL AND Email IS NULL)
				   OR (Email IS NOT NULL AND Email NOT LIKE '%_@%_.__%')
			  )
		THROW 60001, 'Found invalid data in Owners table. Aborting', 2

GO
CREATE TRIGGER [Close offers of deleted owner]
ON Owners
AFTER DELETE
AS
	INSERT INTO [Closed Offers]
	SELECT Offer_id, GETDATE(), 'OD'
	FROM [Active Offers]
	JOIN INSERTED
	ON [Active Offers].Owner_id = INSERTED.Owner_id

GO
CREATE TRIGGER [Block deletion of referenced locations]
ON Locations
AFTER DELETE
AS
	IF EXISTS (
				SELECT * 
				FROM Houses
				JOIN deleted
				ON Houses.Location_id = deleted.Location_id
			  )
		THROW 60000, 'Attempted to delete locations bound to houses present in the database. Aborting', 1

GO
CREATE TRIGGER [Insert new offers into price changes]
ON Offers
AFTER INSERT
AS
	INSERT INTO [Price Changes]
	SELECT Offer_id, Open_dt, Price
	FROM INSERTED

GO
CREATE TRIGGER [Validate dates of inserted price changes]
ON [Price Changes]
AFTER INSERT
AS
	IF EXISTS (
				SELECT *
				FROM INSERTED
				WHERE Modification_ts <= (
					SELECT MAX(Modification_ts) FROM (
						SELECT * FROM [Price Changes]
						EXCEPT
						SELECT * FROM INSERTED
					) AS _
				)
			  )
		THROW 60002, 'Inserted data is older than the one already present. Aborting', 3

-- Populating the database
GO
INSERT INTO Owners (Owner_id, Phone, Email) VALUES
(1, '641-583-9397', 'kkitsuragi@gmail.com'),
(2, '712-870-7641', NULL),
(3, NULL, 'klaasjeA@temporary-mail.net')

GO
INSERT INTO Cities (City_id, [City Name]) VALUES
(1, 'Ames'),
(2, 'Des Moines'),
(3, 'Chicago')

GO
INSERT INTO Districts (District_id, City_id, [District Name]) VALUES
(1, 1, 'Veenker'),
(2, 1, 'Brookside'),
(3, 2, 'Projects'),
(4, 2, 'Windsor Heights'),
(5, 3, 'Chinatown'),
(6, 3, 'Evanston')

GO
INSERT INTO Locations (Location_id, District_id, Longtitude, Latitude) VALUES
(1, 1, -93.4004285, 41.9055594),
(2, 2, -93.6819404, 42.0190166),
(3, 1, -93.3987969, 41.9049386),
(4, 4, -93.7090162, 41.5996038)

GO
INSERT INTO Houses (House_id, [Number of rooms], [Number of bedrooms], [Number of kitchens], Area, [Lot Area], [Year Built], Location_id) VALUES
(1, 5, 2, 1, 854, 6120, 1929, 1),
(2, 4, 1, 1, 520, 6120, 1998, 2),
(3, 6, 3, 1, 1285, 8635, 1948, 3),
(4, 5, 2, 1, 1176, 6240, 1971, 4)

GO
INSERT INTO Basements (House_id, Condition, Area) VALUES
(2, 'TA', 520),
(3, 'TA', 672),
(4, 'TA', 816)

GO
INSERT INTO Garages (House_id, [Garage Type], [Car Capacity], Area, Condition) VALUES
(1, 'Detached', 2, 576, 'TA'),
(3, 'Detached', 1, 240, 'TA'),
(4, 'Detached', 2, 528, 'TA')

GO
INSERT INTO Offers (Offer_id, House_id, Owner_id, Open_dt, Price) VALUES
(4, 1, 3, '2008-01-31', 130000),
(2, 3, 2, '2008-05-01', 75000),
(1, 2, 1, '2008-07-11', 140000),
(3, 4, 2, '2008-09-14', 120000)

GO
INSERT INTO [Price Changes] (Offer_id, Modification_ts, Price) VALUES
(3, '2009-11-11', 110000),
(3, '2009-01-03', 100000),
(1, '2009-07-30', 138000),
(1, '2009-09-02', 130000),
(4, '2010-02-15', 120000),
(1, '2010-02-16', 115000),
(2, '2010-06-06', 80000)

GO
INSERT INTO [Closed Offers] (Offer_id, Close_dt, Reason) VALUES
(3, '2007-05-12', 'S'),
(1, '2008-02-28', 'S'),
(4, '2008-06-01', 'O')
