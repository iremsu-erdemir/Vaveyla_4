namespace Vaveyla.Api.Models;

public sealed record UserProfileDto(
    Guid UserId,
    string FullName,
    string Email,
    string? PhotoUrl);
