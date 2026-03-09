using Microsoft.AspNetCore.Mvc;
using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/courier")]
public sealed class CourierController : ControllerBase
{
    private readonly ICustomerOrdersRepository _ordersRepo;
    private readonly IRestaurantOwnerRepository _restaurantRepo;

    public CourierController(
        ICustomerOrdersRepository ordersRepo,
        IRestaurantOwnerRepository restaurantRepo)
    {
        _ordersRepo = ordersRepo;
        _restaurantRepo = restaurantRepo;
    }

    [HttpGet("orders")]
    public async Task<ActionResult<List<object>>> GetOrders(
        [FromQuery] Guid courierUserId,
        CancellationToken cancellationToken)
    {
        var orders = await _ordersRepo.GetOrdersForCourierAsync(cancellationToken);
        var result = orders.Select(o => new
        {
            id = o.OrderId,
            time = o.CreatedAtUtc.ToLocalTime().ToString("HH:mm"),
            date = o.CreatedAtUtc.ToLocalTime().ToString("dd.MM.yyyy"),
            imagePath = "",
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
        }).ToList();
        return Ok(result);
    }

    [HttpPut("orders/{orderId:guid}/status")]
    public async Task<ActionResult<object>> UpdateOrderStatus(
        [FromQuery] Guid courierUserId,
        [FromRoute] Guid orderId,
        [FromBody] UpdateCourierStatusRequest request,
        CancellationToken cancellationToken)
    {
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

        order.Status = newStatus.Value;
        await _ordersRepo.UpdateOrderStatusAsync(order, cancellationToken);

        return Ok(new
        {
            id = order.OrderId,
            status = MapStatus(order.Status),
        });
    }

    private static string MapStatus(CustomerOrderStatus status)
    {
        return status switch
        {
            CustomerOrderStatus.Assigned => "assigned",
            CustomerOrderStatus.InTransit => "inTransit",
            CustomerOrderStatus.Delivered => "delivered",
            _ => "assigned",
        };
    }

    private static CustomerOrderStatus? ParseStatus(string? status)
    {
        var s = status?.Trim().ToLowerInvariant();
        return s switch
        {
            "assigned" => CustomerOrderStatus.Assigned,
            "picked_up" or "pickedup" => CustomerOrderStatus.Assigned,
            "in_transit" or "intransit" => CustomerOrderStatus.InTransit,
            "delivered" => CustomerOrderStatus.Delivered,
            _ => null,
        };
    }
}

public sealed record UpdateCourierStatusRequest(string Status);
