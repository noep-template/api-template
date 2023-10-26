import {
  Controller,
  Body,
  Get,
  Delete,
  UseGuards,
  HttpCode,
  Patch,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateUserApi } from '@web-template/types';
import { ApiKeyGuard } from 'src/decorators/api-key.decorator';
import { ApiBearerAuth } from '@nestjs/swagger';
import { User } from './user.entity';
import { GetCurrentUser } from 'src/decorators/get-current-user.decorator';

@Controller('users')
export class UsersController {
  constructor(private service: UsersService) {}

  @Get()
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  async getAll() {
    const users = await this.service.getUsers();
    return users.map((user) => this.service.formatUser(user));
  }

  @Get('me')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  me(@GetCurrentUser() user: User) {
    return this.service.formatUser(user);
  }

  @Patch('me')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  async update(@Body() body: UpdateUserApi, @GetCurrentUser() user: User) {
    const userUpdated = await this.service.updateUser(body, user.id);
    return this.service.formatUser(userUpdated);
  }

  @Delete('me')
  @HttpCode(204)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  deleteUser(@GetCurrentUser() user: User) {
    return this.service.deleteUser(user.id);
  }
}
