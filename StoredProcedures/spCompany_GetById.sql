CREATE PROCEDURE [dbo].[spCompany_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Email], [Status], [TrialStartDate], [TrialEndDate], 
           [VerificationToken], [VerificationTokenExpires], [SubscriptionTier],
           [CreatedDate], [LastModifiedDate]
    FROM [dbo].[Company]
    WHERE [Id] = @Id;
END;
GO
