import { useEffect, useState, useRef } from 'react'
import { useSearchParams } from 'react-router-dom'
import { getCallback } from '../../utils/api'
import Nav from '../../components/nav/nav'
import PageBody from '../../components/page_body/page_body'
import HomePageContent from '../../components/home_page_content/home_page_content'
import ErrorContent from '../../components/error_content/error_content'

const CallbackPage = () => {
  const [queryParams, _setQueryParams] = useSearchParams()
  const [tokenValue, setTokenValue] = useState(null)
  const [error, setError] = useState(queryParams.get('error'))
  const mountedRef = useRef(true)

  useEffect(() => {
    if (mountedRef.current && !tokenValue && !error) {
      getCallback(queryParams)
        .then(resp => {
          resp.json()
            .then((json) => {
              if (resp.status >= 200 && resp.status < 300) {
                setTokenValue(json.access_token)
              } else {
                setError(json.error)
              }
            })
        })
    }

    return () => mountedRef.current = false
  }, [error, tokenValue, queryParams])

  return(
    <>
      <Nav />
      <PageBody>
        {error ? <ErrorContent error={error} /> :
          <HomePageContent tokenValue={tokenValue} />}
      </PageBody>
    </>
  )
}

export default CallbackPage