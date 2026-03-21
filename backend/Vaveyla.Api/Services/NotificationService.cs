using System.Text.Json;
using Microsoft.AspNetCore.SignalR;
using Vaveyla.Api.Data;
using Vaveyla.Api.Hubs;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Services;

public interface INotificationService
{
    Task<NotificationDto> SendToUserAsync(
        Guid userId,
        NotificationType type,
        string title,
        string message,
        Guid? relatedOrderId,
        Dictionary<string, object?>? data,
        CancellationToken cancellationToken);
    Task<int> SendToRoleAsync(
        UserRole role,
        NotificationType type,
        string title,
        string message,
        Guid? relatedOrderId,
        Dictionary<string, object?>? data,
        CancellationToken cancellationToken);
    Task<List<NotificationDto>> GetUserNotificationsAsync(
        Guid userId,
        int page,
        int pageSize,
        bool? isRead,
        CancellationToken cancellationToken);
    Task<int> GetUnreadCountAsync(Guid userId, CancellationToken cancellationToken);
    Task<bool> MarkAsReadAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken);
    Task MarkAllAsReadAsync(Guid userId, CancellationToken cancellationToken);
    Task RegisterDeviceTokenAsync(Guid userId, string platform, string token, CancellationToken cancellationToken);
    Task NotifyOrderCreatedAsync(CustomerOrder order, CancellationToken cancellationToken);
    Task NotifyOwnerOrderStatusChangedAsync(CustomerOrder order, CustomerOrderStatus previousStatus, CancellationToken cancellationToken);
    Task NotifyCourierAcceptedAsync(CustomerOrder order, CancellationToken cancellationToken);
    Task NotifyCourierStatusChangedAsync(CustomerOrder order, CustomerOrderStatus previousStatus, CancellationToken cancellationToken);
}

public sealed class NotificationService : INotificationService
{
    private readonly INotificationRepository _repository;
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly IPushNotificationSender _pushNotificationSender;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        INotificationRepository repository,
        IHubContext<NotificationHub> hubContext,
        IPushNotificationSender pushNotificationSender,
        ILogger<NotificationService> logger)
    {
        _repository = repository;
        _hubContext = hubContext;
        _pushNotificationSender = pushNotificationSender;
        _logger = logger;
    }

    public async Task<NotificationDto> SendToUserAsync(
        Guid userId,
        NotificationType type,
        string title,
        string message,
        Guid? relatedOrderId,
        Dictionary<string, object?>? data,
        CancellationToken cancellationToken)
    {
        var user = await _repository.GetUserAsync(userId, cancellationToken);
        if (user is null)
        {
            throw new InvalidOperationException("Target user was not found.");
        }

        var payloadJson = data is null ? null : JsonSerializer.Serialize(data);
        var entity = new Notification
        {
            NotificationId = Guid.NewGuid(),
            UserId = userId,
            UserRole = user.Role,
            Type = type,
            Title = title.Trim(),
            Message = message.Trim(),
            DataJson = payloadJson,
            RelatedOrderId = relatedOrderId,
            IsRead = false,
            CreatedAtUtc = DateTime.UtcNow,
        };

        await _repository.AddAsync(entity, cancellationToken);
        var dto = Map(entity);
        await PublishRealtimeAsync(dto, cancellationToken);
        await TrySendPushAsync(dto, cancellationToken);
        return dto;
    }

    public async Task<int> SendToRoleAsync(
        UserRole role,
        NotificationType type,
        string title,
        string message,
        Guid? relatedOrderId,
        Dictionary<string, object?>? data,
        CancellationToken cancellationToken)
    {
        var userIds = await _repository.GetUserIdsByRoleAsync(role, cancellationToken);
        var sentCount = 0;

        foreach (var userId in userIds)
        {
            await SendToUserAsync(
                userId,
                type,
                title,
                message,
                relatedOrderId,
                data,
                cancellationToken);
            sentCount++;
        }

        return sentCount;
    }

    public async Task<List<NotificationDto>> GetUserNotificationsAsync(
        Guid userId,
        int page,
        int pageSize,
        bool? isRead,
        CancellationToken cancellationToken)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 1;
        if (pageSize > 100) pageSize = 100;

        var notifications = await _repository.GetByUserAsync(
            userId,
            page,
            pageSize,
            isRead,
            cancellationToken);
        return notifications.Select(Map).ToList();
    }

    public Task<int> GetUnreadCountAsync(Guid userId, CancellationToken cancellationToken)
    {
        return _repository.GetUnreadCountAsync(userId, cancellationToken);
    }

    public async Task<bool> MarkAsReadAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken)
    {
        var notification = await _repository.GetByIdAsync(notificationId, cancellationToken);
        if (notification is null || notification.UserId != userId)
        {
            return false;
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAtUtc = DateTime.UtcNow;
            await _repository.MarkAsReadAsync(notification, cancellationToken);
        }

        return true;
    }

    public Task MarkAllAsReadAsync(Guid userId, CancellationToken cancellationToken)
    {
        return _repository.MarkAllAsReadAsync(userId, cancellationToken);
    }

    public Task RegisterDeviceTokenAsync(
        Guid userId,
        string platform,
        string token,
        CancellationToken cancellationToken)
    {
        var entity = new UserDeviceToken
        {
            DeviceTokenId = Guid.NewGuid(),
            UserId = userId,
            Platform = platform.Trim(),
            Token = token.Trim(),
            LastSeenAtUtc = DateTime.UtcNow,
            CreatedAtUtc = DateTime.UtcNow,
        };

        return _repository.UpsertDeviceTokenAsync(entity, cancellationToken);
    }

    public async Task NotifyOrderCreatedAsync(CustomerOrder order, CancellationToken cancellationToken)
    {
        await SendToUserAsync(
            order.CustomerUserId,
            NotificationType.OrderCreated,
            "Siparişiniz alındı",
            $"#{order.OrderId.ToString()[..8]} numaralı siparişiniz oluşturuldu.",
            order.OrderId,
            OrderData(order),
            cancellationToken);

        var ownerUserId = await _repository.GetRestaurantOwnerUserIdAsync(order.RestaurantId, cancellationToken);
        if (ownerUserId.HasValue)
        {
            await SendToUserAsync(
                ownerUserId.Value,
                NotificationType.NewOrderForOwner,
                "Yeni sipariş geldi",
                $"Yeni bir müşteri siparişi var: #{order.OrderId.ToString()[..8]}",
                order.OrderId,
                OrderData(order),
                cancellationToken);
        }
    }

    public async Task NotifyOwnerOrderStatusChangedAsync(
        CustomerOrder order,
        CustomerOrderStatus previousStatus,
        CancellationToken cancellationToken)
    {
        if (order.Status == previousStatus)
        {
            return;
        }

        if (order.Status == CustomerOrderStatus.Preparing)
        {
            await SendToUserAsync(
                order.CustomerUserId,
                NotificationType.OrderPreparing,
                "Sipariş hazırlanıyor",
                $"#{order.OrderId.ToString()[..8]} siparişiniz hazırlanmaya başlandı.",
                order.OrderId,
                OrderData(order),
                cancellationToken);

            await SendToRoleAsync(
                UserRole.Courier,
                NotificationType.OrderReadyForCourier,
                "Hazır sipariş bekliyor",
                $"#{order.OrderId.ToString()[..8]} siparişi teslimat için hazır.",
                order.OrderId,
                OrderData(order),
                cancellationToken);
        }

        if (order.Status == CustomerOrderStatus.Assigned)
        {
            await SendToRoleAsync(
                UserRole.Courier,
                NotificationType.OrderReadyForCourier,
                "Hazır sipariş bekliyor",
                $"#{order.OrderId.ToString()[..8]} siparişi teslimat için hazır.",
                order.OrderId,
                OrderData(order),
                cancellationToken);
        }

        if (order.Status == CustomerOrderStatus.Cancelled)
        {
            var ownerUserId = await _repository.GetRestaurantOwnerUserIdAsync(order.RestaurantId, cancellationToken);
            if (ownerUserId.HasValue)
            {
                await SendToUserAsync(
                    ownerUserId.Value,
                    NotificationType.OrderCancelledForOwner,
                    "Sipariş iptal edildi",
                    $"#{order.OrderId.ToString()[..8]} siparişi iptal edildi.",
                    order.OrderId,
                    OrderData(order),
                    cancellationToken);
            }
        }
    }

    public async Task NotifyCourierAcceptedAsync(CustomerOrder order, CancellationToken cancellationToken)
    {
        if (!order.AssignedCourierUserId.HasValue)
        {
            return;
        }

        var courierUserId = order.AssignedCourierUserId.Value;
        await SendToUserAsync(
            courierUserId,
            NotificationType.NewDeliveryTaskForCourier,
            "Yeni teslimat görevi",
            $"#{order.OrderId.ToString()[..8]} siparişi size atandı.",
            order.OrderId,
            OrderData(order),
            cancellationToken);

        var ownerUserId = await _repository.GetRestaurantOwnerUserIdAsync(order.RestaurantId, cancellationToken);
        if (ownerUserId.HasValue)
        {
            await SendToUserAsync(
                ownerUserId.Value,
                NotificationType.CourierPickedUpForOwner,
                "Kurye siparişi teslim aldı",
                $"#{order.OrderId.ToString()[..8]} siparişini kurye teslim aldı.",
                order.OrderId,
                OrderData(order),
                cancellationToken);
        }
    }

    public async Task NotifyCourierStatusChangedAsync(
        CustomerOrder order,
        CustomerOrderStatus previousStatus,
        CancellationToken cancellationToken)
    {
        if (order.Status == previousStatus)
        {
            return;
        }

        if (order.Status == CustomerOrderStatus.InTransit)
        {
            await SendToUserAsync(
                order.CustomerUserId,
                NotificationType.CourierDispatched,
                "Kurye yola çıktı",
                $"#{order.OrderId.ToString()[..8]} siparişiniz yola çıktı.",
                order.OrderId,
                OrderData(order),
                cancellationToken);
        }

        if (order.Status == CustomerOrderStatus.Delivered)
        {
            await SendToUserAsync(
                order.CustomerUserId,
                NotificationType.OrderDelivered,
                "Sipariş teslim edildi",
                $"#{order.OrderId.ToString()[..8]} siparişiniz teslim edildi.",
                order.OrderId,
                OrderData(order),
                cancellationToken);

            if (order.AssignedCourierUserId.HasValue)
            {
                await SendToUserAsync(
                    order.AssignedCourierUserId.Value,
                    NotificationType.DeliveryCompletedForCourier,
                    "Teslimat tamamlandı",
                    $"#{order.OrderId.ToString()[..8]} teslimatı başarıyla tamamlandı.",
                    order.OrderId,
                    OrderData(order),
                    cancellationToken);
            }
        }
    }

    private async Task PublishRealtimeAsync(NotificationDto notification, CancellationToken cancellationToken)
    {
        await _hubContext.Clients
            .Group($"user:{notification.UserId}")
            .SendAsync("notification_received", notification, cancellationToken);
    }

    private async Task TrySendPushAsync(NotificationDto notification, CancellationToken cancellationToken)
    {
        var tokens = await _repository.GetDeviceTokensAsync(notification.UserId, cancellationToken);
        if (tokens.Count == 0)
        {
            return;
        }

        foreach (var token in tokens)
        {
            try
            {
                await _pushNotificationSender.SendAsync(
                    token.Token,
                    new PushMessage(
                        notification.Title,
                        notification.Message,
                        new Dictionary<string, string>
                        {
                            ["notificationId"] = notification.NotificationId.ToString(),
                            ["userId"] = notification.UserId.ToString(),
                            ["type"] = notification.Type,
                            ["relatedOrderId"] = notification.RelatedOrderId?.ToString() ?? string.Empty,
                        }),
                    cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Push notification failed for user {UserId} token {Token}.",
                    notification.UserId,
                    token.Token);
            }
        }
    }

    private static Dictionary<string, object?> OrderData(CustomerOrder order)
    {
        return new Dictionary<string, object?>
        {
            ["orderId"] = order.OrderId,
            ["restaurantId"] = order.RestaurantId,
            ["status"] = order.Status.ToString(),
            ["total"] = order.Total,
        };
    }

    private static NotificationDto Map(Notification n)
    {
        return new NotificationDto(
            n.NotificationId,
            n.UserId,
            n.UserRole.ToString(),
            n.Type.ToString(),
            n.Title,
            n.Message,
            n.IsRead,
            n.CreatedAtUtc,
            n.ReadAtUtc,
            n.RelatedOrderId,
            n.DataJson);
    }
}
