using Microsoft.EntityFrameworkCore;
using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Services;

public sealed class CartCalculationService : ICartCalculationService
{
    private const decimal DefaultCommissionRate = 0.10m;
    private readonly VaveylaDbContext _db;

    public CartCalculationService(VaveylaDbContext db)
    {
        _db = db;
    }

    public async Task<CalculateCartResponse> CalculateCartAsync(CalculateCartRequest request, CancellationToken ct = default)
    {
        if (request.Items == null || request.Items.Count == 0)
        {
            return new CalculateCartResponse(
                [],
                0,
                0,
                0,
                0,
                0,
                0);
        }

        var productIds = request.Items.Select(x => x.ProductId).Distinct().ToList();
        var menuItems = await _db.MenuItems
            .Where(m => m.RestaurantId == request.RestaurantId && productIds.Contains(m.MenuItemId))
            .ToDictionaryAsync(m => m.MenuItemId, ct);

        var restaurant = await _db.Restaurants
            .FirstOrDefaultAsync(r => r.RestaurantId == request.RestaurantId, ct);
        var commissionRate = restaurant?.CommissionRate ?? DefaultCommissionRate;

        var now = DateTime.UtcNow;
        var campaigns = await _db.Campaigns
            .Where(c =>
                c.IsActive &&
                c.Status == "Active" &&
                c.StartDate <= now &&
                c.EndDate >= now &&
                (c.RestaurantId == null || c.RestaurantId == request.RestaurantId))
            .ToListAsync(ct);

        var itemResults = new List<CalculateCartItemResponse>();
        decimal totalOriginal = 0;
        decimal totalItemDiscounts = 0;
        var discountOwner = CampaignDiscountOwner.Platform;

        foreach (var reqItem in request.Items)
        {
            if (reqItem.Quantity <= 0) continue;

            menuItems.TryGetValue(reqItem.ProductId, out var menuItem);
            var productName = menuItem?.Name ?? "Ürün";
            var categoryName = menuItem?.CategoryName;
            var originalUnitPrice = (decimal)reqItem.UnitPrice;
            var lineOriginal = originalUnitPrice * reqItem.Quantity;
            totalOriginal += lineOriginal;

            var candidateDiscounts = new List<(decimal amount, CampaignDiscountOwner owner)>();

            foreach (var campaign in campaigns)
            {
                decimal? discountAmount = null;

                switch ((CampaignTargetType)campaign.TargetType)
                {
                    case CampaignTargetType.Product:
                        if (campaign.TargetId == reqItem.ProductId)
                            discountAmount = ComputeDiscount(campaign, originalUnitPrice) * reqItem.Quantity;
                        break;
                    case CampaignTargetType.Category:
                        if (!string.IsNullOrEmpty(campaign.TargetCategoryName) &&
                            string.Equals(campaign.TargetCategoryName, categoryName, StringComparison.OrdinalIgnoreCase))
                            discountAmount = ComputeDiscount(campaign, originalUnitPrice) * reqItem.Quantity;
                        break;
                    case CampaignTargetType.Cart:
                        break;
                }

                if (discountAmount.HasValue && discountAmount.Value > 0)
                    candidateDiscounts.Add((Math.Min(discountAmount.Value, lineOriginal), (CampaignDiscountOwner)campaign.DiscountOwner));
            }

            var best = candidateDiscounts.OrderByDescending(x => x.amount).FirstOrDefault();
            var itemDiscount = best.amount;
            if (itemDiscount > 0)
                discountOwner = best.owner;

            totalItemDiscounts += itemDiscount;
            var discountedLine = lineOriginal - itemDiscount;

            itemResults.Add(new CalculateCartItemResponse(
                reqItem.ProductId,
                productName,
                reqItem.Quantity,
                lineOriginal,
                discountedLine,
                itemDiscount));
        }

        var subtotalAfterItems = totalOriginal - totalItemDiscounts;
        var cartCampaigns = campaigns.Where(c => c.TargetType == CampaignTargetType.Cart).ToList();
        decimal cartDiscount = 0;
        CampaignDiscountOwner? cartDiscountOwner = null;

        foreach (var campaign in cartCampaigns)
        {
            if (campaign.MinCartAmount.HasValue && totalOriginal < campaign.MinCartAmount.Value)
                continue;

            var discountAmount = campaign.DiscountType == CampaignDiscountType.Percentage
                ? totalOriginal * (campaign.DiscountValue / 100m)
                : campaign.DiscountValue;

            if (discountAmount > subtotalAfterItems - cartDiscount)
                discountAmount = Math.Max(0, subtotalAfterItems - cartDiscount);

            if (discountAmount > cartDiscount)
            {
                cartDiscount = discountAmount;
                cartDiscountOwner = (CampaignDiscountOwner)campaign.DiscountOwner;
            }
        }

        var totalDiscount = totalItemDiscounts + cartDiscount;
        if (cartDiscountOwner.HasValue && cartDiscount > 0)
            discountOwner = cartDiscountOwner.Value;

        var finalPrice = Math.Max(0, totalOriginal - totalDiscount);
        decimal restaurantEarning;
        decimal platformEarning;

        if (discountOwner == CampaignDiscountOwner.Restaurant)
        {
            restaurantEarning = finalPrice * (1 - commissionRate);
            platformEarning = finalPrice * commissionRate;
        }
        else
        {
            restaurantEarning = totalOriginal * (1 - commissionRate);
            platformEarning = totalOriginal * commissionRate - totalDiscount;
            if (platformEarning < 0) platformEarning = 0;
        }

        return new CalculateCartResponse(
            itemResults,
            totalOriginal,
            totalDiscount,
            finalPrice,
            finalPrice,
            restaurantEarning,
            platformEarning);
    }

    private static decimal ComputeDiscount(Campaign campaign, decimal unitPrice)
    {
        return campaign.DiscountType == CampaignDiscountType.Percentage
            ? unitPrice * (campaign.DiscountValue / 100m)
            : Math.Min(campaign.DiscountValue, unitPrice);
    }
}
