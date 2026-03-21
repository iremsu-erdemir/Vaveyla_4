using System.Text.Json.Serialization;

namespace Vaveyla.Api.Models;

public sealed record CustomerProductDto(
    Guid Id,
    Guid RestaurantId,
    string? RestaurantName,
    string? RestaurantPhotoPath,
    string? RestaurantType,
    string? RestaurantAddress,
    string? RestaurantPhone,
    double? RestaurantLat,
    double? RestaurantLng,
    int? EstimatedDeliveryMinutes,
    bool RestaurantIsOpen,
    string? CategoryName,
    string Name,
    int Price,
    double Rating,
    int ReviewCount,
    [property: JsonPropertyName("imagePath")] string ImagePath,
    bool IsAvailable,
    bool IsFeatured,
    DateTime CreatedAtUtc);
