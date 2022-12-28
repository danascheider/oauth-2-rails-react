import { useState, useRef, useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { getCallback } from '../../utils/api'
import ErrorContent from '../../components/error_content/error_content'
import HomePageContent from '../../components/home_page_content/home_page_content'
import Nav from '../../components/nav/nav'
import PageBody from '../../components/page_body/page_body'

const CallbackPage = () => {
  const [queryParams, _setQueryParams] = useSearchParams()
  const [accessToken, setAccessToken] = useState(null)
  const [refreshToken, setRefreshToken] = useState(null)
  const [scope, setScope] = useState(null)
  const [error, setError] = useState(queryParams.get('error'))
  const mountedRef = useRef(true)

  useEffect(() => {
    if (mountedRef.current && !accessToken && !error) {
      getCallback(queryParams)
        .then(resp => {
          resp.json()
            .then(json => {
              if (resp.status >= 200 && resp.status < 300) {
                setAccessToken(json.access_token)
                setRefreshToken(json.refresh_token)
                setScope(json.scope.join(' '))
              } else {
                setError(json.error)
              }
            })
        })
    }

    return () => mountedRef.current = false
  }, [error, accessToken, queryParams])

  return(
    <>
      <Nav />
      <PageBody>
        {error ? <ErrorContent error={error} /> :
          <HomePageContent accessToken={accessToken} refreshToken={refreshToken} scope={scope} />}
      </PageBody>
    </>
  )
}

export default CallbackPage