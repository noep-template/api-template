import { errorMessage } from '@/errors';
import { UpdateUserApi, UserDto } from '@/types';
import { userValidation } from '@/validations';
import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Inject,
  Param,
  Patch,
  UseGuards,
  forwardRef,
} from '@nestjs/common';
import { ApiBearerAuth } from '@nestjs/swagger';
import { ApiKeyGuard } from 'src/decorators/api-key.decorator';
import { GetCurrentUser } from 'src/decorators/get-current-user.decorator';
import { User } from './user.entity';
import { UserService } from './user.service';

@Controller('users')
export class UserController {
  constructor(
    @Inject(forwardRef(() => UserService))
    private service: UserService,
  ) {}

  @Get('me')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  async me(@GetCurrentUser() user: User): Promise<UserDto> {
    const formattedUser = this.service.formatUser(user);
    if (!formattedUser) {
      throw new BadRequestException(errorMessage.api('user').NOT_FOUND);
    }
    return formattedUser;
  }

  @Patch('me')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  async update(@Body() body: UpdateUserApi, @GetCurrentUser() user: User): Promise<UserDto> {
    try {
      await userValidation.update.validate(body, {
        abortEarly: false,
      });
      const userUpdated = await this.service.updateUser(body, user.id);
      const formattedUser = this.service.formatUser(userUpdated);
      if (!formattedUser) {
        throw new BadRequestException(errorMessage.api('user').NOT_FOUND);
      }
      return formattedUser;
    } catch (e) {
      if (e && typeof e === 'object' && 'errors' in e) {
        throw new BadRequestException((e as any).errors);
      }
      throw new BadRequestException(e);
    }
  }

  @Delete('me')
  @HttpCode(204)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  deleteUser(@GetCurrentUser() user: User): void {
    this.service.deleteUser(user.id);
  }

  @Delete(':id')
  @HttpCode(204)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  async deleteUserById(@GetCurrentUser() user: User, @Param('id') id: string): Promise<void> {
    try {
      const possibleUser = await this.service.getOneById(id);
      if (!possibleUser) throw new BadRequestException(errorMessage.api('user').NOT_FOUND);
      this.service.deleteUser(id);
    } catch (e) {
      throw new BadRequestException(e);
    }
  }

  @Patch(':id')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  async updateUserById(
    @GetCurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: UpdateUserApi,
  ): Promise<UserDto> {
    try {
      await userValidation.update.validate(body, {
        abortEarly: false,
      });
      const userUpdated = await this.service.updateUser(body, id);
      const formattedUser = this.service.formatUser(userUpdated);
      if (!formattedUser) {
        throw new BadRequestException(errorMessage.api('user').NOT_FOUND);
      }
      return formattedUser;
    } catch (e) {
      console.log(e);
      if (e && typeof e === 'object' && 'errors' in e) {
        throw new BadRequestException((e as any).errors);
      }
      throw new BadRequestException(e);
    }
  }
}
