export interface SearchParams {
  search?: string;
  pageSize?: number;
  page?: number;
  orderBy?: string;
  orderType?: 'ASC' | 'DESC';
}

export interface ApiSearchResponse<T> {
  items: T[];
  total: number;
  page: number;
}
