CREATE TABLE [dbo].[GameInventory] (
    [Id]                INT             IDENTITY (1, 1) NOT NULL,
    [Name]              NVARCHAR (255)  NOT NULL,
    [Category]          NVARCHAR (100)  NOT NULL,
    [Quantity]          INT             NOT NULL DEFAULT 0,
    [SellPrice]         DECIMAL (18, 2) NOT NULL,
    [BuyPrice]          DECIMAL (18, 2) NULL,
    [Condition]         NVARCHAR (50)  NOT NULL,
    [GameId]            NVARCHAR (100) NULL,
    [HasBox]            BIT             NOT NULL DEFAULT 0,
    [HasInstructions]  BIT             NOT NULL DEFAULT 0,
    [HasGame]           BIT             NOT NULL DEFAULT 1,
    [HasInserts]        BIT             NOT NULL DEFAULT 0,
    [HasOther]          BIT             NOT NULL DEFAULT 0,
    [Notes]             NVARCHAR (MAX)  NULL,
    [AddedDate]         DATETIME2 (7)   NOT NULL,
    [LastModifiedDate]  DATETIME2 (7)   NULL,
    CONSTRAINT [PK_GameInventory] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_GameInventory_GameEncyclopedia] FOREIGN KEY ([GameId]) REFERENCES [dbo].[GameEncyclopedia] ([Id])
);
GO

CREATE NONCLUSTERED INDEX [IX_GameInventory_GameId]
    ON [dbo].[GameInventory]([GameId] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_GameInventory_Category]
    ON [dbo].[GameInventory]([Category] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_GameInventory_Name]
    ON [dbo].[GameInventory]([Name] ASC);
GO

