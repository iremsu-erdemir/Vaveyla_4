using System.Text.Json.Serialization;

namespace Vaveyla.Api.Models;

public sealed record CalculateCartItemRequest(
    Guid ProductId,
    int Quantity,
    [property: JsonPropertyName("unitPrice")] decimal UnitPrice);

public sealed record CalculateCartRequest(
    Guid RestaurantId,
    [property: JsonPropertyName("items")] List<CalculateCartItemRequest> Items);

public sealed record CalculateCartItemResponse(
    Guid ProductId,
    string ProductName,
    int Quantity,
    [property: JsonPropertyName("originalPrice")] decimal OriginalPrice,
    [property: JsonPropertyName("discountedPrice")] decimal DiscountedPrice,
    [property: JsonPropertyName("itemDiscount")] decimal ItemDiscount);

public sealed record CalculateCartResponse(
    [property: JsonPropertyName("items")] List<CalculateCartItemResponse> Items,
    [property: JsonPropertyName("totalPrice")] decimal TotalPrice,
    [property: JsonPropertyName("totalDiscount")] decimal TotalDiscount,
    [property: JsonPropertyName("finalPrice")] decimal FinalPrice,
    [property: JsonPropertyName("customerPaidAmount")] decimal CustomerPaidAmount,
    [property: JsonPropertyName("restaurantEarning")] decimal RestaurantEarning,
    [property: JsonPropertyName("platformEarning")] decimal PlatformEarning);

public sealed record CampaignDto(
    Guid CampaignId,
    string Name,
    string? Description,
    int DiscountType,
    decimal DiscountValue,
    int TargetType,
    Guid? TargetId,
    string? TargetCategoryName,
    decimal? MinCartAmount,
    bool IsActive,
    string Status,
    int DiscountOwner,
    Guid? RestaurantId,
    string? RestaurantName,
    DateTime StartDate,
    DateTime EndDate,
    DateTime CreatedAtUtc);

public sealed record CreateCampaignRequest(
    string Name,
    string? Description,
    int DiscountType,
    decimal DiscountValue,
    int TargetType,
    Guid? TargetId,
    string? TargetCategoryName,
    decimal? MinCartAmount,
    int DiscountOwner,
    DateTime StartDate,
    DateTime EndDate);
