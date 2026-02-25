CREATE TABLE [dbo].[DslMetaData]
		(
			[Id]			VARCHAR(36)		NOT NULL,
			[Name]			VARCHAR(100)	NOT NULL,
			Multiplicity	BIT				NOT NULL,
			DataType		VARCHAR(100)  	NOT NULL,
			Entity			VARCHAR(100)	NOT NULL,
			IsDisabled		BIT      		NOT NULL,
			CreatedOn		DATETIME		NOT NULL,
			ModifiedOn		DATETIME		NOT NULL,
			Category        VARCHAR (20),
			CONSTRAINT [PK_DslMetaData_Id] PRIMARY KEY([Id])
		);
