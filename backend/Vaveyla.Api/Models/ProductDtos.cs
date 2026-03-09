using System.Text.Json.Serialization;

namespace Vaveyla.Api.Models;

public sealed record CustomerProductDto(
    Guid Id,
    Guid RestaurantId,
    string? RestaurantName,
    string? RestaurantPhotoPath,
    string? RestaurantType,
    string? RestaurantPhone,
    double? RestaurantLat,
    double? RestaurantLng,
    string? CategoryName,
    string Name,
    int Price,
    double Rating,
    int ReviewCount,
    [property: JsonPropertyName("imagePath")] string ImagePath,
    bool IsAvailable,
    bool IsFeatured,
    DateTime CreatedAtUtc);
