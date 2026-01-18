/**
 * Mock Data Seed Script for NWU Connect
 * 
 * This script generates 100+ mock users with:
 * - User accounts in MongoDB
 * - Firebase Auth accounts
 * - Profiles with realistic data
 * - Posts with likes and comments
 * - Conversations and messages
 * - Swipes and matches for the connect feature
 * 
 * Usage: npm run seed:mock
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { getModelToken } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as admin from 'firebase-admin';

// Mock Data Generator Utilities

// Image placeholder services
const AVATAR_SERVICE = 'https://ui-avatars.com/api/';
const IMAGE_SERVICE = 'https://picsum.photos/';
class MockDataGenerator {
    private firstNames = [
        'Aarav', 'Aditi', 'Aryan', 'Diya', 'Kabir', 'Kiara', 'Rohan', 'Saanvi',
        'Vihaan', 'Ananya', 'Ishaan', 'Aanya', 'Advait', 'Sara', 'Sai', 'Aadhya',
        'Reyansh', 'Navya', 'Ayaan', 'Pari', 'Krishna', 'Myra', 'Shaurya', 'Anika',
        'Atharv', 'Ira', 'Vivaan', 'Riya', 'Aditya', 'Anvi', 'Arjun', 'Shanaya',
        'Shlok', 'Tara', 'Om', 'Zara', 'Dhruv', 'Aarohi', 'Kian', 'Avni',
        'Mohammed', 'Fatima', 'Ali', 'Zainab', 'Omar', 'Maryam', 'Ibrahim', 'Aisha',
        'Yusuf', 'Layla', 'Hassan', 'Noor', 'Bilal', 'Hana', 'Ahmed', 'Safiya'
    ];

    private lastNames = [
        'Sharma', 'Patel', 'Singh', 'Kumar', 'Gupta', 'Reddy', 'Rao', 'Khan',
        'Ahmed', 'Ali', 'Rahman', 'Islam', 'Hossain', 'Das', 'Roy', 'Nath',
        'Chakraborty', 'Banerjee', 'Ghosh', 'Mukherjee', 'Bose', 'Sen', 'Dutta', 'Saha'
    ];

    private departments = [
        'CSE', 'EEE', 'ECE', 'Civil Engineering', 'Business Administration',
        'Law', 'English', 'Economics', 'Sociology', 'Development Studies', 'Public Health'
    ];

    private interests = [
        'Coding', 'Photography', 'Travel', 'Music', 'Reading', 'Sports', 'Art',
        'Gaming', 'Cooking', 'Dancing', 'Fitness', 'Movies', 'Writing', 'Volunteering',
        'Entrepreneurship', 'Fashion', 'Technology', 'Science', 'Nature', 'Astronomy'
    ];

    private years = ['1.1', '1.2', '2.1', '2.2', '3.1', '3.2', '4.1', '4.2'];
    private sections = ['A', 'B', 'C', 'D'];

    private postContentTemplates = [
        // Academic Life
        "Just aced my Data Structures exam! All those late nights paid off 🎓",
        "Group presentation went amazing! Teamwork makes the dream work 📊",
        "Finally submitted my thesis proposal. Feeling relieved! 📝",
        "Library vibes on point today. 3rd floor is the best study spot 📚☕",
        "Who else is surviving on coffee and deadlines this week? 😅",

        // Campus Social
        "Beautiful sunrise from the NWU rooftop this morning 🌅",
        "Just had the best samosa from the canteen. Nothing beats campus food! 🥟",
        "Friday afternoon classes hit different 😴",
        "Made some amazing friends in my Economics class! Love this community ❤️",
        "Campus photoshoot with the squad! Check out these shots 📸",

        // Events & Activities
        "Tech fest is coming up! Who's ready for the hackathon? 💻🚀",
        "Volunteering at the community service event tomorrow. Join us! 🤝",
        "Just joined the Photography Club! Excited for the weekend trip 📷",
        "Debate competition finals were intense! So proud of our team 🏆",
        "Cultural night was absolutely incredible! The performances were 🔥",

        // Student Life
        "New semester, new opportunities! Let's make it count ✨",
        "Looking for a study partner for Microeconomics. DM me! 📖",
        "That moment when you finally understand a concept you've been struggling with 💡",
        "Grabbed coffee before class. Anyone else at the campus cafe? ☕",
        "Weekend plans: catch up on sleep and maybe some assignments 😴",

        // Social/Connection
        "Anyone interested in starting a coding study group? Let's connect! 💻",
        "Just met someone with the same music taste! Small world 🎵",
        "Looking forward to the department mixer this weekend 🎉",
        "Love how diverse and welcoming our campus community is 🌍❤️",
        "Great conversation at the student lounge today. This is what college is about! 💬"
    ];

    private bioTemplates = [
        "Tech enthusiast | Coffee lover ☕",
        "Passionate about innovation and creativity 🚀",
        "Dream big, work hard, stay humble ✨",
        "Engineering student by day, coder by night 💻",
        "Making the world a better place, one line of code at a time 🌍",
        "Living life one adventure at a time 🌟",
        "Aspiring entrepreneur | Tech geek 💡",
        "Books, code, and everything nice 📚",
        "Always learning, always growing 🌱",
        "Future engineer in the making 🔧"
    ];

    generateFullName(): { firstName: string; lastName: string; fullName: string } {
        const firstName = this.firstNames[Math.floor(Math.random() * this.firstNames.length)];
        const lastName = this.lastNames[Math.floor(Math.random() * this.lastNames.length)];
        return { firstName, lastName, fullName: `${firstName} ${lastName}` };
    }

    generateEmail(name: string, index: number): string {
        const cleanName = name.toLowerCase().replace(/\s+/g, '.');
        return `${cleanName}.${index}@nwu.edu.bd`;
    }

    generateDepartment(): string {
        return this.departments[Math.floor(Math.random() * this.departments.length)];
    }

    generateInterests(count: number = 3): string[] {
        const shuffled = [...this.interests].sort(() => 0.5 - Math.random());
        return shuffled.slice(0, count);
    }

    generateStudentId(index: number): string {
        const year = 2021 + Math.floor(Math.random() * 4);
        return `${year}${String(index).padStart(6, '0')}`;
    }

    generateYear(): string {
        return this.years[Math.floor(Math.random() * this.years.length)];
    }

    generateSection(): string {
        return this.sections[Math.floor(Math.random() * this.sections.length)];
    }

    generateBio(): string {
        return this.bioTemplates[Math.floor(Math.random() * this.bioTemplates.length)];
    }

    generatePostContent(): string {
        return this.postContentTemplates[Math.floor(Math.random() * this.postContentTemplates.length)];
    }

    generateRandomDate(start: Date, end: Date): Date {
        return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
    }

    generateProfileImage(name: string, index: number): string {
        // Use RandomUser.me API for realistic profile photos
        // The seed ensures consistent photos for the same index
        return `https://randomuser.me/api/portraits/${index % 2 === 0 ? 'men' : 'women'}/${(index % 99) + 1}.jpg`;
    }

    generatePostImages(count: number = 0): string[] {
        if (count === 0) return [];
        const images: string[] = [];
        for (let i = 0; i < count; i++) {
            // Use Lorem Picsum for varied, high-quality placeholder images
            const imageId = 100 + Math.floor(Math.random() * 900); // Random image ID
            images.push(`${IMAGE_SERVICE}800/600?random=${imageId}`);
        }
        return images;
    }

    generateCoverPhoto(index: number): string {
        // Use Lorem Picsum for cover photos with landscape orientation
        const imageId = 1 + (index % 50); // Cycle through image IDs
        return `${IMAGE_SERVICE}1200/400?random=${imageId}`;
    }
}

async function bootstrap() {
    console.log('🚀 Starting Mock Data Generation...\n');

    // Initialize Firebase Admin SDK
    try {
        const path = require('path');
        const serviceAccountPath = path.resolve(__dirname, '../firebase-service-account.json');
        const serviceAccount = require(serviceAccountPath);

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            databaseURL: process.env.FIREBASE_DATABASE_URL || 'https://nwu-connect-default-rtdb.firebaseio.com'
        });
        console.log('✅ Firebase Admin initialized\n');
    } catch (error: any) {
        console.error('❌ Failed to initialize Firebase Admin:', error.message);
        console.error('Make sure firebase-service-account.json exists in the server root directory');
        process.exit(1);
    }

    const app = await NestFactory.createApplicationContext(AppModule);
    const generator = new MockDataGenerator();

    // Get models
    const UserModel = app.get<Model<any>>(getModelToken('User'));
    const ProfileModel = app.get<Model<any>>(getModelToken('Profile'));
    const PostModel = app.get<Model<any>>(getModelToken('Post'));
    const ConversationModel = app.get<Model<any>>(getModelToken('Conversation'));
    const MessageModel = app.get<Model<any>>(getModelToken('Message'));
    const SwipeModel = app.get<Model<any>>(getModelToken('Swipe'));
    const MatchModel = app.get<Model<any>>(getModelToken('Match'));

    const NUM_USERS = 250;
    const createdUsers: any[] = [];
    const createdProfiles: any[] = [];

    try {
        // Step 1: Create Firebase Users and MongoDB User Documents
        console.log('📋 Step 1: Creating users in Firebase and MongoDB...');
        for (let i = 0; i < NUM_USERS; i++) {
            const { fullName } = generator.generateFullName();
            const email = generator.generateEmail(fullName, i);
            const password = 'Test@123'; // Simple password for testing

            try {
                // Create Firebase user
                const firebaseUser = await admin.auth().createUser({
                    email,
                    password,
                    displayName: fullName,
                });

                // Create MongoDB user
                const department = generator.generateDepartment();
                const profileImage = generator.generateProfileImage(fullName, i);
                const user = await UserModel.create({
                    firebaseUid: firebaseUser.uid,
                    email,
                    status: Math.random() > 0.1 ? 'approved' : 'pending', // 90% approved
                    onboardingCompleted: true,
                    welcomeSeen: true,
                    name: fullName,
                    profileImage: profileImage,
                    department,
                    bio: generator.generateBio(),
                    role: 'user',
                });

                createdUsers.push({ firebaseUid: firebaseUser.uid, email, name: fullName, department });

                if ((i + 1) % 10 === 0) {
                    console.log(`  ✓ Created ${i + 1}/${NUM_USERS} users`);
                }
            } catch (error: any) {
                if (error.code === 'auth/email-already-exists') {
                    console.log(`  ⚠ User ${email} already exists, skipping...`);
                } else {
                    console.error(`  ✗ Error creating user ${email}:`, error.message);
                }
            }
        }
        console.log(`✅ Created ${createdUsers.length} users\n`);

        // Step 2: Create Profiles
        console.log('👤 Step 2: Creating user profiles...');
        for (let i = 0; i < createdUsers.length; i++) {
            const user = createdUsers[i];

            try {
                // Generate realistic images
                const profileImage = generator.generateProfileImage(user.name, i);
                const numPhotos = Math.floor(Math.random() * 3); // 0-2 additional photos
                const additionalPhotos = numPhotos > 0 ? generator.generatePostImages(numPhotos) : [];
                const photos = [profileImage, ...additionalPhotos];
                const coverPhoto = generator.generateCoverPhoto(i);

                const profile = await ProfileModel.create({
                    userId: user.firebaseUid,
                    name: user.name,
                    bio: generator.generateBio(),
                    interests: generator.generateInterests(Math.floor(Math.random() * 5) + 2),
                    photos: photos,
                    coverPhoto: coverPhoto,
                    department: user.department,
                    friendIds: [],
                    studentId: generator.generateStudentId(i),
                    year: generator.generateYear(),
                    section: generator.generateSection(),
                    isOnline: Math.random() > 0.5,
                    lastSeen: new Date(),
                });

                createdProfiles.push(profile);

                if ((i + 1) % 20 === 0) {
                    console.log(`  ✓ Created ${i + 1}/${createdUsers.length} profiles`);
                }
            } catch (error: any) {
                console.error(`  ✗ Error creating profile for ${user.email}:`, error.message);
            }
        }
        console.log(`✅ Created ${createdProfiles.length} profiles\n`);

        // Step 3: Create Posts with Likes and Comments
        console.log('📝 Step 3: Creating posts with engagement...');
        const NUM_POSTS = 600;
        const createdPosts: any[] = [];

        for (let i = 0; i < NUM_POSTS; i++) {
            const randomUser = createdUsers[Math.floor(Math.random() * createdUsers.length)];
            const visibility = ['public', 'friends', 'department'][Math.floor(Math.random() * 3)];

            try {
                // Random likes (0-20 likes per post)
                const numLikes = Math.floor(Math.random() * 20);
                const likes: string[] = [];
                for (let j = 0; j < numLikes; j++) {
                    const liker = createdUsers[Math.floor(Math.random() * createdUsers.length)];
                    if (!likes.includes(liker.firebaseUid)) {
                        likes.push(liker.firebaseUid);
                    }
                }

                // Random comments (0-10 comments per post)
                const numComments = Math.floor(Math.random() * 10);
                const comments: any[] = [];
                for (let j = 0; j < numComments; j++) {
                    const commenter = createdUsers[Math.floor(Math.random() * createdUsers.length)];
                    comments.push({
                        userId: commenter.firebaseUid,
                        text: `Great post! ${['👍', '❤️', '🔥', '💯'][Math.floor(Math.random() * 4)]}`,
                        createdAt: generator.generateRandomDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), new Date()),
                        replies: [],
                    });
                }

                // 40% of posts have images (1-3 images)
                const hasImages = Math.random() > 0.6;
                const numImages = hasImages ? Math.floor(Math.random() * 3) + 1 : 0;
                const imageUrls = generator.generatePostImages(numImages);

                const post = await PostModel.create({
                    userId: randomUser.firebaseUid,
                    content: generator.generatePostContent(),
                    imageUrls,
                    visibility,
                    authorDepartment: randomUser.department,
                    likes,
                    comments,
                    isArchived: false,
                    editHistory: [],
                });

                createdPosts.push(post);

                if ((i + 1) % 50 === 0) {
                    console.log(`  ✓ Created ${i + 1}/${NUM_POSTS} posts`);
                }
            } catch (error: any) {
                console.error(`  ✗ Error creating post:`, error.message);
            }
        }
        console.log(`✅ Created ${createdPosts.length} posts\n`);

        // Step 4: Create Swipes and Matches
        console.log('💖 Step 4: Creating swipes and matches...');
        const NUM_SWIPES = 2000;
        const createdMatches: any[] = [];
        const swipeMap = new Map<string, Set<string>>();

        for (let i = 0; i < NUM_SWIPES; i++) {
            const swiper = createdUsers[Math.floor(Math.random() * createdUsers.length)];
            const target = createdUsers[Math.floor(Math.random() * createdUsers.length)];

            if (swiper.firebaseUid === target.firebaseUid) continue;

            const swipeKey = `${swiper.firebaseUid}-${target.firebaseUid}`;
            if (swipeMap.has(swipeKey)) continue;

            try {
                const action = Math.random() > 0.3 ? 'like' : 'pass'; // 70% like rate

                await SwipeModel.create({
                    swiperId: swiper.firebaseUid,
                    targetId: target.firebaseUid,
                    action,
                });

                if (!swipeMap.has(swiper.firebaseUid)) {
                    swipeMap.set(swiper.firebaseUid, new Set());
                }
                swipeMap.get(swiper.firebaseUid)!.add(target.firebaseUid);

                // Check for match
                if (action === 'like') {
                    const reverseSwipe = await SwipeModel.findOne({
                        swiperId: target.firebaseUid,
                        targetId: swiper.firebaseUid,
                        action: 'like',
                    });

                    if (reverseSwipe) {
                        // It's a match!
                        const match = await MatchModel.create({
                            users: [swiper.firebaseUid, target.firebaseUid].sort(),
                            lastMessage: '',
                            lastMessageTime: new Date(),
                        });
                        createdMatches.push(match);
                    }
                }
            } catch (error: any) {
                if (!error.message.includes('duplicate key')) {
                    console.error(`  ✗ Error creating swipe:`, error.message);
                }
            }
        }
        console.log(`✅ Created swipes with ${createdMatches.length} matches\n`);

        // Step 5: Create Conversations and Messages
        console.log('💬 Step 5: Creating conversations and messages...');
        const NUM_CONVERSATIONS = 200;

        for (let i = 0; i < NUM_CONVERSATIONS; i++) {
            const user1 = createdUsers[Math.floor(Math.random() * createdUsers.length)];
            const user2 = createdUsers[Math.floor(Math.random() * createdUsers.length)];

            if (user1.firebaseUid === user2.firebaseUid) continue;

            try {
                const participants = [user1.firebaseUid, user2.firebaseUid].sort();

                // Check if conversation already exists
                const existing = await ConversationModel.findOne({ participants });
                if (existing) continue;

                // Create conversation
                const conversation = await ConversationModel.create({
                    participants,
                    lastMessage: 'Hey! How are you?',
                    lastMessageAt: new Date(),
                });

                // Create 5-15 messages
                const numMessages = 5 + Math.floor(Math.random() * 10);
                const messageTemplates = [
                    'Hey! How are you?',
                    'Did you finish the assignment?',
                    'Want to grab coffee later?',
                    'See you at the library!',
                    'Thanks for the notes!',
                    'Good luck on your exam!',
                    'That class was interesting!',
                    'Are you free this weekend?',
                    'Let me know when you get this',
                    'Talk to you later!'
                ];

                for (let j = 0; j < numMessages; j++) {
                    const sender = j % 2 === 0 ? user1.firebaseUid : user2.firebaseUid;
                    const content = messageTemplates[Math.floor(Math.random() * messageTemplates.length)];

                    await MessageModel.create({
                        conversationId: conversation._id.toString(),
                        senderId: sender,
                        content,
                        type: 'text',
                        status: Math.random() > 0.3 ? 'seen' : 'delivered',
                        read: Math.random() > 0.2,
                    });
                }

                if ((i + 1) % 20 === 0) {
                    console.log(`  ✓ Created ${i + 1}/${NUM_CONVERSATIONS} conversations`);
                }
            } catch (error: any) {
                console.error(`  ✗ Error creating conversation:`, error.message);
            }
        }
        console.log(`✅ Created ${NUM_CONVERSATIONS} conversations with messages\n`);

        // Summary
        console.log('🎉 Mock Data Generation Complete!\n');
        console.log('📊 Summary:');
        console.log(`   • Users: ${createdUsers.length}`);
        console.log(`   • Profiles: ${createdProfiles.length}`);
        console.log(`   • Posts: ${createdPosts.length}`);
        console.log(`   • Matches: ${createdMatches.length}`);
        console.log(`   • Conversations: ${NUM_CONVERSATIONS}`);
        console.log('\n💡 Test Credentials:');
        console.log('   Email: [any generated email]');
        console.log('   Password: Test@123');
        console.log('\nExample users:');
        createdUsers.slice(0, 5).forEach(u => console.log(`   - ${u.email}`));

    } catch (error) {
        console.error('❌ Error during mock data generation:', error);
    } finally {
        await app.close();
        process.exit(0);
    }
}

bootstrap();
