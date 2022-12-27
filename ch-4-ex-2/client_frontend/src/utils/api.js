const baseUri = 'http://localhost:4001'

export const getAuthorize = (redirectPage = null) => {
  const uri = `${baseUri}/authorize`
  const uriWithQuery = redirectPage ? `${uri}?redirect_page=${redirectPage}` : uri

  return fetch(uriWithQuery)
}

// export const getToken = () => {
//   const uri = `${baseUri}/token`

//   return fetch(uri)
// }

// export const getCallback = queryString => {
//   const uri = `${baseUri}/callback?${queryString}`

//   return fetch(uri)
// }

// export const getResource = () => {
//   const uri = `${baseUri}/fetch_resource`

//   return fetch(uri)
// }