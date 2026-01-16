
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class R2Service {
    private s3Client: S3Client;
    private bucketName: string;

    constructor(private configService: ConfigService) {
        this.bucketName = this.configService.get<string>('R2_BUCKET_NAME')!;

        this.s3Client = new S3Client({
            region: 'auto',
            endpoint: `https://${this.configService.get<string>('R2_ACCOUNT_ID')}.r2.cloudflarestorage.com`,
            credentials: {
                accessKeyId: this.configService.get<string>('R2_ACCESS_KEY_ID')!,
                secretAccessKey: this.configService.get<string>('R2_SECRET_ACCESS_KEY')!,
            },
        });
    }

    async generatePresignedUrl(mimeType: string, folder: 'profiles' | 'chat' = 'profiles'): Promise<{ uploadUrl: string; publicUrl: string; key: string }> {
        const ext = mimeType.split('/')[1];
        const key = `${folder}/${uuidv4()}.${ext}`;

        const command = new PutObjectCommand({
            Bucket: this.bucketName,
            Key: key,
            ContentType: mimeType,
        });

        // Expires in 15 minutes
        const uploadUrl = await getSignedUrl(this.s3Client, command, { expiresIn: 900 });

        // Assuming a public custom domain is set up or using the R2 dev URL
        // For now, using the public domain var or falling back to constructed URL if needed
        const publicDomain = this.configService.get<string>('R2_PUBLIC_DOMAIN');
        const publicUrl = `${publicDomain}/${key}`;

        return { uploadUrl, publicUrl, key };
    }
}
