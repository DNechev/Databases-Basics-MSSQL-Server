CREATE TABLE Planes(
Id INT PRIMARY KEY IDENTITY(1, 1),
Name NVARCHAR(30) NOT NULL,
Seats INT NOT NULL,
[Range] INT NOT NULL
)

CREATE TABLE Flights(
Id INT PRIMARY KEY IDENTITY(1, 1),
DepartureTime DATETIME,
ArrivalTime DATETIME,
Origin NVARCHAR(50) NOT NULL,
Destination NVARCHAR(50) NOT NULL,
PlaneId INT NOT NULL
FOREIGN KEY(PlaneId)
REFERENCES Planes(Id)
)

CREATE TABLE Passengers(
Id INT PRIMARY KEY IDENTITY(1, 1),
FirstName NVARCHAR(30) NOT NULL,
LastName NVARCHAR(30) NOT NULL,
Age INT NOT NULL,
Address NVARCHAR(30) NOT NULL,
PassportId NVARCHAR(11) NOT NULL
)

CREATE TABLE LuggageTypes(
Id INT PRIMARY KEY IDENTITY(1,1),
[Type] NVARCHAR(30) NOT NULL
)

CREATE TABLE Luggages(
Id INT PRIMARY KEY IDENTITY(1,1),
LuggageTypeId INT NOT NULL
FOREIGN KEY (LuggageTypeId)
REFERENCES LuggageTypes(Id),
PassengerId INT NOT NULL
FOREIGN KEY (PassengerId)
REFERENCES Passengers(Id)
)

CREATE TABLE Tickets(
Id INT PRIMARY KEY IDENTITY(1,1),
PassengerId INT NOT NULL
FOREIGN KEY (PassengerId)
REFERENCES Passengers(Id),
FlightId INT NOT NULL
FOREIGN KEY (FlightId)
REFERENCES Flights(Id),
LuggageId INT NOT NULL
FOREIGN KEY (LuggageId)
REFERENCES Luggages(Id),
Price DECIMAL(15, 2) NOT NULL
)

--2

INSERT INTO Planes (Name, Seats, Range)
VALUES 
('Airbus 336', 112, 5132),
('Airbus 330', 432, 5325),
('Boeing 369', 231, 2355),
('Stelt 297', 254, 2143),
('Boeing 338', 165, 5111),
('Airbus 558', 387, 1342),
('Boeing 128', 345, 5541)

INSERT INTO LuggageTypes (Type)
VALUES
('Crossbody Bag'),
('School Backpack'),
('Shoulder Bag')


--3

UPDATE Tickets
SET Price = Price * 1.13
WHERE FlightId  = (SELECT F.Id
FROM Flights AS F
WHERE Destination = 'Carlsbad')

--4
DELETE FROM Tickets
WHERE FlightId = (SELECT F.Id
FROM Flights AS F
WHERE F.Destination = 'Ayn Halagim')

DELETE FROM Flights
WHERE Destination = 'Ayn Halagim'

--5

SELECT F.Origin, F.Destination
FROM Flights AS F
ORDER BY Origin, Destination

--6

SELECT *
FROM Planes AS P
WHERE P.Name LIKE '%tr%' 

--7

SELECT F.Id, SUM(T.Price) AS TotalPrice
FROM Flights AS F
JOIN Tickets AS T ON F.Id = T.FlightId
GROUP BY F.Id
ORDER BY TotalPrice DESC, F.Id

--8

SELECT TOP 10 P.FirstName, P.LastName, T.Price
FROM Passengers AS P
JOIN Tickets AS T ON T.PassengerId = P.Id
ORDER BY T.Price DESC , P.FirstName, P.LastName

--9

SELECT LT.Type, COUNT(LT.Id)
FROM Passengers AS P
JOIN Luggages AS L ON L.PassengerId = P.Id
JOIN LuggageTypes AS LT ON LT.Id = L.LuggageTypeId
GROUP BY LT.Type
ORDER BY COUNT(LT.Id) DESC, LT.Type


--10

SELECT CONCAT(P.FirstName, ' ', P.LastName) AS FullName, F.Origin AS Origin, F.Destination AS Destination
FROM Passengers AS P
JOIN Tickets AS T ON T.PassengerId = P.Id
JOIN Flights AS F ON T.FlightId = F.Id
ORDER BY FullName, Origin, Destination


--11

SELECT P.FirstName, P.LastName, P.Age
FROM Passengers AS P
LEFT JOIN Tickets AS T ON P.Id = T.PassengerId
WHERE T.FlightId IS NULL
ORDER BY P.Age DESC, P.FirstName, P.LastName

--12

SELECT P.PassportId, P.Address
FROM Passengers AS P
LEFT JOIN Luggages AS L ON P.Id = L.PassengerId
WHERE L.Id IS NULL
ORDER BY P.PassportId, P.Address


--13

SELECT P.FirstName, P.LastName, COUNT(T.Id) AS TotalTrips
FROM Passengers AS P
LEFT JOIN Tickets AS T ON P.Id = T.PassengerId
GROUP BY P.FirstName, P.LastName
ORDER BY TotalTrips DESC, P.FirstName, P.LastName

--14

SELECT CONCAT(P.FirstName, ' ', P.LastName) AS FullName, PL.Name, CONCAT(F.Origin, ' - ', F.Destination) AS Trip, LT.Type
FROM Passengers AS P
JOIN Tickets AS T ON P.Id = T.PassengerId
JOIN Flights AS F ON T.FlightId = F.Id
JOIN Planes AS PL ON F.PlaneId = PL.Id
JOIN Luggages AS L ON T.LuggageId = L.Id
JOIN LuggageTypes AS LT ON L.LuggageTypeId = LT.Id
ORDER BY FullName, PL.Name, F.Origin, F.Destination, LT.Type


--15

SELECT R.FirstName, R.LastName, R.Destination, R.Price
FROM (
SELECT P.FirstName, P.LastName, F.Destination, T.Price,
RANK () OVER (PARTITION BY P.Id ORDER BY T.Price DESC) AS RN
FROM Passengers AS P
JOIN Tickets AS T ON P.Id = T.PassengerId
JOIN Flights AS F ON T.FlightId = F.Id
) AS R
WHERE R.RN = 1
ORDER BY R.Price DESC, R.FirstName, R.LastName, R.Destination

--16

SELECT F.Destination, COUNT(T.Id) AS TripsCount
FROM Tickets AS T
RIGHT JOIN Flights AS F ON F.Id = T.FlightId
GROUP BY F.Destination
ORDER BY TripsCount DESC, F.Destination

--17

SELECT PL.Name, PL.Seats, COUNT(P.Id) AS PassengersCount
FROM Passengers AS P
LEFT JOIN Tickets AS T ON T.PassengerId = P.Id
JOIN Flights AS F ON F.Id = T.FlightId
RIGHT JOIN Planes AS PL ON F.PlaneId = PL.Id
GROUP BY PL.Name, PL.Seats
ORDER BY PassengersCount DESC, PL.Name, PL.Seats

--18

GO
CREATE FUNCTION udf_CalculateTickets(@origin NVARCHAR(MAX), @destination NVARCHAR(MAX), @peopleCount INT)
RETURNS VARCHAR(MAX)
AS BEGIN
	DECLARE @flightIdOrigin INT = (SELECT F.Id
							FROM Flights AS F
							WHERE F.Origin = @origin)

	DECLARE @flightIdDestination INT = (SELECT F.Id
							FROM Flights AS F
							WHERE F.Destination = @destination)

	IF(@flightIdDestination != @flightIdOrigin OR @flightIdDestination IS NULL OR @flightIdOrigin IS NULL)
	BEGIN
		RETURN 'Invalid flight!'
	END
	
	IF(@peopleCount <= 0)
	BEGIN
			RETURN 'Invalid people count!'
	END

	DECLARE @TicketPrice DECIMAL(15, 2) = (SELECT T.Price
							FROM Tickets AS T
							WHERE T.FlightId = @flightIdOrigin)


	DECLARE @TotalPrice DECIMAL(15, 2) = @TicketPrice * @peopleCount


	RETURN 'Total price ' + CAST(@TotalPrice as varchar(30))

	END


	SELECT dbo.udf_CalculateTickets('Kolyshley','Rancabolang', 33)

	DROP FUNCTION  dbo.udf_CalculateTickets
				

--19
GO
CREATE PROCEDURE usp_CancelFlights
AS BEGIN

UPDATE Flights
SET DepartureTime = (CASE 
					WHEN ArrivalTime > DepartureTime AND DepartureTime IS NOT NULL THEN NULL
					ELSE DepartureTime
					END),
ArrivalTime = (CASE
				WHEN ArrivalTime > DepartureTime AND ArrivalTime IS NOT NULL THEN NULL
				ELSE ArrivalTime
				END) 
END

EXEC usp_CancelFlights


--20

CREATE TABLE DeletedPlanes(
Id INT,
Name NVARCHAR(30),
Seats INT,
[Range] INT
)

GO
CREATE TRIGGER dbo.udf_Deleted_Planes
ON Planes
AFTER DELETE
AS BEGIN
	INSERT INTO DeletedPlanes(Id, Name, Seats, Range)
	SELECT D.Id, D.Name, D.Seats, D.Range
	FROM deleted AS D

END


SELECT Id, DATEPART(DAY, DepartureTime), DATEPART(DAY, ArrivalTime)
FROM Flights
WHERE ArrivalTime > DepartureTime
GROUP BY Id, ArrivalTime, DepartureTime