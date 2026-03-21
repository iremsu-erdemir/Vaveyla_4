using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Vaveyla.Api.Data;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/admin/restaurants")]
[Authorize(Roles = "Admin")]
public sealed class AdminRestaurantsController : ControllerBase
{
    private readonly VaveylaDbContext _db;

    public AdminRestaurantsController(VaveylaDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<List<object>>> GetAll(CancellationToken ct)
    {
        var restaurants = await _db.Restaurants
            .OrderBy(r => r.Name)
            .Select(r => new
            {
                r.RestaurantId,
                r.Name,
                r.Type,
                r.Address,
                r.Phone,
                r.IsOpen,
                r.IsEnabled,
                r.CommissionRate,
            })
            .ToListAsync(ct);

        return Ok(restaurants);
    }

    [HttpPut("{id:guid}/toggle-status")]
    public async Task<ActionResult> ToggleStatus([FromRoute] Guid id, CancellationToken ct)
    {
        var restaurant = await _db.Restaurants.FirstOrDefaultAsync(r => r.RestaurantId == id, ct);
        if (restaurant == null)
            return NotFound(new { message = "Restoran bulunamadı." });

        restaurant.IsEnabled = !restaurant.IsEnabled;
        await _db.SaveChangesAsync(ct);
        return Ok(new { message = $"Restoran {(restaurant.IsEnabled ? "aktif" : "pasif")}." });
    }

    [HttpPut("{id:guid}/set-commission")]
    public async Task<ActionResult> SetCommission(
        [FromRoute] Guid id,
        [FromBody] SetCommissionRequest request,
        CancellationToken ct)
    {
        var restaurant = await _db.Restaurants.FirstOrDefaultAsync(r => r.RestaurantId == id, ct);
        if (restaurant == null)
            return NotFound(new { message = "Restoran bulunamadı." });

        if (!request.CommissionRate.HasValue || request.CommissionRate is < 0 or > 1)
            return BadRequest(new { message = "Komisyon oranı 0-1 arasında olmalıdır." });

        restaurant.CommissionRate = request.CommissionRate.Value;
        await _db.SaveChangesAsync(ct);
        return Ok(new { message = "Komisyon oranı güncellendi.", commissionRate = restaurant.CommissionRate });
    }
}

public sealed record SetCommissionRequest(decimal? CommissionRate);
