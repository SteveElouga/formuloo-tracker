// Mode mock (FT-6b) : l'app tourne sans backend via MSW + fixtures.
export const environment = {
  production: false,
  apiMode: 'mock' as 'live' | 'mock',
  graphqlUrl: '/graphql'
};
