import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { ApiKeyGuard } from 'src/decorators/api-key.decorator';
import { ApiBearerAuth } from '@nestjs/swagger';
import { GetCurrentUser } from 'src/decorators/get-current-user.decorator';
import { User } from '../users/user.entity';

@Controller('admin')
export class AdminController {
  constructor(private service: AdminService) {}

  @Get('create-default-admin')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  loadAdmin() {
    return this.service.loadAdmin();
  }

  @Get('users/:id/toggle-admin-status')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  createAdmin(@GetCurrentUser() user: User, @Param() params) {
    return this.service.toggleAdminStatus(user, params.id);
  }

  @Get('users/:id')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  getUser(@GetCurrentUser() user: User, @Param() params) {
    return this.service.getUser(user, params.id);
  }

  @Patch('users/:id')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  updateUser(@GetCurrentUser() user: User, @Param() params, @Body() body) {
    return this.service.updateUser(user, params.id, body);
  }

  @Delete('users/:id')
  @HttpCode(204)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  deleteUser(@GetCurrentUser() user: User, @Param() params) {
    return this.service.deleteUser(user, params.id);
  }
}
