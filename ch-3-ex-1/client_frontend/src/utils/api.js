const baseUri = 'http://localhost:4001'
// TODO: I think this is actually supposed to be a response header
const headers = {
  'Access-Control-Allow-Origin': 'http://localhost:4000'
}

export const getAuthorize = () => {
  const uri = `${baseUri}/authorize`

  return fetch(uri, { redirect: 'follow', headers })
}

export const getCallback = queryString => {
  const uri = `${baseUri}/callback?${queryString}`

  return fetch(uri)
}

export const getResource = () => {
  const uri = `${baseUri}/fetch_resource`

  return fetch(uri)
}