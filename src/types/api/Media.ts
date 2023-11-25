import { MediaType } from '../dto';

export interface CreateMediaApi {
  type: MediaType;
  url: string;
  name: string;
}

export interface UpdateMediaApi {
  type?: MediaType;
  url?: string;
  name?: string;
}
