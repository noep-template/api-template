import * as dotenv from 'dotenv';
import { DataSource } from 'typeorm';
dotenv.config();

// Vérification des variables d'environnement essentielles
const requiredEnv = [
  'TYPEORM_NAME',
  'TYPEORM_HOST',
  'TYPEORM_PORT',
  'TYPEORM_USERNAME',
  'TYPEORM_PASSWORD',
  'TYPEORM_DATABASE',
];
requiredEnv.forEach((env) => {
  if (!process.env[env]) {
    throw new Error(`${env} is not defined`);
  }
});

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
  synchronize: process.env.NODE_ENV !== 'production',
  migrationsTableName: 'migrations',
  migrations: ['src/migrations/**/*.ts'],
});
