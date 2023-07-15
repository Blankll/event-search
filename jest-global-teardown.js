// eslint-disable-next-line @typescript-eslint/no-var-requires
const { globalTeardown } = require('@geek-fun/jest-search');
module.exports = async () => {
  await Promise.all([globalTeardown()]);
};
