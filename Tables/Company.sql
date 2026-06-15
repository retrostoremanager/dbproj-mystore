CREATE TABLE [dbo].[Company] (
    [Id]                        INT            IDENTITY (1, 1) NOT NULL,
    [Email]                     NVARCHAR (255) NOT NULL,
    [Status]                    NVARCHAR (50)  NOT NULL,
    [TrialStartDate]            DATETIME2 (7)  NOT NULL,
    [TrialEndDate]              DATETIME2 (7)  NOT NULL,
    [VerificationToken]         NVARCHAR (255) NULL,
    [VerificationTokenExpires]  DATETIME2 (7)  NULL,
    [SubscriptionTier]          NVARCHAR (50)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  NOT NULL,
    [LastModifiedDate]          DATETIME2 (7)  NULL,
    CONSTRAINT [PK_Company] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_Company_Email]
    ON [dbo].[Company]([Email] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_Company_Status]
    ON [dbo].[Company]([Status] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_Company_VerificationToken]
    ON [dbo].[Company]([VerificationToken] ASC)
    WHERE [VerificationToken] IS NOT NULL;
GO
