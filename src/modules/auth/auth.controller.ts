import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { ApiKeyGuard } from '../../decorators/api-key.decorator';
import { AuthLoginApi, AuthRegisterApi } from '@web-template/types';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  @UseGuards(ApiKeyGuard)
  @HttpCode(200)
  async login(@Body() body: AuthLoginApi) {
    return await this.authService.login(body);
  }

  @Post('register')
  @UseGuards(ApiKeyGuard)
  @HttpCode(200)
  async register(@Body() body: AuthRegisterApi) {
    const { access_token } = await this.authService.register(body);
    return access_token;
  }
}
