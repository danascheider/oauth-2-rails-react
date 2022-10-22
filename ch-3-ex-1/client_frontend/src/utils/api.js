const baseUri = 'http://localhost:4001'
// TODO: I think this is actually supposed to be a response header
const headers = {
  'Access-Control-Allow-Origin': 'http://localhost:4000'
}

export const getAuthorize = (redirectPage = null) => {
  const uri = `${baseUri}/authorize`
  const uriWithQuery = redirectPage ? `${uri}?redirect_page=${redirectPage}` : uri

  return fetch(uriWithQuery, { redirect: 'follow', headers })
}

export const getCallback = queryString => {
  const uri = `${baseUri}/callback?${queryString}`

  return fetch(uri)
}

export const getResource = () => {
  const uri = `${baseUri}/fetch_resource`

  return fetch(uri)
}

export const getToken = () => {
  const uri = `${baseUri}/token`

  return fetch(uri)
}