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
  ) {}

  async getUsers(): Promise<UserDto[]> {
    try {
      return await this.usersRepository.find({
        select: ['id', 'lastName', 'firstName', 'email', 'isAdmin', 'address'],
      });
    } catch (error) {
      throw new BadRequestException(errorMessage.api('user').NOT_FOUND);
    }
  }

  async getUser(_id: string): Promise<UserDto> {
    try {
      const user = await this.usersRepository.findOne({
        select: ['id', 'lastName', 'firstName', 'email', 'isAdmin', 'address'],
        where: [{ id: _id }],
      });
      return user;
    } catch (error) {
      throw new NotFoundException(errorMessage.api('user').NOT_FOUND, _id);
    }
  }

  async me(user: User): Promise<User> {
    return user;
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

  async createUser(body: AuthRegisterApi): Promise<UserDto> {
    const addressesCreated = body.address
      ? await this.addressService.createAddress(body.address)
      : null;
    try {
      return await this.usersRepository.save({
        ...body,
        address: addressesCreated,
      });
    } catch (error) {
      throw new BadRequestException(errorMessage.api('user').NOT_CREATED);
    }
  }

  async updateUser(body: UpdateUserApi, id: string): Promise<UserDto> {
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
      await this.usersRepository.update(id, {
        ...body,
        address: addressUpdated,
      });
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
