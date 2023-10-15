import { Injectable, NotFoundException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import * as bcrypt from 'bcryptjs';
import { errorMessage } from '@web-template/errors';

@Injectable()
export class AuthValidation {
  constructor(private userRepository: UsersService) {}

  async validateUser(email: string, password: string): Promise<any> {
    const user = await this.userRepository.findOneByEmail(email);
    if (user && (await this.comparePassword(user.password, password))) {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { password: __password, ...result } = user;
      return result;
    }
    throw new NotFoundException(
      errorMessage.api('user').NOT_FOUND_OR_WRONG_PASSWORD,
    );
  }

  async comparePassword(
    encryptedPassword: string,
    password: string,
  ): Promise<boolean> {
    return await bcrypt.compare(password, encryptedPassword);
  }
}
