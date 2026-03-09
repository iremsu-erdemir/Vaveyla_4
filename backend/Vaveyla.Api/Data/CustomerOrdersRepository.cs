using Microsoft.EntityFrameworkCore;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Data;

public interface ICustomerOrdersRepository
{
    Task<CustomerOrder> CreateOrderAsync(CustomerOrder order, CancellationToken cancellationToken);
    Task<List<CustomerOrder>> GetOrdersForCustomerAsync(Guid customerUserId, CancellationToken cancellationToken);
    Task<List<CustomerOrder>> GetOrdersForRestaurantAsync(Guid restaurantId, CancellationToken cancellationToken);
    Task<List<CustomerOrder>> GetOrdersForCourierAsync(CancellationToken cancellationToken);
    Task<CustomerOrder?> GetOrderAsync(Guid orderId, CancellationToken cancellationToken);
    Task UpdateOrderStatusAsync(CustomerOrder order, CancellationToken cancellationToken);
}

public sealed class CustomerOrdersRepository : ICustomerOrdersRepository
{
    private readonly VaveylaDbContext _dbContext;

    public CustomerOrdersRepository(VaveylaDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<CustomerOrder> CreateOrderAsync(
        CustomerOrder order,
        CancellationToken cancellationToken)
    {
        _dbContext.CustomerOrders.Add(order);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return order;
    }

    public async Task<List<CustomerOrder>> GetOrdersForCustomerAsync(
        Guid customerUserId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.CustomerOrders
            .Where(o => o.CustomerUserId == customerUserId)
            .OrderByDescending(o => o.CreatedAtUtc)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<CustomerOrder>> GetOrdersForRestaurantAsync(
        Guid restaurantId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.CustomerOrders
            .Where(o => o.RestaurantId == restaurantId)
            .OrderByDescending(o => o.CreatedAtUtc)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<CustomerOrder>> GetOrdersForCourierAsync(
        CancellationToken cancellationToken)
    {
        return await _dbContext.CustomerOrders
            .Where(o => o.Status != CustomerOrderStatus.Delivered &&
                        o.Status != CustomerOrderStatus.Cancelled)
            .OrderByDescending(o => o.CreatedAtUtc)
            .ToListAsync(cancellationToken);
    }

    public async Task<CustomerOrder?> GetOrderAsync(
        Guid orderId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.CustomerOrders
            .FirstOrDefaultAsync(o => o.OrderId == orderId, cancellationToken);
    }

    public async Task UpdateOrderStatusAsync(
        CustomerOrder order,
        CancellationToken cancellationToken)
    {
        _dbContext.CustomerOrders.Update(order);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
