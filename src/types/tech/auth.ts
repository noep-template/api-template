import { RegisterApi } from '../api';

export interface TechRegisterApi extends RegisterApi {
  isAdmin?: boolean;
}
