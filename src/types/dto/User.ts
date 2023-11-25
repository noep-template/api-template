import { BaseDto } from './BaseDto';
import { MediaDto } from './Media';

export interface UserDto extends BaseDto {
  firstName: string;
  email?: string;
  lastName?: string;
  profilePicture?: MediaDto;
  isAdmin: boolean;
}
