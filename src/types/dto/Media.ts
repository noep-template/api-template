import { BaseDto } from './BaseDto';

export enum MediaType {
  IMAGE = 'IMAGE',
  FILE = 'FILE',
}
export interface MediaDto extends BaseDto {
  type: MediaType;
  filename: string;
  url: string;
  size: number;
}
