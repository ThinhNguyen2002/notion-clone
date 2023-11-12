/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    domains: [
      "files.edgestore.dev"
    ]
  },
  output: 'standalone',
}

module.exports = nextConfig
