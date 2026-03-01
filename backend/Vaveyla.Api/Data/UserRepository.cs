using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Data;

public sealed class UserRepository : IUserRepository
{
    private readonly VaveylaDbContext _dbContext;
    private readonly string _connectionString;

    public UserRepository(IConfiguration configuration, VaveylaDbContext dbContext)
    {
        _connectionString = configuration.GetConnectionString("Default")
            ?? throw new InvalidOperationException("Connection string 'Default' is missing.");
        _dbContext = dbContext;
    }

    public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT UserId, FullName, Email, PasswordHash, ProfilePhotoPath, Role, IsPrivacyPolicyAccepted, IsTermsOfServiceAccepted, CreatedAtUtc
            FROM dbo.Users
            WHERE Email = @Email
            """;

        await using var connection = new SqlConnection(_connectionString);
        return await connection.QuerySingleOrDefaultAsync<User>(
            new CommandDefinition(sql, new { Email = email }, cancellationToken: cancellationToken));
    }

    public async Task<User?> GetByIdAsync(Guid userId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT UserId, FullName, Email, PasswordHash, ProfilePhotoPath, Role, IsPrivacyPolicyAccepted, IsTermsOfServiceAccepted, CreatedAtUtc
            FROM dbo.Users
            WHERE UserId = @UserId
            """;

        await using var connection = new SqlConnection(_connectionString);
        return await connection.QuerySingleOrDefaultAsync<User>(
            new CommandDefinition(sql, new { UserId = userId }, cancellationToken: cancellationToken));
    }

    public async Task<User> CreateAsync(User user, CancellationToken cancellationToken)
    {
        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return user;
    }

    public async Task<User> UpdateAsync(User user, CancellationToken cancellationToken)
    {
        _dbContext.Users.Update(user);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return user;
    }

    public async Task<List<UserAddress>> GetAddressesAsync(Guid userId, CancellationToken cancellationToken)
    {
        return await _dbContext.UserAddresses
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.IsSelected)
            .ThenByDescending(x => x.CreatedAtUtc)
            .ToListAsync(cancellationToken);
    }

    public async Task<UserAddress?> GetAddressByIdAsync(
        Guid userId,
        Guid addressId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.UserAddresses.FirstOrDefaultAsync(
            x => x.UserId == userId && x.AddressId == addressId,
            cancellationToken);
    }

    public async Task<UserAddress> AddAddressAsync(
        UserAddress address,
        CancellationToken cancellationToken)
    {
        _dbContext.UserAddresses.Add(address);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return address;
    }

    public async Task DeleteAddressAsync(UserAddress address, CancellationToken cancellationToken)
    {
        _dbContext.UserAddresses.Remove(address);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken)
    {
        return _dbContext.SaveChangesAsync(cancellationToken);
    }
}
