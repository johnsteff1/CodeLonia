'use strict'

const { as } = require('@cuties/cutie')
const { Backend, RestApi, ServingFilesEndpoint } = require('@cuties/rest')
const { ReadDataByPath } = require('@cuties/fs')
const { ParsedJSON, Value } = require('@cuties/json')
const { Created } = require('@cuties/created')
const PGClient = require('pg').Client
const CustomNotFoundEndpoint = require('./endpoints/CustomNotFoundEndpoint')
const CustomInternalServerErrorEndpoint = require('./endpoints/CustomInternalServerErrorEndpoint')
const CustomIndexEndpoint = require('./endpoints/CustomIndexEndpoint')
const CheckPostgresConnectionEndpoint = require('./endpoints/CheckPostgresConnectionEndpoint')
const ConnectedPostgresClient = require('./async/postgresql/ConnectedPostgresClient')
const path = require('path')

const env = process.env.NODE_ENV || 'local'
const notFoundEndpoint = new CustomNotFoundEndpoint(new RegExp(/\/not-found/), './src/static/html/404.html')
const mapper = (url) => {
  return path.join('src', 'static', ...url.split('?')[0].split('/').filter(path => path !== ''))
}

new ParsedJSON(
  new ReadDataByPath(
    `./resources/${env}.json`,
    { 'encoding': 'utf8' }
  )
).as('ENV_CONFIG').after(
  new ConnectedPostgresClient(
    PGClient,
    new Value(
      as('ENV_CONFIG'),
      'postgres'
    )
  ).as('POSTGRES_CLIENT').after(
    new Backend(
      'http',
      8000,
      '0.0.0.0',
      new RestApi(
        new CustomIndexEndpoint('./src/static/html/index.html', notFoundEndpoint),
        new ServingFilesEndpoint(new RegExp(/^\/(html|css|js|images)/), mapper, {}, notFoundEndpoint),
        new Created(CheckPostgresConnectionEndpoint, new RegExp(/^\/(postgres)/), as('POSTGRES_CLIENT')),
        notFoundEndpoint,
        new CustomInternalServerErrorEndpoint(new RegExp(/^\/internal-server-error/))
      )
    )
  )
).call()
