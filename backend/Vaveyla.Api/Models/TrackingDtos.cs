namespace Vaveyla.Api.Models;

public sealed record LocationUpdateDto(
    Guid OrderId,
    Guid CourierUserId,
    double Lat,
    double Lng,
    double? Bearing,
    DateTime? TimestampUtc);

public sealed record CourierDetailsDto(
    Guid CourierUserId,
    string FirstName,
    string LastName,
    string FullName,
    string? Phone,
    string? PhotoUrl);

public sealed record TrackingSnapshotDto(
    Guid OrderId,
    string Items,
    string DeliveryAddress,
    double? CustomerLat,
    double? CustomerLng,
    double? CourierLat,
    double? CourierLng,
    double? Bearing,
    DateTime? CourierLocationUpdatedAtUtc,
    bool IsTrackingActive,
    CourierDetailsDto? Courier);
