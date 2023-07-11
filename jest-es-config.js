module.exports = () => {
  return {
    esVersion: '8.4.0', // ! must be exact version. Ref: https://github.com/elastic/elasticsearch-js .
    // don't be shy to fork our code and update deps to correct.
    clusterName: 'event-es-8-cluster',
    nodeName: 'event-es-8-node',
    port: 9201,
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
