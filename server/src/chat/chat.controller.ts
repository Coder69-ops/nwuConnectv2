import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { ChatService } from './chat.service';

@Controller('chat')
@UseGuards(FirebaseAuthGuard)
export class ChatController {
    constructor(private readonly chatService: ChatService) { }

    @Post('start')
    async startChat(@Req() req: any, @Body() body: { targetId: string }) {
        return this.chatService.getOrCreateConversation(req.user.uid, body.targetId);
    }

    @Post('send')
    async sendMessage(@Req() req: any, @Body() body: { targetId: string; content: string; type?: string; imageUrl?: string }) {
        return this.chatService.sendMessage(req.user.uid, body.targetId, body.content, body.type, body.imageUrl);
    }

    @Post('read/:conversationId')
    async markAsRead(@Req() req: any, @Param('conversationId') conversationId: string) {
        return this.chatService.markAsRead(conversationId, req.user.uid);
    }

    @Get('conversations')
    async getConversations(@Req() req: any) {
        return this.chatService.getConversations(req.user.uid);
    }

    @Get('messages/:conversationId')
    async getMessages(@Param('conversationId') conversationId: string) {
        return this.chatService.getMessages(conversationId);
    }
}
