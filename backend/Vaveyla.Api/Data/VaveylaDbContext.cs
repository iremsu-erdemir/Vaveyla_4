using Microsoft.EntityFrameworkCore;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Data;

public sealed class VaveylaDbContext : DbContext
{
    public VaveylaDbContext(DbContextOptions<VaveylaDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<UserAddress> UserAddresses => Set<UserAddress>();
    public DbSet<Restaurant> Restaurants => Set<Restaurant>();
    public DbSet<MenuItem> MenuItems => Set<MenuItem>();
    public DbSet<RestaurantOrder> RestaurantOrders => Set<RestaurantOrder>();
    public DbSet<RestaurantReview> RestaurantReviews => Set<RestaurantReview>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var user = modelBuilder.Entity<User>();
        user.ToTable("Users");
        user.HasKey(x => x.UserId);
        user.Property(x => x.FullName).HasMaxLength(120).IsRequired();
        user.Property(x => x.Email).HasMaxLength(256).IsRequired();
        user.Property(x => x.PasswordHash).HasMaxLength(200).IsRequired();
        user.Property(x => x.ProfilePhotoPath).HasMaxLength(512);
        user.Property(x => x.Role)
            .HasConversion<byte>()
            .IsRequired();
        user.Property(x => x.IsPrivacyPolicyAccepted)
            .HasDefaultValue(false)
            .IsRequired();
        user.Property(x => x.IsTermsOfServiceAccepted)
            .HasDefaultValue(false)
            .IsRequired();
        user.Property(x => x.CreatedAtUtc)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();
        user.HasIndex(x => x.Email).IsUnique();
        user.HasMany(x => x.Addresses)
            .WithOne(x => x.User)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        var userAddress = modelBuilder.Entity<UserAddress>();
        userAddress.ToTable("UserAddresses");
        userAddress.HasKey(x => x.AddressId);
        userAddress.Property(x => x.UserId).IsRequired();
        userAddress.Property(x => x.Label).HasMaxLength(64).IsRequired();
        userAddress.Property(x => x.AddressLine).HasMaxLength(320).IsRequired();
        userAddress.Property(x => x.AddressDetail).HasMaxLength(320);
        userAddress.Property(x => x.IsSelected).HasDefaultValue(false).IsRequired();
        userAddress.Property(x => x.CreatedAtUtc)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();
        userAddress.HasIndex(x => x.UserId);

        var restaurant = modelBuilder.Entity<Restaurant>();
        restaurant.ToTable("Restaurants");
        restaurant.HasKey(x => x.RestaurantId);
        restaurant.Property(x => x.OwnerUserId).IsRequired();
        restaurant.Property(x => x.Name).HasMaxLength(160).IsRequired();
        restaurant.Property(x => x.Type).HasMaxLength(120).IsRequired();
        restaurant.Property(x => x.Address).HasMaxLength(320).IsRequired();
        restaurant.Property(x => x.Phone).HasMaxLength(40).IsRequired();
        restaurant.Property(x => x.WorkingHours).HasMaxLength(60).IsRequired();
        restaurant.Property(x => x.PhotoPath).HasMaxLength(512);
        restaurant.Property(x => x.OrderNotifications).HasDefaultValue(true).IsRequired();
        restaurant.Property(x => x.IsOpen).HasDefaultValue(true).IsRequired();
        restaurant.Property(x => x.CreatedAtUtc)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();
        restaurant.HasIndex(x => x.OwnerUserId).IsUnique();

        var menuItem = modelBuilder.Entity<MenuItem>();
        menuItem.ToTable("MenuItems");
        menuItem.HasKey(x => x.MenuItemId);
        menuItem.Property(x => x.RestaurantId).IsRequired();
        menuItem.Property(x => x.Name).HasMaxLength(160).IsRequired();
        menuItem.Property(x => x.Price).IsRequired();
        menuItem.Property(x => x.ImagePath).HasMaxLength(512).IsRequired();
        menuItem.Property(x => x.IsAvailable).HasDefaultValue(true).IsRequired();
        menuItem.Property(x => x.IsFeatured).HasDefaultValue(false).IsRequired();
        menuItem.Property(x => x.CreatedAtUtc)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();
        menuItem.HasIndex(x => x.RestaurantId);

        var order = modelBuilder.Entity<RestaurantOrder>();
        order.ToTable("RestaurantOrders");
        order.HasKey(x => x.OrderId);
        order.Property(x => x.RestaurantId).IsRequired();
        order.Property(x => x.Items).HasMaxLength(600).IsRequired();
        order.Property(x => x.ImagePath).HasMaxLength(512);
        order.Property(x => x.PreparationMinutes);
        order.Property(x => x.Total).IsRequired();
        order.Property(x => x.Status)
            .HasConversion<byte>()
            .IsRequired();
        order.Property(x => x.CreatedAtUtc)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();
        order.HasIndex(x => x.RestaurantId);

        var review = modelBuilder.Entity<RestaurantReview>();
        review.ToTable("RestaurantReviews");
        review.HasKey(x => x.ReviewId);
        review.Property(x => x.RestaurantId).IsRequired();
        review.Property(x => x.CustomerName).HasMaxLength(120).IsRequired();
        review.Property(x => x.Rating).IsRequired();
        review.Property(x => x.Comment).HasMaxLength(800).IsRequired();
        review.Property(x => x.OwnerReply).HasMaxLength(800);
        review.Property(x => x.CreatedAtUtc)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();
        review.HasIndex(x => x.RestaurantId);
    }
}
