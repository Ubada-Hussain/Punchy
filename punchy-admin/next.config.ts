import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${process.env.BACKEND_URL || "http://129.154.252.220"}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;
