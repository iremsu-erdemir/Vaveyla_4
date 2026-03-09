using System.Text.Json.Serialization;

namespace Vaveyla.Api.Models;

public sealed record MenuItemDto(
    Guid Id,
    string? CategoryName,
    string Name,
    int Price,
    [property: JsonPropertyName("imagePath")] string ImagePath,
    bool IsAvailable,
    bool IsFeatured);

public sealed record CreateMenuItemRequest(
    string Name,
    int Price,
    [property: JsonPropertyName("imagePath")] string? ImagePath,
    bool? IsAvailable,
    bool? IsFeatured,
    [property: JsonPropertyName("categoryName")] string? CategoryName);

public sealed record UpdateMenuItemRequest(
    string? Name,
    int? Price,
    [property: JsonPropertyName("imagePath")] string? ImagePath,
    bool? IsAvailable,
    bool? IsFeatured,
    [property: JsonPropertyName("categoryName")] string? CategoryName);

public sealed record RestaurantOrderDto(
    Guid Id,
    string Time,
    string Date,
    [property: JsonPropertyName("imagePath")] string ImagePath,
    string Items,
    int Total,
    string Status,
    [property: JsonPropertyName("preparationMinutes")] int? PreparationMinutes);

public sealed record CreateOrderRequest(
    string Items,
    int Total,
    [property: JsonPropertyName("imagePath")] string? ImagePath,
    [property: JsonPropertyName("preparationMinutes")] int? PreparationMinutes,
    string? Status,
    DateTime? CreatedAtUtc);

public sealed record UpdateOrderStatusRequest(string Status);

public sealed record RestaurantReviewDto(
    Guid Id,
    string CustomerName,
    double Rating,
    string Comment,
    string Date,
    string? OwnerReply);

public sealed record UpdateReviewReplyRequest(string OwnerReply);

public sealed record RestaurantSettingsDto
{
    public Guid RestaurantId { get; init; }
    public string RestaurantName { get; init; } = string.Empty;
    public string RestaurantType { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public double? Latitude { get; init; }
    public double? Longitude { get; init; }
    public string Phone { get; init; } = string.Empty;
    public string WorkingHours { get; init; } = string.Empty;
    public bool OrderNotifications { get; init; }
    public bool IsOpen { get; init; }
    public double Rating { get; init; }
    public int ReviewCount { get; init; }
    public string? RestaurantPhotoPath { get; init; }
    public Dictionary<int, int> RatingDistribution { get; init; } = new();
    public List<RestaurantReviewDto> Reviews { get; init; } = new();
}

public sealed record UpdateRestaurantSettingsRequest
{
    public string? RestaurantName { get; init; }
    public string? RestaurantType { get; init; }
    public string? Address { get; init; }
    public double? Latitude { get; init; }
    public double? Longitude { get; init; }
    public string? Phone { get; init; }
    public string? WorkingHours { get; init; }
    public bool? OrderNotifications { get; init; }
    public bool? IsOpen { get; init; }
    public string? RestaurantPhotoPath { get; init; }
}
