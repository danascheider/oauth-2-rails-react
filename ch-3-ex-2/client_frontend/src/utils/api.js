const baseUri = 'http://localhost:4001'

export const getAuthorize = () => {
  const uri = `${baseUri}/authorize`

  return fetch(uri)
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