import * as mongoose from 'mongoose';
import * as dotenv from 'dotenv';
import { resolve } from 'path';

// Load env from server root
dotenv.config({ path: resolve(__dirname, '../.env') });

const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
    console.error('❌ MONGO_URI not found in .env');
    process.exit(1);
}

const userSchema = new mongoose.Schema({
    email: String,
    status: String,
    role: String
});

const User = mongoose.model('User', userSchema);

async function promoteUser(email: string) {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(MONGO_URI!);

        console.log(`🔍 Looking for user: ${email}`);
        const user = await User.findOne({ email });

        if (!user) {
            console.error(`❌ User not found! Please sign up in the app first with email: ${email}`);
            process.exit(1);
        }

        console.log(`✅ User found. Current Status: ${user.status}, Role: ${user.role}`);

        user.status = 'admin'; // For gatekeeper logic
        user.role = 'admin';   // For role-based guards
        await user.save();

        console.log(`🎉 SUCCESS! ${email} is now an ADMIN.`);
    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await mongoose.disconnect();
    }
}

const emailArg = process.argv[2];

if (!emailArg) {
    console.log('Example usage: ts-node scripts/set-admin.ts user@example.com');
    process.exit(0);
}

promoteUser(emailArg);
