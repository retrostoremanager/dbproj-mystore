CREATE PROCEDURE [dbo].[spCompany_Create]
    @Email NVARCHAR(255),
    @Status NVARCHAR(50),
    @TrialStartDate DATETIME2(7),
    @TrialEndDate DATETIME2(7),
    @VerificationToken NVARCHAR(255) = NULL,
    @VerificationTokenExpires DATETIME2(7) = NULL,
    @SubscriptionTier NVARCHAR(50),
    @CreatedDate DATETIME2(7),
    @LastModifiedDate DATETIME2(7) = NULL,
    @Id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[Company] 
        ([Email], [Status], [TrialStartDate], [TrialEndDate], 
         [VerificationToken], [VerificationTokenExpires], [SubscriptionTier],
         [CreatedDate], [LastModifiedDate])
    VALUES 
        (@Email, @Status, @TrialStartDate, @TrialEndDate,
         @VerificationToken, @VerificationTokenExpires, @SubscriptionTier,
         @CreatedDate, @LastModifiedDate);

    SET @Id = SCOPE_IDENTITY();
END;
GO
