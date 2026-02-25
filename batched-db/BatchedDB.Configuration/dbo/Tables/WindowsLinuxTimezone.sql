CREATE TABLE [dbo].[WindowsLinuxTimezone]
(
	[WindowsId] NVARCHAR(255) NOT NULL,
	[LinuxTZ] NVARCHAR(255) NOT NULL,
    CONSTRAINT [FK_WindowsLinuxTimezone_WindowsId] FOREIGN KEY ([WindowsId]) REFERENCES [dbo].[timezone] ([ID])
)
