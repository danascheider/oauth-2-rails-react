const baseUri = 'http://localhost:4001'
const wordsUri = `${baseUri}/words`

export const getAuthorize = () => {
  const uri = `${baseUri}/authorize`

  return fetch(uri)
}

export const getToken = () => {
  const uri = `${baseUri}/token`

  return fetch(uri)
}

export const getCallback = queryString => {
  const uri = `${baseUri}/callback?${queryString}`

  return fetch(uri)
}

export const getWords = () => fetch(wordsUri)

export const addWord = word => {
  const body = JSON.stringify({ word })
  const headers = {
    'Content-Type': 'application/json'
  }
  return fetch(wordsUri, { method: 'POST', body, headers })
}

export const deleteWord = () => fetch(wordsUri, { method: 'DELETE' })