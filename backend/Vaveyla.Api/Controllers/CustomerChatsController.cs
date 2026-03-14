using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/customer/chats")]
public sealed class CustomerChatsController : ControllerBase
{
    private readonly ICustomerChatsRepository _repository;
    private readonly VaveylaDbContext _dbContext;

    public CustomerChatsController(
        ICustomerChatsRepository repository,
        VaveylaDbContext dbContext)
    {
        _repository = repository;
        _dbContext = dbContext;
    }

    [HttpGet("messages")]
    public async Task<ActionResult<object>> GetMessages(
        [FromQuery] Guid customerUserId,
        [FromQuery] Guid restaurantId,
        CancellationToken cancellationToken,
        [FromQuery] int limit = 100)
    {
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }
        if (restaurantId == Guid.Empty)
        {
            return BadRequest(new { message = "Restaurant id is required." });
        }

        var messages = await _repository.GetMessagesAsync(
            customerUserId,
            restaurantId,
            limit,
            cancellationToken);
        var customerName = await _dbContext.Users
            .Where(x => x.UserId == customerUserId)
            .Select(x => x.FullName)
            .FirstOrDefaultAsync(cancellationToken);
        var restaurantOwnerName = await _dbContext.Restaurants
            .Where(x => x.RestaurantId == restaurantId)
            .Join(
                _dbContext.Users,
                r => r.OwnerUserId,
                u => u.UserId,
                (_, u) => u.FullName)
            .FirstOrDefaultAsync(cancellationToken);

        return Ok(new
        {
            items = messages.Select(x => MapMessage(x, customerName, restaurantOwnerName)),
            totalCount = messages.Count,
        });
    }

    [HttpPost("messages")]
    public async Task<ActionResult<object>> SendCustomerMessage(
        [FromQuery] Guid customerUserId,
        [FromBody] SendCustomerMessageRequest request,
        CancellationToken cancellationToken)
    {
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }
        if (request.RestaurantId == Guid.Empty)
        {
            return BadRequest(new { message = "Restaurant id is required." });
        }
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest(new { message = "Message is required." });
        }

        var customerExists = await _dbContext.Users.AnyAsync(
            x => x.UserId == customerUserId,
            cancellationToken);
        if (!customerExists)
        {
            return NotFound(new { message = "Customer not found." });
        }

        var restaurant = await _dbContext.Restaurants.FirstOrDefaultAsync(
            x => x.RestaurantId == request.RestaurantId,
            cancellationToken);
        if (restaurant is null)
        {
            return NotFound(new { message = "Restaurant not found." });
        }

        var created = await _repository.AddMessageAsync(
            new RestaurantChatMessage
            {
                ChatMessageId = Guid.NewGuid(),
                RestaurantId = request.RestaurantId,
                CustomerUserId = customerUserId,
                SenderUserId = customerUserId,
                SenderType = "customer",
                Message = request.Message.Trim(),
                CreatedAtUtc = DateTime.UtcNow,
            },
            cancellationToken);

        var customerName = await _dbContext.Users
            .Where(x => x.UserId == customerUserId)
            .Select(x => x.FullName)
            .FirstOrDefaultAsync(cancellationToken);
        var restaurantOwnerName = await _dbContext.Users
            .Where(x => x.UserId == restaurant.OwnerUserId)
            .Select(x => x.FullName)
            .FirstOrDefaultAsync(cancellationToken);

        return Ok(MapMessage(created, customerName, restaurantOwnerName));
    }

    [HttpDelete("messages/{messageId:guid}")]
    public async Task<ActionResult> DeleteCustomerMessage(
        [FromRoute] Guid messageId,
        [FromQuery] Guid customerUserId,
        CancellationToken cancellationToken)
    {
        if (messageId == Guid.Empty)
        {
            return BadRequest(new { message = "Message id is required." });
        }
        if (customerUserId == Guid.Empty)
        {
            return BadRequest(new { message = "Customer user id is required." });
        }

        var deleted = await _repository.DeleteCustomerMessageAsync(
            messageId,
            customerUserId,
            cancellationToken);
        if (!deleted)
        {
            return NotFound(new { message = "Message not found or cannot be deleted." });
        }

        return NoContent();
    }

    private static object MapMessage(
        RestaurantChatMessage message,
        string? customerName,
        string? restaurantOwnerName)
    {
        var isCustomer = string.Equals(
            message.SenderType,
            "customer",
            StringComparison.OrdinalIgnoreCase);
        return new
        {
            id = message.ChatMessageId,
            restaurantId = message.RestaurantId,
            customerUserId = message.CustomerUserId,
            senderUserId = message.SenderUserId,
            senderType = message.SenderType,
            senderName = isCustomer
                ? string.IsNullOrWhiteSpace(customerName) ? "Müşteri" : customerName
                : string.IsNullOrWhiteSpace(restaurantOwnerName) ? "Restoran" : restaurantOwnerName,
            message = message.Message,
            createdAtUtc = message.CreatedAtUtc,
        };
    }
}

public sealed record SendCustomerMessageRequest(Guid RestaurantId, string Message);
