IF NOT EXISTS (SELECT 1 FROM [dbo].[DslMetaData] WHERE [Name] = 'ColorByUnit')
BEGIN
    INSERT INTO [dbo].[DslMetaData] ([Id], [Name], [Multiplicity], [DataType], [Entity], [IsDisabled], [CreatedOn], [ModifiedOn], [Category])
    VALUES (NEWID(), 'ColorByUnit', 0, 'string', 'Ticket', 0, GETUTCDATE(), GETUTCDATE(), 'Attribute');
END