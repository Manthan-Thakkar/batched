CREATE FUNCTION [dbo].[udf_GetAlphanumericString] (@inputString VARCHAR(256)) 

RETURNS VARCHAR(256)

AS 
-- To separate special characters from a given string.
BEGIN
 DECLARE @alphaNumericPattern VARCHAR(256) = '%[^0-9A-Z]%'
 
 WHILE PATINDEX(@alphaNumericPattern,@inputString) > 0

 SET @inputString = STUFF(@inputString,PATINDEX(@alphaNumericPattern,@inputString),1,'')

 RETURN @inputString

END;