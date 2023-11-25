# api-template

Template pour créer une API REST avec Node.js, TypeORM et Postgres.

## Installation

1. Cloner le dépôt
2. Installer les dépendances avec `npm install` ou `yarn install`
3. Toutes les commandes sont disponibles avec `make help`

## Architecture

- `src` : code source
  - `decorators` : décorateurs pour les contrôleurs
  - `errors` : gestionnaire des erreurs pour le front
  - `migrations` : migrations de la base de données
  - `modules` :
    - `nom-du-module` : module
      - `entity` : entités du module
      - `controller` : contrôleurs du module
      - `repositorie` : répertoires du module
      - `service` : services du module
  - `types` : types
    - `api`: Ce que l'API reçoit
    - `dto`: Ce que l'API renvoie
  - `validations` : validation des données avec yup

## Utilisation

### Lancer le projet

1. Créer un .env à partir du .env.example (Modifier les variables d'environnement si besoin)
2. Faire correspondre les variables d'environnement avec le docker-compose.yml
3. Lancer un docker et faire cette commande : `make db.create`
   Cette commande va créer la base de données, et faire les migrations.
4. Lancer le docker avec `make db.start`
5. Lancer le projet avec `make start`
6. Si tous fonctionne, vous pouvez accéder à l'API à l'adresse [http://localhost:8000](http://localhost:8000). Vous devrez voir écrit `Hello World!`

### Tester l'API (register et login)

1. Lancer le projet
2. Ouvrer un Postman
3. Créer une méthode POST avec l'URL [http://localhost:8000/auth/register](http://localhost:8000/auth/register)
4. Dans le Header, dans `KEY`, mettre `x-api-key` et dans `VALUE`, mettre votre clef d'API présenter dans le .env
5. Dans le Body, sélectionner `raw` et `JSON`, puis mettre ceci :

```json
{
  "email": "john@gmail.com",
  "password": "Azerty123!",
  "lastName": "Doe",
  "firstName": "John"
}
```

6. Envoyer la requête (Cette requête va créer un utilisateur et le logger)
7. Copier le token dans la réponse
8. Ouvrir une nouvelle fenêtre Postman avec un GET sur [http://localhost:8000/users/me](http://localhost:8000/users/me)
9. Dans Authorization, sélectionner `Bearer Token` et coller le token copier précédemment
10. Envoyer la requête (Cette requête va récupérer les informations de l'utilisateur connecté)
11. Pour mettre à jour l'utilisateur, faire un PATCH sur [http://localhost:8000/users/me](http://localhost:8000/users/me) avec le même token et dans le body :

```json
{
  "lastName": "Doe2"
}
```

La requête va mettre à jour le nom de famille de l'utilisateur et renvoyer les informations de l'utilisateur 12. Pour supprimer l'utilisateur, faire un DELETE sur [http://localhost:8000/users/me](http://localhost:8000/users/me) avec le même token 13. Vous pouvez également créer un admin par défaut une fois que vous êtes connecté avec un GET sur [http://localhost:8000/admin/create-default-admin](http://localhost:8000/admin/create-default-admin)

### Créer un module

Nous allons faire un cas pratique en ajoutant un module Address.

1. Creéer un nouveau module avec cette commande : `make module.create` et entrer `address`
2. Cette commande va créer un nouveau module avec les fichiers de base.
3. Dans le fichier `src/modules/address/address.entity.ts`, ajouter les propriétés suivantes :

```typescript
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ default: '' })
  street: string;

  @Column({ default: '' })
  city: string;

  @Column({ default: '' })
  zipCode: string;

  @Column({ default: '' })
  country: string;
```

4. Dans le fichier `@/types/api/Address.ts` ajouter les propriétés suivantes :

```typescript
export interface CreateAddressApi {
  street: string;
  city: string;
  zipCode: string;
  country: string;
}

export interface UpdateAddressApi {
  street?: string;
  city?: string;
  zipCode?: string;
  country?: string;
}
```

5.  Dans le fichier `@/types/dto/Address.ts` ajouter les propriétés suivantes :

```typescript
export interface AddressDto {
  id: string;
  street: string;
  city: string;
  zipCode: string;
  country: string;
}
```

6. Le fichier `@/errors/errors.ts` permet de gérer les erreurs pour le front, ajouter les propriétés suivantes :

```typescript
export enum AddressError {
  ADDRESS_NOT_FOUND = 'ADDRESS_NOT_FOUND',
  STREET_REQUIRED = 'STREET_REQUIRED',
  CITY_REQUIRED = 'CITY_REQUIRED',
  COUNTRY_REQUIRED = 'COUNTRY_REQUIRED',
  ZIPCODE_REQUIRED = 'ZIPCODE_REQUIRED',
  STREET_NOT_STRING = 'STREET_NOT_STRING',
  CITY_NOT_STRING = 'CITY_NOT_STRING',
  COUNTRY_NOT_STRING = 'COUNTRY_NOT_STRING',
  ZIPCODE_NOT_STRING = 'ZIPCODE_NOT_STRING',
}
```

1. Le fichier `@/validations/address.ts` permet de gérer toutes les validations, ajouter les propriétés suivantes :

```typescript
import { AddressError } from '@/errors/errors';
import { CreateAddressApi, UpdateAddressApi } from '@/types';
import * as yup from 'yup';

const create = yup.object<CreateAddressApi>().shape({
  street: yup
    .string()
    .required(AddressError.STREET_REQUIRED)
    .typeError(AddressError.STREET_NOT_STRING),
  city: yup
    .string()
    .required(AddressError.CITY_REQUIRED)
    .typeError(AddressError.CITY_NOT_STRING),
  zipCode: yup
    .string()
    .required(AddressError.ZIPCODE_REQUIRED)
    .typeError(AddressError.ZIPCODE_NOT_STRING),
  country: yup
    .string()
    .required(AddressError.COUNTRY_REQUIRED)
    .typeError(AddressError.COUNTRY_NOT_STRING),
});

const update = yup.object<UpdateAddressApi>().shape({
  street: yup.string().typeError(AddressError.STREET_NOT_STRING),
  city: yup.string().typeError(AddressError.CITY_NOT_STRING),
  zipCode: yup.string().typeError(AddressError.ZIPCODE_NOT_STRING),
  country: yup.string().typeError(AddressError.COUNTRY_NOT_STRING),
});

export const validationAddress = {
  create: create,
  update: update,
};
```

8. Dans le fichier `src/modules/address/address.module.ts` :

- Si vous voulez la les routes soient accessibles uniquement aux utilisateurs connectés, ajouter ces imports :

```typescript
   imports: [TypeOrmModule.forFeature([Address]), UsersModule, forwardRef(() => AuthModule)],
```

et ajouter ce code dans AddressModule :

```typescript
  public configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .forRoutes(
        { path: '/address', method: RequestMethod.ALL },
        { path: '/address/*', method: RequestMethod.ALL },
      );
  }
```

9. Le fichier `src/modules/address/address.service.ts` permet de gérer toutes les actions, ajouter les propriétés suivantes :

```typescript
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Repository } from 'typeorm';
import { Address } from './address.entity';
import {
  AddressDto,
  CreateAddressApi,
  UpdateAddressApi,
} from '@/types';
import { AddressError, GenericsError } from '@/errors/errors';
import { validationAddress } from '@/validations';
import { InjectRepository } from '@nestjs/typeorm';

@Injectable()
export class AddressService {
  constructor(
    @InjectRepository(Address)
    private addressRepository: Repository<Address>,
  ) {}

  async createAddress(address: CreateAddressApi): Promise<AddressDto> {
    try {
      await validationAddress.create.validate(address);
      return await this.addressRepository.save(address);
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async updateAddress(
    address: UpdateAddressApi,
    id: string,
  ): Promise<AddressDto> {
    try {
      await validationAddress.update.validate(address);
      await this.addressRepository.update(id, address);
      return await this.getAddress(id);
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async deleteAddress(id: string): Promise<void> {
    try {
      await this.addressRepository.delete(id);
    } catch (error) {
      throw new BadRequestException(GenericsError.INTERNAL_SERVER_ERROR);
    }
  }

  async getAddress(_id: string): Promise<AddressDto> {
    try {
      const address = await this.addressRepository.findOne({
        select: ['id', 'street', 'city', 'zipCode', 'country'],
        where: [{ id: _id }],
      });
      return address;
    } catch (error) {
      throw new NotFoundException(AddressError.ADDRESS_NOT_FOUND);
    }
  }
}
```

10. Le fichier `src/modules/address/address.controller.ts` permet de gérer les routes, ajouter les propriétés suivantes :

```typescript
import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth } from '@nestjs/swagger';
import { ApiKeyGuard } from 'src/decorators/api-key.decorator';
import { AddressService } from './address.service';
import { CreateAddressApi } from '@/types';

@Controller('address')
export class AddressController {
  constructor(private service: AddressService) {}

  @Get(':id')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  get(@Param() params) {
    return this.service.getAddress(params.id);
  }

  @Post()
  @HttpCode(201)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  create(@Body() body: CreateAddressApi) {
    return this.service.createAddress(body);
  }

  @Patch(':id')
  @HttpCode(200)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  update(@Body() body: CreateAddressApi, @Param() params) {
    return this.service.updateAddress(body, params.id);
  }

  @Delete(':id')
  @HttpCode(204)
  @UseGuards(ApiKeyGuard)
  @ApiBearerAuth()
  delete(@Param() params) {
    return this.service.deleteAddress(params.id);
  }
}
```

11. Maintenant que le module est créé, il faut l'ajouter à l'entity `User` :

- Dans le fichier `src/modules/users/user.entity.ts`, ajouter la propriété suivante :

```typescript
@OneToOne(() => Address, { cascade: true, eager: true, nullable: true })
@JoinColumn()
address: Address;
```

- Nous allons mettre à jours les types de l'entity, dans le fichier `@/types/api/Auth.ts`, `@/types/api/User.ts` et `@/types/dto/User.ts`, ajouter la propriété suivante :

```typescript
address?: CreateAddressApi; // ou UpdateAddressApi ou AddressDto
```

12. Nous allons mettre à jour le service `UserService` pour ajouter l'adresse à l'utilisateur :

- Dans le `getUser` et `getUsers`, ajouter `address` dans le `select`
- Ajouter `private addressService: AddressService,` dans le constructor
- Mettre à jour le `createUser` :

```typescript
  async createUser(user: AuthRegisterApi): Promise<UserDto> {
    const addressesCreated = user.address
      ? await this.addressService.createAddress(user.address)
      : null;
    try {
      return await this.usersRepository.save({
        ...user,
        address: addressesCreated,
      });
    } catch (error) {
      throw new BadRequestException(GenericsError.INTERNAL_SERVER_ERROR);
    }
  }
```

- Mettre à jour le `updateUser` :

```typescript
  async updateUser(body: UpdateUserApi, id: string): Promise<UserDto> {
    try {
      await validationUser.update.validate(body);
      const user = await this.getUser(id);
      const addressUpdated =
        user.address !== null
          ? await this.addressService.updateAddress(
              body.address ?? user.address,
              user.address.id,
            )
          : await this.addressService.createAddress(
              body.address as CreateAddressApi,
            );
      await this.usersRepository.update(id, {
        ...body,
        address: addressUpdated,
      });
      return await this.getUser(id);
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }
```

- Mettre à jour le `deleteUser` :

```typescript
   async deleteUser(id: string): Promise<void> {
    try {
      const user = await this.getUser(id);
      await this.addressService.deleteAddress(user.address.id);
      await this.usersRepository.delete(user.id);
    } catch (error) {
      throw new BadRequestException(GenericsError.INTERNAL_SERVER_ERROR);
    }
  }
```

13. Nous allons mettre à jours les modules :

- Dans le fichier `address.module.ts`, ajouter `forwardRef(() => UsersModule)` dans les imports et `AddressService` dans les exports
- Dans le fichier `users.module.ts`, ajouter `forwardRef(() => AddressModule)` dans les imports

14. Vous pouvez supprimer `address.controller.ts`, il n'est plus utilisé
15. Mettre à jour les migrations : `make migration` avec comme nom `add-address-to-user`
16. Vous pouvez maintenant tester l'API avec Postman avec un POST sur [http://localhost:8000/users/register](http://localhost:8000/users/register) avec le body suivant :

```json
{
  "email": "john13@gmail.com",
  "password": "Azerty123!",
  "lastName": "Doe",
  "firstName": "John",
  "address": {
    "street": "4 rue des lilas",
    "city": "Rennes",
    "zipCode": "35000",
    "country": "France"
  }
}
```
