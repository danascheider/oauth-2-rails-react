const baseUri = 'http://localhost:4001'

export const getAuthorize = () => {
  const uri = `${baseUri}/authorize`

  return fetch(uri, { redirect: 'manual' })
}

export const getCallback = queryString => {
  const uri = `${baseUri}/callback?${queryString}`

  return fetch(uri)
}

export const getProduce = () => {
  const uri = `${baseUri}/produce`

  return fetch(uri)
}

export const getToken = () => {
  const uri = `${baseUri}/tokens`

  return fetch(uri)
}