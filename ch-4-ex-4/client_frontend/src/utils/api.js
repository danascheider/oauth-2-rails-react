const baseUri = 'http://localhost:4001'

export const getAuthorize = () => {
  const uri = `${baseUri}/authorize`

  return fetch(uri, { redirect: 'manual' })
}

export const getToken = () => {
  const uri = `${baseUri}/token`

  return fetch(uri)
}