# Quick Start: Using Block User Feature

## For Developers

### Backend Setup (C#)

1. **Apply Database Migration**
   ```bash
   cd SamaNetMessaegingAppApi/SamaNetMessaegingAppApi
   dotnet ef database update
   ```

2. **Run the API**
   ```bash
   dotnet run
   ```

3. **Test with Swagger**
   - Navigate to: `http://localhost:5000/swagger`
   - Try the new endpoints under "Users" section

### Frontend Setup (Flutter)

1. **Get Dependencies**
   ```bash
   cd sama_net_messaging_app_mobile
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

## For Users

### How to Block a User

1. Open a chat with the user you want to block
2. Tap the three-dot menu (⋮) in the top right
3. Select "حظر المستخدم" (Block User)
4. Confirm your choice in the dialog
5. Wait for the confirmation message
6. You'll be returned to the conversations list

### What Happens When You Block Someone

- You won't see their messages (in future versions)
- They won't appear in your search results (in future versions)
- You can unblock them later from the blocked users list (in future versions)

## API Testing Examples

### Block a User
```bash
curl -X POST "http://localhost:5000/api/users/1/block" \
  -H "Content-Type: application/json" \
  -d '{"blockedUserId": 2}'
```

### Unblock a User
```bash
curl -X DELETE "http://localhost:5000/api/users/1/unblock/2"
```

### Check if User is Blocked
```bash
curl -X GET "http://localhost:5000/api/users/1/is-blocked/2"
```

### Get Blocked Users List
```bash
curl -X GET "http://localhost:5000/api/users/1/blocked-users"
```

## Common Issues & Solutions

### Issue: Migration Error
**Solution**: Make sure you're in the correct directory and have the Entity Framework CLI tools installed:
```bash
dotnet tool install --global dotnet-ef
```

### Issue: Service Not Found Error (Flutter)
**Solution**: Make sure you call `initializeDependencies()` before using any services:
```dart
await initializeDependencies();
```

### Issue: Block Button Doesn't Appear
**Solution**: Verify you're viewing the messages page (not the conversations list)

## Database Schema

The UserBlocks table structure:
```
UserBlocks
├── Id (PK)
├── BlockerId (FK → Users.Id)
├── BlockedUserId (FK → Users.Id)
└── BlockedAt (DateTime)

Indexes:
- Unique: (BlockerId, BlockedUserId)
- IDX_UserBlocks_Blocker
- IDX_UserBlocks_Blocked
```

## Important Notes

- ⚠️ You cannot block yourself
- ⚠️ Blocking is one-way (A blocks B doesn't mean B blocks A)
- ⚠️ Duplicate blocks are prevented automatically
- ✅ Blocks are permanent until manually unblocked
- ✅ All operations are logged with timestamps

## Future Enhancements Planned

1. Message filtering from blocked users
2. Search results filtering
3. Blocked users management page
4. Unblock functionality from UI
5. Block status indicators

---

**Need Help?** Check the full documentation in `USER_BLOCK_FEATURE_GUIDE.md`
