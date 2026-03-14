using Microsoft.AspNetCore.Mvc;
using Vaveyla.Api.Data;
using Vaveyla.Api.Models;
using Vaveyla.Api.Services;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/courier")]
public sealed class CourierController : ControllerBase
{
    private readonly ICustomerOrdersRepository _ordersRepo;
    private readonly IRestaurantOwnerRepository _restaurantRepo;
    private readonly INotificationService _notificationService;

    public CourierController(
        ICustomerOrdersRepository ordersRepo,
        IRestaurantOwnerRepository restaurantRepo,
        INotificationService notificationService)
    {
        _ordersRepo = ordersRepo;
        _restaurantRepo = restaurantRepo;
        _notificationService = notificationService;
    }

    [HttpGet("orders")]
    public async Task<ActionResult<List<object>>> GetOrders(
        [FromQuery] Guid courierUserId,
        CancellationToken cancellationToken)
    {
        if (courierUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Courier user id is required." });
        }

        var orders = await _ordersRepo.GetOrdersForCourierAsync(courierUserId, cancellationToken);
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
            time = o.CreatedAtUtc.ToLocalTime().ToString("HH:mm"),
            date = o.CreatedAtUtc.ToLocalTime().ToString("dd.MM.yyyy"),
            imagePath = NormalizeImagePath(ResolveOrderImagePath(
                o.Items,
                menuMap.TryGetValue(o.RestaurantId, out var menuItems) ? menuItems : new List<MenuItem>())),
            preparationMinutes = (int?)25,
            items = o.Items,
            total = o.Total,
            status = MapStatus(o.Status),
            customerAddress = o.DeliveryAddress,
            customerLat = o.CustomerLat,
            customerLng = o.CustomerLng,
            restaurantAddress = o.RestaurantAddress,
            restaurantLat = o.RestaurantLat,
            restaurantLng = o.RestaurantLng,
            customerName = o.CustomerName,
            customerPhone = o.CustomerPhone,
            courierUserId = o.AssignedCourierUserId,
            courierLat = o.CourierLat,
            courierLng = o.CourierLng,
            courierLocationUpdatedAtUtc = o.CourierLocationUpdatedAtUtc,
        }).ToList();
        return Ok(result);
    }

    [HttpPut("orders/{orderId:guid}/accept")]
    public async Task<ActionResult<object>> AcceptOrder(
        [FromQuery] Guid courierUserId,
        [FromRoute] Guid orderId,
        CancellationToken cancellationToken)
    {
        if (courierUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Courier user id is required." });
        }

        var order = await _ordersRepo.GetOrderAsync(orderId, cancellationToken);
        if (order is null)
        {
            return NotFound(new { message = "Order not found." });
        }

        if (order.Status != CustomerOrderStatus.Preparing &&
            order.Status != CustomerOrderStatus.Assigned)
        {
            return BadRequest(new { message = "Order is not available for courier acceptance." });
        }

        if (order.AssignedCourierUserId.HasValue &&
            order.AssignedCourierUserId.Value != courierUserId)
        {
            return Conflict(new { message = "Order is already accepted by another courier." });
        }

        order.AssignedCourierUserId = courierUserId;
        order.Status = CustomerOrderStatus.Assigned;
        await _ordersRepo.UpdateOrderStatusAsync(order, cancellationToken);
        await _notificationService.NotifyCourierAcceptedAsync(order, cancellationToken);

        return Ok(new
        {
            id = order.OrderId,
            status = MapStatus(order.Status),
            courierUserId = order.AssignedCourierUserId,
        });
    }

    [HttpPut("orders/{orderId:guid}/status")]
    public async Task<ActionResult<object>> UpdateOrderStatus(
        [FromQuery] Guid courierUserId,
        [FromRoute] Guid orderId,
        [FromBody] UpdateCourierStatusRequest request,
        CancellationToken cancellationToken)
    {
        if (courierUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Courier user id is required." });
        }

        var order = await _ordersRepo.GetOrderAsync(orderId, cancellationToken);
        if (order is null)
        {
            return NotFound(new { message = "Order not found." });
        }

        var newStatus = ParseStatus(request.Status);
        if (!newStatus.HasValue)
        {
            return BadRequest(new { message = "Invalid status." });
        }

        if (order.AssignedCourierUserId is null ||
            order.AssignedCourierUserId.Value != courierUserId)
        {
            return Conflict(new { message = "Order is not assigned to this courier." });
        }

        if (!IsAllowedTransition(order.Status, newStatus.Value))
        {
            return BadRequest(new { message = "Invalid status transition." });
        }

        var previousStatus = order.Status;
        order.Status = newStatus.Value;
        await _ordersRepo.UpdateOrderStatusAsync(order, cancellationToken);
        await _notificationService.NotifyCourierStatusChangedAsync(
            order,
            previousStatus,
            cancellationToken);

        return Ok(new
        {
            id = order.OrderId,
            status = MapStatus(order.Status),
        });
    }

    [HttpPut("orders/{orderId:guid}/location")]
    public async Task<ActionResult> UpdateOrderLocation(
        [FromQuery] Guid courierUserId,
        [FromRoute] Guid orderId,
        [FromBody] UpdateCourierLocationRequest request,
        CancellationToken cancellationToken)
    {
        if (courierUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Courier user id is required." });
        }

        var order = await _ordersRepo.GetOrderAsync(orderId, cancellationToken);
        if (order is null)
        {
            return NotFound(new { message = "Order not found." });
        }

        if (order.AssignedCourierUserId is null ||
            order.AssignedCourierUserId.Value != courierUserId)
        {
            return Conflict(new { message = "Order is not assigned to this courier." });
        }

        var timestamp = request.TimestampUtc?.ToUniversalTime() ?? DateTime.UtcNow;
        order.CourierLat = request.Lat;
        order.CourierLng = request.Lng;
        order.CourierLocationUpdatedAtUtc = timestamp;
        await _ordersRepo.UpdateOrderStatusAsync(order, cancellationToken);

        await _ordersRepo.AddCourierLocationAsync(new CourierLocationLog
        {
            CourierLocationLogId = Guid.NewGuid(),
            OrderId = order.OrderId,
            CourierUserId = courierUserId,
            Latitude = request.Lat,
            Longitude = request.Lng,
            TimestampUtc = timestamp,
            CreatedAtUtc = DateTime.UtcNow,
        }, cancellationToken);

        return NoContent();
    }

    private static string MapStatus(CustomerOrderStatus status)
    {
        return status switch
        {
            CustomerOrderStatus.Preparing => "preparing",
            CustomerOrderStatus.Assigned => "assigned",
            CustomerOrderStatus.InTransit => "inTransit",
            CustomerOrderStatus.Delivered => "delivered",
            _ => "preparing",
        };
    }

    private static CustomerOrderStatus? ParseStatus(string? status)
    {
        var s = status?.Trim().ToLowerInvariant();
        return s switch
        {
            "assigned" => CustomerOrderStatus.Assigned,
            "preparing" => CustomerOrderStatus.Preparing,
            "picked_up" or "pickedup" => CustomerOrderStatus.Assigned,
            "in_transit" or "intransit" => CustomerOrderStatus.InTransit,
            "delivered" => CustomerOrderStatus.Delivered,
            _ => null,
        };
    }

    private static bool IsAllowedTransition(CustomerOrderStatus from, CustomerOrderStatus to)
    {
        if (from == to)
        {
            return true;
        }

        return (from, to) switch
        {
            (CustomerOrderStatus.Assigned, CustomerOrderStatus.InTransit) => true,
            (CustomerOrderStatus.InTransit, CustomerOrderStatus.Delivered) => true,
            _ => false,
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

public sealed record UpdateCourierStatusRequest(string Status);
public sealed record UpdateCourierLocationRequest(double Lat, double Lng, DateTime? TimestampUtc);
