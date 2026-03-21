namespace Vaveyla.Api.Models;

public sealed class Restaurant
{
    public Guid RestaurantId { get; set; }
    public Guid OwnerUserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string WorkingHours { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool OrderNotifications { get; set; } = true;
    public bool IsOpen { get; set; } = true;
    public string? PhotoPath { get; set; }
    public decimal CommissionRate { get; set; } = 0.10m;
    public bool IsEnabled { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; }
}
