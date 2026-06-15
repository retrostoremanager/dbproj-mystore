CREATE PROCEDURE [dbo].[spCompany_GetByVerificationToken]
    @Token NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Email], [Status], [TrialStartDate], [TrialEndDate], 
           [VerificationToken], [VerificationTokenExpires], [SubscriptionTier],
           [CreatedDate], [LastModifiedDate]
    FROM [dbo].[Company]
    WHERE [VerificationToken] = @Token;
END;
GO
