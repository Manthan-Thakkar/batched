CREATE TABLE [dbo].TicketScore
(
	TicketId			VARCHAR(36)		NOT NULL CONSTRAINT [FK_TicketScore_TicketMasterId] FOREIGN KEY REFERENCES TicketMaster(Id),
	[RevenueScore]		Numeric (34,12) Not NULL,
	[DueDateScore]		Numeric(12,2)	Not Null,
	[CustomerRankScore]	INT				NOT NULL,
	[PriorityScore]		INT				NOT NULL,
	CreatedOn			DATETIME		NOT NULL,
	ModifiedOn			DATETIME		NOT NULL,
)