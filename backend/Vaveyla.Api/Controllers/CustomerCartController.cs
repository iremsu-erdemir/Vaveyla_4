using Microsoft.AspNetCore.Mvc;
using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/customer/cart")]
public sealed class CustomerCartController : ControllerBase
{
    private readonly ICustomerCartRepository _repository;

    public CustomerCartController(ICustomerCartRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<List<CustomerCartItemDto>>> GetCart(
        [FromQuery] Guid customerUserId,
        CancellationToken cancellationToken)
    {
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }

        var items = await _repository.GetCartAsync(customerUserId, cancellationToken);
        return Ok(items.Select(MapItem).ToList());
    }

    [HttpPost("items")]
    public async Task<ActionResult<CustomerCartItemDto>> AddItem(
        [FromQuery] Guid customerUserId,
        [FromBody] AddCartItemRequest request,
        CancellationToken cancellationToken)
    {
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }

        if (request.ProductId == Guid.Empty)
        {
            return BadRequest(new { message = "Product id is required." });
        }

        if (request.Quantity <= 0)
        {
            return BadRequest(new { message = "Quantity must be greater than zero." });
        }

        var weightKg = request.WeightKg <= 0 ? 1.0m : request.WeightKg;
        try
        {
            var item = await _repository.AddOrUpdateAsync(
                customerUserId,
                request.ProductId,
                weightKg,
                request.Quantity,
                cancellationToken);
            return Ok(MapItem(item));
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPut("items/{cartItemId:guid}")]
    public async Task<ActionResult<CustomerCartItemDto>> UpdateItemQuantity(
        [FromQuery] Guid customerUserId,
        [FromRoute] Guid cartItemId,
        [FromBody] UpdateCartItemRequest request,
        CancellationToken cancellationToken)
    {
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }

        if (request.Quantity <= 0)
        {
            return BadRequest(new { message = "Quantity must be greater than zero." });
        }

        var item = await _repository.UpdateQuantityAsync(
            customerUserId,
            cartItemId,
            request.Quantity,
            cancellationToken);
        if (item is null)
        {
            return NotFound(new { message = "Cart item not found." });
        }

        return Ok(MapItem(item));
    }

    [HttpDelete("items/{cartItemId:guid}")]
    public async Task<ActionResult> RemoveItem(
        [FromQuery] Guid customerUserId,
        [FromRoute] Guid cartItemId,
        CancellationToken cancellationToken)
    {
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }

        var removed = await _repository.RemoveItemAsync(customerUserId, cartItemId, cancellationToken);
        if (!removed)
        {
            return NotFound(new { message = "Cart item not found." });
        }

        return NoContent();
    }

    [HttpDelete("clear")]
    public async Task<ActionResult> Clear(
        [FromQuery] Guid customerUserId,
        CancellationToken cancellationToken)
    {
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }

        await _repository.ClearCartAsync(customerUserId, cancellationToken);
        return NoContent();
    }

    private static CustomerCartItemDto MapItem(CustomerCartItem item)
    {
        return new CustomerCartItemDto(
            item.CartItemId,
            item.ProductId,
            item.RestaurantId,
            item.ProductName,
            item.ImagePath,
            item.UnitPrice,
            item.WeightKg,
            item.Quantity);
    }
}
