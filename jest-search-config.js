module.exports = () => {
  return {
    engine: 'elasticsearch',
    version: '8.8.2',
    port: 9201,
    clusterName: 'jest-search-local',
    nodeName: 'jest-search-local',
    indexes: [
      {
        name: 'books',
        body: {
          settings: {
            number_of_shards: '1',
            number_of_replicas: '1',
          },
          mappings: {
            properties: {
              name: {
                type: 'text',
              },
              author: {
                type: 'keyword',
              },
            },
          },
        },
      },
    ],
  };
};
