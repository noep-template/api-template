import { NestFactory } from '@nestjs/core';
import * as express from 'express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({
    origin: '*',
  });

  // Configuration des limites Express pour les gros fichiers
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));

  // Configuration des timeouts pour les uploads longs
  const server = app.getHttpServer();
  server.timeout = 300000; // 5 minutes
  server.maxConnections = 1000;

  const port = process.env.API_PORT || 8000;
  await app.listen(port);
}
bootstrap();
