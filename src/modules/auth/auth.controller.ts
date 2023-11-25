import { errorMessage } from '@/errors';
import { AuthLoginApi, RegisterApi } from '@/types';
import { userValidation } from '@/validations';
import {
  BadRequestException,
  Body,
  Controller,
  HttpCode,
  Inject,
  Post,
  UseGuards,
  forwardRef,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ApiKeyGuard } from '../../decorators/api-key.decorator';
import { UserService } from '../user/user.service';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(
    @Inject(forwardRef(() => AuthService))
    private authService: AuthService,
    private jwtService: JwtService,
    private readonly userService: UserService,
  ) {}

  @Post('login')
  @UseGuards(ApiKeyGuard)
  @HttpCode(200)
  async login(@Body() body: AuthLoginApi) {
    try {
      await userValidation.login.validate(body, {
        abortEarly: false,
      });
      return await this.authService.login(body);
    } catch (e) {
      throw new BadRequestException(e);
    }
  }

  @Post('login/admin')
  @UseGuards(ApiKeyGuard)
  @HttpCode(200)
  async loginAdmin(@Body() body: AuthLoginApi) {
    try {
      await userValidation.login.validate(body, {
        abortEarly: false,
      });
      const user = await this.userService.getOneByEmail(body.email);
      if (!user.isAdmin)
        throw new BadRequestException(errorMessage.api('user').NOT_ADMIN);
      return await this.authService.login(body);
    } catch (e) {
      throw new BadRequestException(e);
    }
  }

  @Post('register')
  @UseGuards(ApiKeyGuard)
  @HttpCode(200)
  async register(@Body() body: RegisterApi) {
    try {
      await userValidation.create.validate(body, {
        abortEarly: false,
      });
      const { access_token } = await this.authService.register(body);
      return access_token;
    } catch (e) {
      throw new BadRequestException(e);
    }
  }
}
