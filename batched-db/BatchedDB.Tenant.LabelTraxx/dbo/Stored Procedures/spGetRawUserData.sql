CREATE PROCEDURE [dbo].[spGetRawUserData]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Number, FirstName, LastName, E_Mail_Address, Phone, Inactive from Associate
	where not(LEN(IsNull(FirstName,'')) <=1 or LEN(IsNull(LastName,'')) <=1);

END
