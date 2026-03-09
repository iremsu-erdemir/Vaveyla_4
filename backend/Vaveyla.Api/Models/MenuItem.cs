namespace Vaveyla.Api.Models;

public sealed class MenuItem
{
    public Guid MenuItemId { get; set; }
    public Guid RestaurantId { get; set; }
    public string? CategoryName { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Price { get; set; }
    public string ImagePath { get; set; } = string.Empty;
    public bool IsAvailable { get; set; } = true;
    public bool IsFeatured { get; set; } = false;
    public DateTime CreatedAtUtc { get; set; }
}
