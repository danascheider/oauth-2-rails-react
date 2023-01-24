const baseUri = 'http://localhost:4001'

export const getToken = () => {
  const uri = `${baseUri}/tokens`

  return fetch(uri)
}