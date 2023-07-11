// eslint-disable-next-line @typescript-eslint/no-var-requires
const esTeardown = require('@shelf/jest-elasticsearch/lib/teardown.js');

module.exports = async () => {
  await Promise.all([esTeardown()]);
};
