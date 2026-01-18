# Mock Data Seed Script

This script generates comprehensive test data for NWU Connect, including users, profiles, posts, conversations, messages, swipes, and matches.

## What It Generates

- **120 Users**: Firebase Auth accounts + MongoDB user documents
- **120 Profiles**: Complete user profiles with interests, departments, student IDs
- **200 Posts**: With random likes (0-20 per post) and comments (0-10 per post)
- **500 Swipes**: Like/pass actions between users
- **Matches**: Automatic match detection when two users like Each other
- **80 Conversations**: With 5-15 messages each

## Features

✨ **Realistic Data**:
- Bangladeshi names (mix of Hindu and Muslim names)
- Valid NWU email addresses
- Diverse departments and interests
- Random engagement (likes, comments)
- Varied online status
- **Profile Images**: UI Avatars with custom colors matching app theme
- **Post Images**: 40% of posts include 1-3 high-quality Lorem Picsum images
- **Cover Photos**: Unique cover images for each profile

🔗 **Interconnected**:
- Posts have likes from other users
- Posts have comments from other users
- Conversations between random users
- Swipes create matches
- All relationships use proper Firebase UIDs

## Usage

### Prerequisites

1. Make sure your server is configured with:
   - MongoDB connection
   - Firebase Admin SDK initialized
   - All models registered

### Run the Script

```bash
# From the server directory
npm run seed:mock
```

### What Happens

The script will:
1. ✅ Create 120 Firebase Auth users
2. ✅ Create 120 MongoDB User documents
3. ✅ Create 120 Profile documents
4. ✅ Create 200 Posts with engagement
5. ✅ Create 500 Swipes with auto-matching
6. ✅ Create 80 Conversations with messages

### Test Credentials

All generated users have the same password for easy testing:

- **Password**: `Test@123`
- **Email Format**: `[firstname].[lastname].[number]@nwu.ac.bd`

Example users will be printed at the end of the script execution.

## Output Example

```
🚀 Starting Mock Data Generation...

📋 Step 1: Creating users in Firebase and MongoDB...
  ✓ Created 10/120 users
  ✓ Created 20/120 users
  ...
✅ Created 120 users

👤 Step 2: Creating user profiles...
  ✓ Created 20/120 profiles
  ...
✅ Created 120 profiles

📝 Step 3: Creating posts with engagement...
  ✓ Created 50/200 posts
  ...
✅ Created 200 posts

💖 Step 4: Creating swipes and matches...
✅ Created swipes with 45 matches

💬 Step 5: Creating conversations and messages...
  ✓ Created 20/80 conversations
  ...
✅ Created 80 conversations with messages

🎉 Mock Data Generation Complete!

📊 Summary:
   • Users: 120
   • Profiles: 120
   • Posts: 200
   • Matches: 45
   • Conversations: 80

💡 Test Credentials:
   Email: [any generated email]
   Password: Test@123

Example users:
   - aarav.sharma.0@nwu.edu.bd
   - aditi.patel.1@nwu.edu.bd
   - aryan.singh.2@nwu.edu.bd
   - diya.kumar.3@nwu.edu.bd
   - kabir.gupta.4@nwu.edu.bd
```

## Important Notes

⚠️ **Warning**: This script creates real Firebase Auth users. Running it multiple times may result in errors for duplicate emails.

💡 **Tip**: You can modify the following constants in the script:
- `NUM_USERS`: Number of users to create (default: 120)
- `NUM_POSTS`: Number of posts to create (default: 200)
- `NUM_SWIPES`: Number of swipe actions (default: 500)
- `NUM_CONVERSATIONS`: Number of conversations (default: 80)

## Cleanup

If you need to clean up the test data:

1. **MongoDB**: Use MongoDB Compass or CLI to drop collections
2. **Firebase**: Use Firebase Console → Authentication to bulk delete users

## Troubleshooting

**Error: "Email already exists"**
- The script will skip users that already exist and continue

**Error: "Cannot connect to MongoDB"**
- Check your `.env` file for correct MongoDB connection string

**Error: "Firebase Admin SDK not initialized"**
- Verify `firebase-service-account.json` exists and is configured correctly

## Customization

You can customize the generated data by editing the arrays in `MockDataGenerator`:

- `firstNames`: Add more first names
- `lastNames`: Add more last names  
- `postContentTemplates`: Add more post content variations
- `bioTemplates`: Add more bio variations
- `interests`: Add more interest options

Enjoy testing with realistic data! 🎉
