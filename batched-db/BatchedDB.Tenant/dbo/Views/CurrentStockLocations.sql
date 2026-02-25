CREATE VIEW dbo.CurrentStockLocations

AS

With stocklocations as (
						Select Distinct sm.SourceStockId, Width, Location
						From StockInventory si
						INNER JOIN StockMaterial sm on si.StockMaterialId = sm.Id
						Where si.StockUsed=0
						)
Select SourceStockId as StockNum, Width, STRING_AGG(Location, ',') as Locations-- WITHIN GROUP (Order by StockNum ASC) as Locations
From stocklocations
Group by SourceStockId, Width