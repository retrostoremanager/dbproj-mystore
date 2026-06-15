CREATE PROCEDURE [dbo].[spCompany_Update]
    @Id INT,
    @Email NVARCHAR(255),
    @Status NVARCHAR(50),
    @TrialStartDate DATETIME2(7),
    @TrialEndDate DATETIME2(7),
    @VerificationToken NVARCHAR(255) = NULL,
    @VerificationTokenExpires DATETIME2(7) = NULL,
    @SubscriptionTier NVARCHAR(50),
    @LastModifiedDate DATETIME2(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [dbo].[Company]
    SET [Email] = @Email,
        [Status] = @Status,
        [TrialStartDate] = @TrialStartDate,
        [TrialEndDate] = @TrialEndDate,
        [VerificationToken] = @VerificationToken,
        [VerificationTokenExpires] = @VerificationTokenExpires,
        [SubscriptionTier] = @SubscriptionTier,
        [LastModifiedDate] = @LastModifiedDate
    WHERE [Id] = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO
