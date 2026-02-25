CREATE PROCEDURE spGetTenantConfigValue(
 @name NVARCHAR(300)
)
AS
BEGIN
	select cv.Value , 'tbl_tenantConfig' AS __dataset_tableName
	from ConfigurationValue cv
	inner join ConfigurationMaster cm
   		on cv.ConfigId = cm.Id
	Where name = @name
	and cm.IsDisabled = 0
	and cv.IsDisabled = 0;
END