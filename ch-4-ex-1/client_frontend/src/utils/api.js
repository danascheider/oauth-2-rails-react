const baseUri = 'http://localhost:4001'

export const getAuthorize = (redirectPage = null) => {
  const uri = `${baseUri}/authorize`
  const uriWithQuery = redirectPage ? `${uri}?redirect_page=${redirectPage}` : uri

  return fetch(uriWithQuery)
}

export const getToken = () => {
  const uri = `${baseUri}/token`

  return fetch(uri)
}