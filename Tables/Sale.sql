CREATE TABLE [dbo].[Sale] (
    [Id]            INT             IDENTITY (1, 1) NOT NULL,
    [CustomerId]    INT             NOT NULL,
    [EmployeeId]    INT             NULL,
    [Subtotal]      DECIMAL (18, 2) NOT NULL,
    [Tax]           DECIMAL (18, 2) NOT NULL,
    [Total]         DECIMAL (18, 2) NOT NULL,
    [PaymentMethod] NVARCHAR (50)  NOT NULL,
    [SaleDate]      DATETIME2 (7)   NOT NULL,
    [Notes]         NVARCHAR (MAX)  NULL,
    CONSTRAINT [PK_Sale] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Sale_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([Id]),
    CONSTRAINT [FK_Sale_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([Id])
);
GO

CREATE NONCLUSTERED INDEX [IX_Sale_CustomerId]
    ON [dbo].[Sale]([CustomerId] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_Sale_EmployeeId]
    ON [dbo].[Sale]([EmployeeId] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_Sale_SaleDate]
    ON [dbo].[Sale]([SaleDate] DESC);
GO

