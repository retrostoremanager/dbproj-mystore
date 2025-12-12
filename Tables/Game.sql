CREATE TABLE [dbo].[Game] (
    [Id]          NVARCHAR (100) NOT NULL,
    [Title]       NVARCHAR (255) NOT NULL,
    [Console]     NVARCHAR (100) NOT NULL,
    [ReleaseDate] DATE           NULL,
    [Publisher]   NVARCHAR (255) NULL,
    [Genre]       NVARCHAR (100) NULL,
    [ImageUrl]    NVARCHAR (500) NULL,
    CONSTRAINT [PK_Game] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_Game_Title]
    ON [dbo].[Game]([Title] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_Game_Console]
    ON [dbo].[Game]([Console] ASC);
GO

