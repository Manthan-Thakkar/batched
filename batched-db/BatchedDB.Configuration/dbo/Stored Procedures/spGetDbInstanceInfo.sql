CREATE PROCEDURE [dbo].[spGetDbInstanceInfo]
@ErpId varchar(36),
@IsSharedInstanceRequested bit = 1
AS
BEGIN

Drop Table IF EXISTS #DbInstanceTemp

select top(1) count(TD.ID) as CurrentDbCount, DI.ID
into  #DbInstanceTemp
from DatabaseInstance DI
left join TenantDatabase TD on DI.ID = TD.DatabaseInstanceId
inner join InstanceType IT on DI.InstanceTypeId = IT.ID
where ((@IsSharedInstanceRequested = 1 OR (ErpId = @ErpId))) AND IsShared = @IsSharedInstanceRequested
group by DI.ID, TD.DatabaseInstanceId, IT.Threshold
having count(TD.ID) <= IT.Threshold

Select CurrentDbCount, ID,
'tbl_dbInstanceInfo' AS __dataset_tablename
from #DbInstanceTemp

Drop Table IF EXISTS #DbInstanceTemp;

END