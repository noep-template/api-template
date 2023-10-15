import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { UpdateUserApi, UserDto } from '@web-template/types';
import { Repository } from 'typeorm';
import { AuthService } from '../auth/auth.service';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { errorMessage } from '@web-template/errors';
import { InjectRepository } from '@nestjs/typeorm';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User) private adminRepository: Repository<User>,
    private usersService: UsersService,
    private authService: AuthService,
  ) {}

  async loadAdmin() {
    const adminBody = {
      firstName: 'admin',
      lastName: 'admin',
      email: 'admin@gmail.com',
      password: 'Azerty123!',
      isAdmin: true,
    };
    try {
      const admin = await this.adminRepository.findOne({
        where: [{ email: adminBody.email }],
      });
      if (!admin) {
        const { access_token } = await this.authService.register(adminBody);
        return access_token;
      } else {
        return admin;
      }
    } catch (error) {
      throw new BadRequestException(errorMessage.api('admin').NOT_FOUND);
    }
  }

  async toggleAdminStatus(user: User, id: string): Promise<UserDto> {
    if (user.isAdmin) {
      if (user.id === id)
        throw new BadRequestException(
          errorMessage.api('admin').CANNOT_CHANGE_OWN_STATUS,
        );
      try {
        const newAdmin = await this.usersService.getUser(id);
        const updatedUser = await this.adminRepository.update(newAdmin.id, {
          isAdmin: !newAdmin.isAdmin,
        });
        return updatedUser.raw;
      } catch (error) {
        throw new BadRequestException(errorMessage.api('admin').NOT_FOUND);
      }
    } else {
      throw new UnauthorizedException(errorMessage.api('admin').NOT_ADMIN);
    }
  }

  async getUser(user: User, id: string): Promise<UserDto> {
    if (user.isAdmin) {
      return await this.usersService.getUser(id);
    } else {
      throw new UnauthorizedException(errorMessage.api('admin').NOT_ADMIN);
    }
  }

  async updateUser(
    user: User,
    id: string,
    body: UpdateUserApi,
  ): Promise<UserDto> {
    if (user.isAdmin) {
      return await this.usersService.updateUser(body, id);
    } else {
      throw new UnauthorizedException(errorMessage.api('admin').NOT_ADMIN);
    }
  }

  async deleteUser(user: User, id: string): Promise<void> {
    if (user.isAdmin) {
      return await this.usersService.deleteUser(id);
    } else {
      throw new UnauthorizedException(errorMessage.api('admin').NOT_ADMIN);
    }
  }
}
