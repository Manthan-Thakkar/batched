CREATE TABLE StagingRequirementGroup(
  Id					VARCHAR(36) PRIMARY KEY NOT NULL, 
  WorkcenterTypeId		VARCHAR(36) NULL,
  StagingRequirementId 	VARCHAR(36) NULL CONSTRAINT [FK_StagingRequirementGroup_StagingRequirementId] FOREIGN KEY REFERENCES StagingRequirement(Id),
  CreatedOnUTC			DATETIME,
  ModifiedOnUTC			DATETIME
)
