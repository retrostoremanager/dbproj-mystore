CREATE TABLE [dbo].[Customer] (
    [Id]                INT            IDENTITY (1, 1) NOT NULL,
    [FirstName]         NVARCHAR (100) NOT NULL,
    [LastName]          NVARCHAR (100) NOT NULL,
    [Email]             NVARCHAR (255) NULL,
    [Phone]             NVARCHAR (20)  NULL,
    [Address]           NVARCHAR (255) NULL,
    [City]              NVARCHAR (100) NULL,
    [State]             NVARCHAR (50)  NULL,
    [ZipCode]           NVARCHAR (10)  NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [LastModifiedDate]  DATETIME2 (7)  NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_Customer_Email]
    ON [dbo].[Customer]([Email] ASC) WHERE ([Email] IS NOT NULL);
GO

CREATE NONCLUSTERED INDEX [IX_Customer_LastName_FirstName]
    ON [dbo].[Customer]([LastName] ASC, [FirstName] ASC);
GO

