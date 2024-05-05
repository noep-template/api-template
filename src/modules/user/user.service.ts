import { errorMessage } from '@/errors';
import { SearchParams, TechRegisterApi, UpdateUserApi, UserDto } from '@/types';
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { FindManyOptions, Raw, Repository } from 'typeorm';
import { MediaService } from '../media/media.service';
import { User } from './user.entity';
import { InjectRepository } from '@nestjs/typeorm';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User) private userRepository: Repository<User>,
    private mediaService: MediaService,
  ) {}

  formatUser(user: User): UserDto {
    if (!user) return;
    return {
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName ?? undefined,
      email: user.email ?? undefined,
      updatedAt: user.updatedAt,
      createdAt: user.createdAt,
      profilePicture: this.mediaService.formatMedia(user?.profilePicture),
      isAdmin: user.isAdmin,
    };
  }

  async getUsers(searchParams: SearchParams): Promise<User[]> {
    try {
      const order = {
        [searchParams.orderBy ?? 'createdAt']: searchParams.orderType ?? 'DESC',
      };
      const conditions: FindManyOptions<User> = {
        where: {
          firstName: Raw(
            (alias) =>
              `LOWER(${alias}) Like '%${searchParams.search?.toLowerCase()}%'`,
          ),
        },
        relations: ['profilePicture'],
        order: {
          ...order,
        },
        skip: searchParams.page * searchParams.pageSize,
        take: searchParams.pageSize,
      };
      return await this.userRepository.find(conditions);
    } catch (error) {
      throw new BadRequestException(errorMessage.api('user').NOT_FOUND);
    }
  }

  async getOneById(_id: string): Promise<User> {
    try {
      const user = await this.userRepository.findOne({
        where: { id: _id },
        relations: ['profilePicture'],
      });
      return { ...user };
    } catch (error) {
      throw new NotFoundException(errorMessage.api('user').NOT_FOUND, _id);
    }
  }

  async toggleAdminStatus(id: string): Promise<User> {
    try {
      const user = await this.getOneById(id);
      await this.userRepository.update(id, {
        isAdmin: !user.isAdmin,
      });
      return await this.getOneById(id);
    } catch (error) {
      console.log(error);
      throw new BadRequestException(errorMessage.api('user').NOT_UPDATED, id);
    }
  }

  async getOneByEmail(email: string): Promise<User | null> {
    const user = await this.userRepository.findOne({
      where: [{ email }],
    });
    return user;
  }

  async createUser(body: TechRegisterApi): Promise<User> {
    try {
      return await this.userRepository.save({
        ...body,
        profilePicture: null,
      });
    } catch (error) {
      console.log(error);
      throw new BadRequestException(errorMessage.api('user').NOT_CREATED);
    }
  }

  async updateUser(body: UpdateUserApi, id: string): Promise<User> {
    try {
      const user = await this.getOneById(id);
      if (!user)
        throw new BadRequestException(errorMessage.api('user').NOT_FOUND);

      const profilePictureMedia =
        body.profilePicture &&
        (await this.mediaService.getMediaById(body.profilePicture));

      const userUpdated = await this.userRepository.save({
        ...user,
        firstName: body.firstName ?? null,
        lastName: body.lastName ?? null,
        profilePicture: profilePictureMedia ?? null,
        email: body.email ?? null,
        updatedAt: new Date(),
      });
      if (profilePictureMedia && user.profilePicture) {
        await this.mediaService.deleteMedia(user.profilePicture.id);
      }
      return userUpdated;
    } catch (error) {
      console.log(error);
      throw new BadRequestException(error);
    }
  }

  async deleteUser(id: string): Promise<void> {
    try {
      await this.userRepository.delete(id);
    } catch (error) {
      console.log(error);
      throw new BadRequestException(errorMessage.api('user').NOT_FOUND, id);
    }
  }
}
