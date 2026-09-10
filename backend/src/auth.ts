import type { FastifyReply, FastifyRequest } from "fastify";
import type pg from "pg";
import { createLocalJWKSet, decodeProtectedHeader, errors, jwtVerify, SignJWT, type JSONWebKeySet } from "jose";
import { createHash, randomBytes } from "node:crypto";

type Database = Pick<pg.Pool, "query">;

export type VerifiedAppleIdentity = {
  subject: string;
  email?: string;
  sessionVersion?: number;
  sessionId?: string;
};

export type AuthenticatedUser = {
  id: string;
  appleSubject: string;
};

export interface AppleTokenVerifier {
  verify(identityToken: string): Promise<VerifiedAppleIdentity>;
}

export type JWKSFetcher = () => Promise<JSONWebKeySet>;

export class ProductionAppleTokenVerifier implements AppleTokenVerifier {
  private cached?: { jwks: JSONWebKeySet; expiresAt: number };
  constructor(
    private readonly clientIds: readonly string[],
    private readonly fetchJWKS: JWKSFetcher = async () => {
      const response = await fetch("https://appleid.apple.com/auth/keys");
      if (!response.ok) throw new InvalidAppleTokenError("Apple JWKS unavailable");
      return await response.json() as JSONWebKeySet;
    },
    private readonly ttlMs = 60 * 60 * 1000,
    private readonly now = () => Date.now()
  ) {
    if (clientIds.length === 0) throw new Error("At least one APPLE_CLIENT_ID is required");
  }

  async verify(identityToken: string): Promise<VerifiedAppleIdentity> {
    try {
      const header = decodeProtectedHeader(identityToken);
      if (header.alg !== "RS256" || !header.kid) throw new InvalidAppleTokenError("Unsupported Apple token header");
      let jwks = await this.keys(false);
      if (!jwks.keys.some(key => key.kid === header.kid)) jwks = await this.keys(true);
      if (!jwks.keys.some(key => key.kid === header.kid)) throw new InvalidAppleTokenError("Unknown Apple signing key");
      const { payload } = await jwtVerify(identityToken, createLocalJWKSet(jwks), {
        algorithms: ["RS256"], issuer: "https://appleid.apple.com", audience: [...this.clientIds], clockTolerance: 5
      });
      if (!payload.sub || typeof payload.iat !== "number" || payload.iat > Math.floor(this.now() / 1000) + 5) throw new InvalidAppleTokenError("Missing or invalid Apple claims");
      return { subject: payload.sub, email: typeof payload.email === "string" ? payload.email : undefined };
    } catch (error) {
      if (error instanceof InvalidAppleTokenError) throw error;
      if (error instanceof errors.JOSEError || error instanceof TypeError) throw new InvalidAppleTokenError("Invalid Apple identity token");
      throw error;
    }
  }

  private async keys(force: boolean): Promise<JSONWebKeySet> {
    if (!force && this.cached && this.cached.expiresAt > this.now()) return this.cached.jwks;
    const jwks = await this.fetchJWKS();
    if (!Array.isArray(jwks.keys)) throw new InvalidAppleTokenError("Malformed Apple JWKS");
    this.cached = { jwks, expiresAt: this.now() + this.ttlMs };
    return jwks;
  }
}

export class SessionTokenService implements AppleTokenVerifier {
  private readonly secret: Uint8Array;
  constructor(secret: string, private readonly lifetimeSeconds = 15 * 60) {
    if (Buffer.byteLength(secret) < 32) throw new Error("SESSION_TOKEN_SECRET must be at least 32 bytes");
    this.secret = new TextEncoder().encode(secret);
  }
  async issue(identity: VerifiedAppleIdentity): Promise<{ accessToken: string; expiresIn: number }> {
    const accessToken = await new SignJWT({ typ: "access", sessionVersion: identity.sessionVersion ?? 1, sid: identity.sessionId }).setProtectedHeader({ alg: "HS256" }).setSubject(identity.subject)
      .setIssuer("hookahboss-api").setAudience("hookahboss-app").setIssuedAt().setExpirationTime(`${this.lifetimeSeconds}s`).sign(this.secret);
    return { accessToken, expiresIn: this.lifetimeSeconds };
  }
  async verify(token: string): Promise<VerifiedAppleIdentity> {
    try {
      const { payload } = await jwtVerify(token, this.secret, { algorithms: ["HS256"], issuer: "hookahboss-api", audience: "hookahboss-app" });
      if (!payload.sub || payload.typ !== "access") throw new InvalidAppleTokenError("Invalid session claims");
      if (!Number.isInteger(payload.sessionVersion)) throw new InvalidAppleTokenError("Invalid session version");
      return { subject: payload.sub, sessionVersion: Number(payload.sessionVersion), sessionId: typeof payload.sid === "string" ? payload.sid : undefined };
    } catch (error) {
      if (error instanceof InvalidAppleTokenError) throw error;
      throw new InvalidAppleTokenError("Invalid session token");
    }
  }
}

export function newRefreshToken(): string { return randomBytes(32).toString("base64url"); }
export function hashRefreshToken(token: string): string { return createHash("sha256").update(token).digest("hex"); }

export interface AdminAuthorizationPolicy {
  allows(user: AuthenticatedUser): boolean | Promise<boolean>;
}

export class AppleSubjectAllowlist implements AdminAuthorizationPolicy {
  private readonly subjects: Set<string>;

  constructor(subjects: Iterable<string>) {
    this.subjects = new Set([...subjects].map(value => value.trim()).filter(Boolean));
  }

  allows(user: AuthenticatedUser): boolean {
    return this.subjects.has(user.appleSubject);
  }
}

export const denyAllAdmins: AdminAuthorizationPolicy = { allows: () => false };

export class InvalidAppleTokenError extends Error {}

export const unavailableAppleTokenVerifier: AppleTokenVerifier = {
  async verify() {
    throw new InvalidAppleTokenError("Apple token verification is not configured");
  }
};

export function createAuthenticator(database: Database, verifier: AppleTokenVerifier) {
  return async (request: FastifyRequest, reply: FastifyReply): Promise<AuthenticatedUser | null> => {
    const authorization = request.headers.authorization;
    if (!authorization?.startsWith("Bearer ") || authorization.length <= 7) {
      reply.code(401).send({ error: "unauthorized" });
      return null;
    }

    try {
      const identity = await verifier.verify(authorization.slice(7));
      if (!identity.subject) throw new InvalidAppleTokenError("Apple subject is empty");

      const result = identity.sessionVersion === undefined ? await database.query<{ id: string; apple_subject: string }>(
        `INSERT INTO app_users (apple_subject, email)
         VALUES ($1, $2)
         ON CONFLICT (apple_subject) DO UPDATE
           SET email = COALESCE(app_users.email, EXCLUDED.email), updated_at = now()
         RETURNING id, apple_subject`,
        [identity.subject, identity.email ?? null]
      ) : await database.query<{ id: string; apple_subject: string }>(
        `SELECT u.id, u.apple_subject FROM app_users u JOIN auth_sessions s ON s.user_id=u.id
          WHERE u.apple_subject=$1 AND u.auth_session_version=$2 AND s.id=$3 AND s.revoked_at IS NULL AND s.expires_at>now()`,
        [identity.subject, identity.sessionVersion, identity.sessionId]
      );
      const row = result.rows[0];
      if (!row) throw new InvalidAppleTokenError("Session is no longer valid");
      return { id: row.id, appleSubject: row.apple_subject };
    } catch (error) {
      if (error instanceof InvalidAppleTokenError) {
        reply.code(401).send({ error: "unauthorized" });
        return null;
      }
      throw error;
    }
  };
}
