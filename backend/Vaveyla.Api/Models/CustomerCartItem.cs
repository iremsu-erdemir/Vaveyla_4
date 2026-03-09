namespace Vaveyla.Api.Models;

public sealed class CustomerCartItem
{
    public Guid CartItemId { get; set; }
    public Guid CustomerUserId { get; set; }
    public Guid ProductId { get; set; }
    public Guid RestaurantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string ImagePath { get; set; } = string.Empty;
    public int UnitPrice { get; set; }
    public decimal WeightKg { get; set; } = 1.0m;
    public int Quantity { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime UpdatedAtUtc { get; set; }
}
