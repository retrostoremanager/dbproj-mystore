CREATE TABLE [dbo].[Employee] (
    [Id]                INT            IDENTITY (1, 1) NOT NULL,
    [FirstName]         NVARCHAR (100) NOT NULL,
    [LastName]          NVARCHAR (100) NOT NULL,
    [Email]             NVARCHAR (255) NOT NULL,
    [Phone]             NVARCHAR (20)  NULL,
    [Role]              NVARCHAR (50)  NOT NULL,
    [HireDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NOT NULL DEFAULT 1,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [LastModifiedDate]  DATETIME2 (7)  NULL,
    CONSTRAINT [PK_Employee] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_Employee_Email]
    ON [dbo].[Employee]([Email] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_Employee_IsActive]
    ON [dbo].[Employee]([IsActive] ASC);
GO

