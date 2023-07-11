/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: '@shelf/jest-elasticsearch',
  testEnvironment: 'node',
  testTimeout: 10 * 60 * 1000,
  testPathIgnorePatterns: ['/node_modules/', '/dist/'],
};
