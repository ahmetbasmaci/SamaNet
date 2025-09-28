using Microsoft.AspNetCore.SignalR;
using SamaNetMessaegingAppApi.DTOs;
using SamaNetMessaegingAppApi.Services.Interfaces;

namespace SamaNetMessaegingAppApi.Hubs
{
    /// <summary>
    /// SignalR Hub for real-time chat messaging
    /// </summary>
    public class ChatHub : Hub
    {
        private readonly IMessageService _messageService;
        private readonly IUserService _userService;
        private static readonly Dictionary<string, int> _connectionUserMap = new();
        private static readonly Dictionary<int, HashSet<string>> _userConnectionMap = new();

        public static string GetUserGroupName(int userId) => $"user:{userId}";

        public ChatHub(IMessageService messageService, IUserService userService)
        {
            _messageService = messageService;
            _userService = userService;
        }

        /// <summary>
        /// User joins the chat with their user ID
        /// </summary>
        public async Task JoinChat(int userId)
        {
            _connectionUserMap[Context.ConnectionId] = userId;

            if (!_userConnectionMap.ContainsKey(userId))
            {
                _userConnectionMap[userId] = new HashSet<string>();
            }
            _userConnectionMap[userId].Add(Context.ConnectionId);

            await Groups.AddToGroupAsync(Context.ConnectionId, GetUserGroupName(userId));

            // Update user's last seen
            await _userService.UpdateLastSeenAsync(userId);

            // Notify others that user is online
            await Clients.Others.SendAsync("UserOnline", userId);
        }

        /// <summary>
        /// Send a text message to another user
        /// </summary>
        public async Task SendMessage(SendMessageRequestDto messageRequest)
        {
            try
            {
                if (!_connectionUserMap.TryGetValue(Context.ConnectionId, out var senderId))
                {
                    await Clients.Caller.SendAsync("Error", "User not authenticated");
                    return;
                }

                var message = await _messageService.SendMessageAsync(senderId, messageRequest);

                // Send confirmation to sender group
                await Clients.Group(GetUserGroupName(senderId)).SendAsync("MessageSent", message);

                // Broadcast to receiver group
                await Clients.Group(GetUserGroupName(messageRequest.ReceiverId)).SendAsync("MessageReceived", message);

                if (_userConnectionMap.TryGetValue(messageRequest.ReceiverId, out var receiverConnections) &&
                    receiverConnections.Count > 0)
                {
                    // Mark as delivered since receiver is online
                    await _messageService.MarkMessageAsDeliveredAsync(message.Id);

                    // Notify sender about delivery
                    await Clients.Group(GetUserGroupName(senderId))
                        .SendAsync("MessageDelivered", new { MessageId = message.Id, DeliveredAt = DateTime.UtcNow });
                }
            }
            catch (Exception ex)
            {
                await Clients.Caller.SendAsync("Error", ex.Message);
            }
        }

        /// <summary>
        /// Mark a message as read
        /// </summary>
        public async Task MarkMessageAsRead(int messageId)
        {
            try
            {
                if (!_connectionUserMap.TryGetValue(Context.ConnectionId, out var userId))
                {
                    await Clients.Caller.SendAsync("Error", "User not authenticated");
                    return;
                }

                var success = await _messageService.MarkMessageAsReadAsync(userId, messageId);
                if (success)
                {
                    var message = await _messageService.GetMessageByIdAsync(messageId);
                    if (message != null)
                    {
                        await Clients.Group(GetUserGroupName(message.SenderId))
                            .SendAsync("MessageRead", new { MessageId = messageId, ReadAt = DateTime.UtcNow, ReadBy = userId });
                    }
                }
            }
            catch (Exception ex)
            {
                await Clients.Caller.SendAsync("Error", ex.Message);
            }
        }

        /// <summary>
        /// User starts typing
        /// </summary>
        public async Task StartTyping(int receiverId)
        {
            if (!_connectionUserMap.TryGetValue(Context.ConnectionId, out var senderId))
                return;

            await Clients.Group(GetUserGroupName(receiverId)).SendAsync("UserStartedTyping", senderId);
        }

        /// <summary>
        /// User stops typing
        /// </summary>
        public async Task StopTyping(int receiverId)
        {
            if (!_connectionUserMap.TryGetValue(Context.ConnectionId, out var senderId))
                return;

            await Clients.Group(GetUserGroupName(receiverId)).SendAsync("UserStoppedTyping", senderId);
        }

        /// <summary>
        /// Handle user disconnection
        /// </summary>
        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            if (_connectionUserMap.TryGetValue(Context.ConnectionId, out var userId))
            {
                _connectionUserMap.Remove(Context.ConnectionId);

                if (_userConnectionMap.TryGetValue(userId, out var connections))
                {
                    connections.Remove(Context.ConnectionId);
                    await Groups.RemoveFromGroupAsync(Context.ConnectionId, GetUserGroupName(userId));
                    
                    // If user has no more connections, mark as offline
                    if (connections.Count == 0)
                    {
                        _userConnectionMap.Remove(userId);
                        await _userService.UpdateLastSeenAsync(userId);
                        await Clients.Others.SendAsync("UserOffline", userId);
                    }
                }
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Get online users (for debugging/admin purposes)
        /// </summary>
        public async Task GetOnlineUsers()
        {
            var onlineUsers = _userConnectionMap.Keys.ToList();
            await Clients.Caller.SendAsync("OnlineUsers", onlineUsers);
        }
    }
}