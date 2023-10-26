import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Repository } from 'typeorm';
import { Address } from './address.entity';
import {
  AddressDto,
  CreateAddressApi,
  UpdateAddressApi,
} from '@web-template/types';
import { validationAddress } from '@web-template/validations';
import { errorMessage } from '@web-template/errors';
import { InjectRepository } from '@nestjs/typeorm';
@Injectable()
export class AddressService {
  constructor(
    @InjectRepository(Address)
    private addressRepository: Repository<Address>,
  ) {}

  formatAddress(address: Address): AddressDto {
    return {
      id: address.id,
      street: address.street,
      city: address.city,
      zipCode: address.zipCode,
      country: address.country,
    };
  }

  async createAddress(address: CreateAddressApi): Promise<AddressDto> {
    try {
      await validationAddress.create.validate(address, {
        abortEarly: false,
      });
      return await this.addressRepository.save(address);
    } catch (error) {
      throw new BadRequestException(error.errors);
    }
  }

  async updateAddress(address: UpdateAddressApi, id: string): Promise<Address> {
    try {
      await validationAddress.update.validate(address, {
        abortEarly: false,
      });
      await this.addressRepository.update(id, address);
      return await this.getAddress(id);
    } catch (error) {
      throw new BadRequestException(error.errors);
    }
  }

  async deleteAddress(id: string): Promise<void> {
    try {
      await this.addressRepository.delete(id);
    } catch (error) {
      throw new BadRequestException(errorMessage.api('address').NOT_FOUND, id);
    }
  }

  async getAddress(_id: string): Promise<Address> {
    try {
      const address = await this.addressRepository.findOneBy({
        id: _id,
      });
      return this.formatAddress(address);
    } catch (error) {
      throw new NotFoundException(errorMessage.api('address').NOT_FOUND, _id);
    }
  }
}
