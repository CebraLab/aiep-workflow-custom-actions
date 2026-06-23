import { Module } from '@nestjs/common';
import { TypeOrmModule, TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService): TypeOrmModuleOptions => {
        const dbType = String(configService.get('database.type') || 'sqlite');

        if (dbType === 'postgres') {
          return {
            type: 'postgres',
            host: String(configService.get('database.host')),
            port: Number(configService.get('database.port')),
            username: String(configService.get('database.username')),
            password: String(configService.get('database.password')),
            database: String(configService.get('database.database')),
            autoLoadEntities: true,
            synchronize: true,
            retryAttempts: 10,
            retryDelay: 5000,
          } as TypeOrmModuleOptions;
        }

        if (dbType === 'mysql') {
          return {
            type: 'mysql',
            host: String(configService.get('database.host')),
            port: Number(configService.get('database.port')),
            username: String(configService.get('database.username')),
            password: String(configService.get('database.password')),
            database: String(configService.get('database.database')),
            autoLoadEntities: true,
            synchronize: true,
            retryAttempts: 10,
            retryDelay: 5000,
          } as TypeOrmModuleOptions;
        }

        return {
          type: 'better-sqlite3',
          database: 'data/hubspot_sync.sqlite',
          autoLoadEntities: true,
          synchronize: true,
        } as TypeOrmModuleOptions;
      },
    }),
  ],
})
export class DatabaseModule {}
