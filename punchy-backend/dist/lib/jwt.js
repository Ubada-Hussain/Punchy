"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyRefreshToken = exports.verifyAccessToken = exports.signRefreshToken = exports.signAccessToken = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const secret = () => process.env.JWT_SECRET;
const refreshSecret = () => process.env.JWT_REFRESH_SECRET;
const signAccessToken = (payload) => jsonwebtoken_1.default.sign(payload, secret(), { expiresIn: (process.env.JWT_EXPIRES_IN || '15m') });
exports.signAccessToken = signAccessToken;
const signRefreshToken = (payload) => jsonwebtoken_1.default.sign(payload, refreshSecret(), { expiresIn: (process.env.JWT_REFRESH_EXPIRES_IN || '30d') });
exports.signRefreshToken = signRefreshToken;
const verifyAccessToken = (token) => jsonwebtoken_1.default.verify(token, secret());
exports.verifyAccessToken = verifyAccessToken;
const verifyRefreshToken = (token) => jsonwebtoken_1.default.verify(token, refreshSecret());
exports.verifyRefreshToken = verifyRefreshToken;
//# sourceMappingURL=jwt.js.map