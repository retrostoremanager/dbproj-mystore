CREATE TABLE [dbo].[SaleItem] (
    [Id]              INT             IDENTITY (1, 1) NOT NULL,
    [SaleId]          INT             NOT NULL,
    [InventoryItemId] INT             NOT NULL,
    [Quantity]        INT             NOT NULL,
    [UnitPrice]       DECIMAL (18, 2) NOT NULL,
    [TotalPrice]      DECIMAL (18, 2) NOT NULL,
    CONSTRAINT [PK_SaleItem] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_SaleItem_Sale] FOREIGN KEY ([SaleId]) REFERENCES [dbo].[Sale] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_SaleItem_InventoryItem] FOREIGN KEY ([InventoryItemId]) REFERENCES [dbo].[InventoryItem] ([Id])
);
GO

CREATE NONCLUSTERED INDEX [IX_SaleItem_SaleId]
    ON [dbo].[SaleItem]([SaleId] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_SaleItem_InventoryItemId]
    ON [dbo].[SaleItem]([InventoryItemId] ASC);
GO

