CREATE TABLE [dbo].[GameEncyclopedia] (
    [Id]          NVARCHAR (100) NOT NULL,
    [Title]       NVARCHAR (255) NOT NULL,
    [Console]     NVARCHAR (100) NOT NULL,
    [ReleaseDate] DATE           NULL,
    [Publisher]   NVARCHAR (255) NULL,
    [Genre]       NVARCHAR (100) NULL,
    [ImageUrl]    NVARCHAR (500) NULL,
    CONSTRAINT [PK_GameEncyclopedia] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_GameEncyclopedia_Title]
    ON [dbo].[GameEncyclopedia]([Title] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_GameEncyclopedia_Console]
    ON [dbo].[GameEncyclopedia]([Console] ASC);
GO

