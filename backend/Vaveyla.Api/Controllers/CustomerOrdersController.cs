using Microsoft.AspNetCore.Mvc;
using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/customer")]
public sealed class CustomerOrdersController : ControllerBase
{
    private readonly ICustomerOrdersRepository _repository;
    private readonly IRestaurantOwnerRepository _restaurantRepo;

    public CustomerOrdersController(
        ICustomerOrdersRepository repository,
        IRestaurantOwnerRepository restaurantRepo)
    {
        _repository = repository;
        _restaurantRepo = restaurantRepo;
    }

    [HttpGet("orders")]
    public async Task<ActionResult<List<object>>> GetOrders(
        [FromQuery] Guid customerUserId,
        CancellationToken cancellationToken)
    {
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }

        var orders = await _repository.GetOrdersForCustomerAsync(customerUserId, cancellationToken);
        var restaurantIds = orders
            .Select(x => x.RestaurantId)
            .Distinct()
            .ToList();
        var menuMap = new Dictionary<Guid, List<MenuItem>>();
        foreach (var restaurantId in restaurantIds)
        {
            var menuItems = await _restaurantRepo.GetMenuItemsAsync(restaurantId, cancellationToken);
            menuMap[restaurantId] = menuItems;
        }

        var result = orders.Select(o => new
        {
            id = o.OrderId,
            restaurantId = o.RestaurantId,
            items = o.Items,
            total = o.Total,
            status = MapStatus(o.Status),
            time = o.CreatedAtUtc.ToLocalTime().ToString("HH:mm"),
            date = o.CreatedAtUtc.ToLocalTime().ToString("dd.MM.yyyy"),
            imagePath = NormalizeImagePath(ResolveOrderImagePath(
                o.Items,
                menuMap.TryGetValue(o.RestaurantId, out var menuItems) ? menuItems : new List<MenuItem>())),
            preparationMinutes = (int?)null,
        }).ToList();

        return Ok(result);
    }

    [HttpPost("orders")]
    public async Task<ActionResult<object>> CreateOrder(
        [FromQuery] Guid customerUserId,
        [FromBody] CreateCustomerOrderRequest request,
        CancellationToken cancellationToken)
    {
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }

        var order = new CustomerOrder
        {
            OrderId = Guid.NewGuid(),
            CustomerUserId = customerUserId,
            RestaurantId = request.RestaurantId,
            Items = request.Items.Trim(),
            Total = request.Total,
            DeliveryAddress = request.DeliveryAddress.Trim(),
            DeliveryAddressDetail = string.IsNullOrWhiteSpace(request.DeliveryAddressDetail)
                ? null
                : request.DeliveryAddressDetail.Trim(),
            CustomerLat = request.CustomerLat,
            CustomerLng = request.CustomerLng,
            CustomerName = request.CustomerName?.Trim(),
            CustomerPhone = request.CustomerPhone?.Trim(),
            Status = CustomerOrderStatus.Pending,
            CreatedAtUtc = DateTime.UtcNow,
        };

        var restaurant = await _restaurantRepo.GetRestaurantByIdAsync(
            request.RestaurantId,
            cancellationToken);
        if (restaurant != null)
        {
            order.RestaurantAddress = restaurant.Address;
        }

        await _repository.CreateOrderAsync(order, cancellationToken);

        return Ok(new
        {
            id = order.OrderId,
            status = "pending",
            total = order.Total,
        });
    }

    private static string MapStatus(CustomerOrderStatus status)
    {
        return status switch
        {
            CustomerOrderStatus.Pending => "pending",
            CustomerOrderStatus.Preparing => "preparing",
            CustomerOrderStatus.Assigned => "assigned",
            CustomerOrderStatus.InTransit => "inTransit",
            CustomerOrderStatus.Delivered => "completed",
            CustomerOrderStatus.Cancelled => "canceled",
            _ => "pending",
        };
    }

    private static string ResolveOrderImagePath(
        string itemsText,
        IReadOnlyList<MenuItem> menuItems)
    {
        if (string.IsNullOrWhiteSpace(itemsText) || menuItems.Count == 0)
        {
            return string.Empty;
        }

        var lowerItems = itemsText.ToLowerInvariant();
        foreach (var menuItem in menuItems)
        {
            var name = menuItem.Name?.Trim();
            if (string.IsNullOrWhiteSpace(name))
            {
                continue;
            }

            if (lowerItems.Contains(name.ToLowerInvariant()) &&
                !string.IsNullOrWhiteSpace(menuItem.ImagePath))
            {
                return menuItem.ImagePath.Trim();
            }
        }

        return menuItems
                   .FirstOrDefault(x => !string.IsNullOrWhiteSpace(x.ImagePath))
                   ?.ImagePath
                   ?.Trim()
               ?? string.Empty;
    }

    private string NormalizeImagePath(string imagePath)
    {
        if (string.IsNullOrWhiteSpace(imagePath))
        {
            return string.Empty;
        }

        if (imagePath.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            imagePath.StartsWith("https://", StringComparison.OrdinalIgnoreCase) ||
            imagePath.StartsWith("assets/", StringComparison.OrdinalIgnoreCase))
        {
            return imagePath.Trim();
        }

        var normalized = imagePath.Trim().TrimStart('/');
        return $"{Request.Scheme}://{Request.Host}/{normalized}";
    }
}

public sealed record CreateCustomerOrderRequest(
    Guid RestaurantId,
    string Items,
    int Total,
    string DeliveryAddress,
    string? DeliveryAddressDetail,
    double? CustomerLat,
    double? CustomerLng,
    string? CustomerName,
    string? CustomerPhone);
