using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/restaurant/campaigns")]
[Authorize(Roles = "RestaurantOwner")]
public sealed class RestaurantCampaignsController : ControllerBase
{
    private readonly ICampaignRepository _campaignRepo;
    private readonly IRestaurantOwnerRepository _restaurantRepo;
    private readonly IUserRepository _userRepo;

    public RestaurantCampaignsController(
        ICampaignRepository campaignRepo,
        IRestaurantOwnerRepository restaurantRepo,
        IUserRepository userRepo)
    {
        _campaignRepo = campaignRepo;
        _restaurantRepo = restaurantRepo;
        _userRepo = userRepo;
    }

    [HttpGet]
    public async Task<ActionResult<List<CampaignDto>>> GetAll(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue) return Unauthorized(new { message = "Yetkisiz erişim." });
        var restaurant = await GetRestaurantForOwnerAsync(userId.Value, ct);
        if (restaurant == null)
            return Unauthorized(new { message = "Restoran bulunamadı." });

        var campaigns = await _campaignRepo.GetByRestaurantAsync(restaurant.RestaurantId, ct);
        return Ok(campaigns.Select(c => ToDto(c, restaurant.Name)).ToList());
    }

    [HttpPost]
    public async Task<ActionResult<CampaignDto>> Create(
        [FromBody] CreateCampaignRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue) return Unauthorized(new { message = "Yetkisiz erişim." });
        var restaurant = await GetRestaurantForOwnerAsync(userId.Value, ct);
        if (restaurant == null)
            return Unauthorized(new { message = "Restoran bulunamadı." });

        var campaign = new Campaign
        {
            CampaignId = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            DiscountType = (CampaignDiscountType)request.DiscountType,
            DiscountValue = request.DiscountValue,
            TargetType = (CampaignTargetType)request.TargetType,
            TargetId = request.TargetId,
            TargetCategoryName = request.TargetCategoryName?.Trim(),
            MinCartAmount = request.MinCartAmount,
            IsActive = true,
            Status = "Pending",
            DiscountOwner = CampaignDiscountOwner.Restaurant,
            RestaurantId = restaurant.RestaurantId,
            StartDate = request.StartDate.ToUniversalTime(),
            EndDate = request.EndDate.ToUniversalTime(),
            CreatedAtUtc = DateTime.UtcNow,
        };
        await _campaignRepo.CreateAsync(campaign, ct);
        return Ok(ToDto(campaign, restaurant.Name));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<CampaignDto>> Update(
        [FromRoute] Guid id,
        [FromBody] CreateCampaignRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue) return Unauthorized(new { message = "Yetkisiz erişim." });
        var restaurant = await GetRestaurantForOwnerAsync(userId.Value, ct);
        if (restaurant == null)
            return Unauthorized(new { message = "Restoran bulunamadı." });

        var campaign = await _campaignRepo.GetByIdAsync(id, ct);
        if (campaign == null || campaign.RestaurantId != restaurant.RestaurantId)
            return NotFound(new { message = "Kampanya bulunamadı." });

        campaign.Name = request.Name.Trim();
        campaign.Description = request.Description?.Trim();
        campaign.DiscountType = (CampaignDiscountType)request.DiscountType;
        campaign.DiscountValue = request.DiscountValue;
        campaign.TargetType = (CampaignTargetType)request.TargetType;
        campaign.TargetId = request.TargetId;
        campaign.TargetCategoryName = request.TargetCategoryName?.Trim();
        campaign.MinCartAmount = request.MinCartAmount;
        campaign.StartDate = request.StartDate.ToUniversalTime();
        campaign.EndDate = request.EndDate.ToUniversalTime();
        await _campaignRepo.UpdateAsync(campaign, ct);
        return Ok(ToDto(campaign, restaurant.Name));
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult> Delete([FromRoute] Guid id, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue) return Unauthorized(new { message = "Yetkisiz erişim." });
        var restaurant = await GetRestaurantForOwnerAsync(userId.Value, ct);
        if (restaurant == null)
            return Unauthorized(new { message = "Restoran bulunamadı." });

        var campaign = await _campaignRepo.GetByIdAsync(id, ct);
        if (campaign == null || campaign.RestaurantId != restaurant.RestaurantId)
            return NotFound(new { message = "Kampanya bulunamadı." });

        await _campaignRepo.DeleteAsync(campaign, ct);
        return NoContent();
    }

    private Guid? GetCurrentUserId()
    {
        var sub = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(sub, out var id) ? id : null;
    }

    private async Task<Restaurant?> GetRestaurantForOwnerAsync(Guid ownerUserId, CancellationToken ct)
    {
        if (ownerUserId == Guid.Empty) return null;
        var user = await _userRepo.GetByIdAsync(ownerUserId, ct);
        if (user == null || user.Role != UserRole.RestaurantOwner) return null;
        return await _restaurantRepo.GetRestaurantAsync(ownerUserId, ct);
    }

    private static CampaignDto ToDto(Campaign c, string restaurantName) =>
        new(c.CampaignId, c.Name, c.Description, (int)c.DiscountType, c.DiscountValue,
            (int)c.TargetType, c.TargetId, c.TargetCategoryName, c.MinCartAmount, c.IsActive, c.Status,
            (int)c.DiscountOwner, c.RestaurantId, restaurantName, c.StartDate, c.EndDate, c.CreatedAtUtc);
}
