import { MediaService } from './../media/media.service';
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AuthRegisterApi,
  CreateAddressApi,
  UpdateUserApi,
  UserDto,
} from '@web-template/types';
import { Repository } from 'typeorm';
import { AddressService } from '../address/address.service';
import { User } from './user.entity';
import { validationUser } from '@web-template/validations';
import { errorMessage } from '@web-template/errors';
import { InjectRepository } from '@nestjs/typeorm';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private usersRepository: Repository<User>,
    private addressService: AddressService,
    private mediaService: MediaService,
  ) {}

  formatUser(user: User): UserDto {
    return {
      id: user.id,
      lastName: user.lastName,
      firstName: user.firstName,
      email: user.email,
      isAdmin: user.isAdmin,
      address: user.address,
      profilePicture: user.profilePicture,
    };
  }

  async getUsers(): Promise<User[]> {
    try {
      return await this.usersRepository.find();
    } catch (error) {
      throw new BadRequestException(errorMessage.api('user').NOT_FOUND);
    }
  }

  async getUser(_id: string): Promise<User> {
    try {
      return await this.usersRepository.findOneBy({ id: _id });
    } catch (error) {
      throw new NotFoundException(errorMessage.api('user').NOT_FOUND, _id);
    }
  }

  async findOneByEmail(email: string): Promise<User | null> {
    try {
      const user = await this.usersRepository.findOne({
        where: [{ email }],
      });
      return user;
    } catch (error) {
      throw new NotFoundException(errorMessage.api('user').NOT_FOUND, email);
    }
  }

  async createUser(body: AuthRegisterApi): Promise<User> {
    const addressesCreated = body.address
      ? await this.addressService.createAddress(body.address)
      : null;
    try {
      return await this.usersRepository.save({
        ...body,
        address: addressesCreated,
        profilePicture: null,
      });
    } catch (error) {
      throw new BadRequestException(errorMessage.api('user').NOT_CREATED);
    }
  }

  async updateUser(body: UpdateUserApi, id: string): Promise<User> {
    try {
      await validationUser.update.validate(body, {
        abortEarly: false,
      });
    } catch (e) {
      throw new BadRequestException(e.errors);
    }
    try {
      const user = await this.getUser(id);
      let addressUpdated = null;
      if (body.address) {
        addressUpdated =
          user.address !== null
            ? await this.addressService.updateAddress(
                body.address ?? user.address,
                user.address.id,
              )
            : await this.addressService.createAddress(
                body.address as CreateAddressApi,
              );
      }
      const profilePictureMedia =
        body.profilePicture &&
        (await this.mediaService.getMediaById(body.profilePicture));

      await this.usersRepository.update(id, {
        ...user,
        email: body.email ?? user.email,
        lastName: body.lastName ?? user.lastName,
        firstName: body.firstName ?? user.firstName,
        address: addressUpdated ?? user.address,
        profilePicture: profilePictureMedia ?? user.profilePicture,
      });

      if (profilePictureMedia) {
        await this.mediaService.deleteMedia(user.profilePicture.id);
      }
      return await this.getUser(id);
    } catch (error) {
      throw new BadRequestException(errorMessage.api('user').NOT_UPDATED, id);
    }
  }

  async deleteUser(id: string): Promise<void> {
    try {
      const user = await this.getUser(id);
      await this.addressService.deleteAddress(user.address.id);
      await this.usersRepository.delete(user.id);
    } catch (error) {
      throw new BadRequestException(errorMessage.api('user').NOT_FOUND, id);
    }
  }
}
