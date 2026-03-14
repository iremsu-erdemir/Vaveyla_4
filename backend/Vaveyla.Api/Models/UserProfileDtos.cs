namespace Vaveyla.Api.Models;

public sealed record UserProfileDto(
    Guid UserId,
    string FullName,
    string Email,
    string? Phone,
    string? Address,
    string? PhotoUrl);

public sealed record UpdateUserProfileRequest(
    string FullName,
    string Email,
    string? Phone,
    string? Address);
