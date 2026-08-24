import jwt from 'jsonwebtoken';

export interface JwtPayload {
  userId: string;
  email: string;
  role: string;
}

const secret = () => process.env.JWT_SECRET!;
const refreshSecret = () => process.env.JWT_REFRESH_SECRET!;

export const signAccessToken = (payload: JwtPayload): string =>
  jwt.sign(payload, secret(), { expiresIn: (process.env.JWT_EXPIRES_IN || '15m') as string } as jwt.SignOptions);

export const signRefreshToken = (payload: JwtPayload): string =>
  jwt.sign(payload, refreshSecret(), { expiresIn: (process.env.JWT_REFRESH_EXPIRES_IN || '30d') as string } as jwt.SignOptions);

export const verifyAccessToken = (token: string): JwtPayload =>
  jwt.verify(token, secret()) as JwtPayload;

export const verifyRefreshToken = (token: string): JwtPayload =>
  jwt.verify(token, refreshSecret()) as JwtPayload;
