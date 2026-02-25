CREATE TABLE [dbo].[S3DataDestination](
	[ID]								VARCHAR (36)	NOT NULL,
	[JobId]								VARCHAR (36)	NOT NULL CONSTRAINT [FK_S3DataDestination_JobId] FOREIGN KEY REFERENCES Job(Id),
	[BucketName]						NVARCHAR(256)	NOT NULL,
	[PayloadType]						NVARCHAR(256)	NOT NULL,
	[TransferTypeId]					VARCHAR(36)		CONSTRAINT [FK_S3DataDestination_TransferTypeId] FOREIGN KEY REFERENCES S3DataTransferType(Id),
	[CreatedOn]							DATETIME		NOT NULL,
    [ModifiedOn]						DATETIME		NULL,
    CONSTRAINT [PK_S3DataDestinationID] PRIMARY KEY NONCLUSTERED ([ID] ASC),
	CONSTRAINT USP_JobID UNIQUE (JobId)
);