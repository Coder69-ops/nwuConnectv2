
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as admin from 'firebase-admin';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  // Initialize Firebase Admin
  const serviceAccountPath = configService.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH');
  const databaseURL = configService.get<string>('FIREBASE_DATABASE_URL');

  if (serviceAccountPath) {
    const serviceAccount = require(require('path').resolve(serviceAccountPath));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: databaseURL,
    });
    console.log('Firebase Admin initialized with Service Account');
  } else {
    admin.initializeApp();
    console.log('Firebase Admin initialized with default credentials');
  }

  if (!databaseURL) {
    console.warn('Warning: FIREBASE_DATABASE_URL is not set. Realtime Database features may fail.');
  }

  const port = configService.get<number>('PORT') || 3000;

  // Enable CORS
  app.enableCors({
    origin: [
      'http://localhost:3001', // Admin Panel
      'http://localhost:3000', // Self
      'http://10.0.2.2:3000',  // Android Emulator
    ],
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  await app.listen(port, '0.0.0.0');
  console.log(`Application is running on: ${await app.getUrl()}`);
}
bootstrap();
