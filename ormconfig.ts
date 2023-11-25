import * as dotenv from 'dotenv';
import { DataSource } from 'typeorm';
dotenv.config();

export const mysqlDataSource = new DataSource({
  name: process.env.TYPEORM_NAME,
  type: 'postgres',
  host: process.env.TYPEORM_HOST,
  port: Number(process.env.TYPEORM_PORT),
  username: process.env.TYPEORM_USERNAME,
  password: process.env.TYPEORM_PASSWORD,
  database: process.env.TYPEORM_DATABASE,
  logging: false,
  entities: ['src/**/**.entity{.ts,.js}'],
  synchronize: true,
  migrationsTableName: 'migrations',
  migrations: ['src/migrations/**/*.ts'],
});
