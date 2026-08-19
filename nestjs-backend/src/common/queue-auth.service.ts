import { Injectable, Logger } from '@nestjs/common';

interface CachedToken {
  token: string;
  expiresAt: number;
}

@Injectable()
export class QueueAuthService {
  private readonly logger = new Logger(QueueAuthService.name);
  private cached: CachedToken | null = null;
  private inflight: Promise<string> | null = null;

  async getAccessToken(): Promise<string> {
    if (this.cached && this.cached.expiresAt - 60000 > Date.now()) {
      return this.cached.token;
    }

    if (!this.inflight) {
      this.inflight = this.login().finally(() => {
        this.inflight = null;
      });
    }
    return this.inflight;
  }

  private async login(): Promise<string> {
    const baseUrl =
      process.env.EXTERNAL_API_BASE_URL || 'https://aiep.cebralab.com';
    const username = process.env.QUEUE_AUTH_USERNAME || '';
    const password = process.env.QUEUE_AUTH_PASSWORD || '';

    const response = await fetch(`${baseUrl}/api/v1/auth/sign-in`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
      signal: AbortSignal.timeout(30000),
    });

    const data = await response.json().catch(() => null);

    if (!response.ok || !data?.access_token) {
      throw new Error(
        `Login de integración fallido: HTTP ${response.status} ${JSON.stringify(data)}`,
      );
    }

    const expiresAt = this.parseExpiry(data.access_token);
    this.cached = { token: data.access_token, expiresAt };
    this.logger.log('Token de integración obtenido/cacheado');
    return data.access_token;
  }

  private parseExpiry(token: string): number {
    try {
      const payload = token.split('.')[1];
      const decoded = JSON.parse(
        Buffer.from(payload, 'base64url').toString('utf8'),
      );
      return decoded.exp ? decoded.exp * 1000 : Date.now() + 3600 * 1000;
    } catch {
      return Date.now() + 3600 * 1000;
    }
  }
}
