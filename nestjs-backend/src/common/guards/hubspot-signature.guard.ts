import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';

@Injectable()
export class HubspotSignatureGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const signature = request.headers['x-hubspot-signature'];

    if (!signature) {
      // Allow requests without signature in development
      return true;
    }

    const clientSecret = this.configService.get('hubspot.clientSecret');
    if (!clientSecret) {
      return true;
    }

    const method = request.method;
    const url = `${request.protocol}://${request.get('host')}${request.originalUrl}`;
    const rawBody = JSON.stringify(request.body);

    const sourceString = method + url + rawBody;
    const hash = createHmac('sha256', clientSecret)
      .update(sourceString)
      .digest('hex');

    if (hash !== signature) {
      throw new UnauthorizedException('Invalid HubSpot signature');
    }

    return true;
  }
}
