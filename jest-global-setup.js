// eslint-disable-next-line @typescript-eslint/no-var-requires
const esSetup = require('@shelf/jest-elasticsearch/lib/setup.js');

module.exports = async () => {
  await Promise.all([esSetup()]);
};
