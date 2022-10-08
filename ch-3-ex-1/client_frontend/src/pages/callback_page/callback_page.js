import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { getCallback } from '../../utils/api'
import Nav from '../../components/nav/nav'
import PageBody from '../../components/page_body/page_body'
import HomePageContent from '../../components/home_page_content/home_page_content'
import ErrorContent from '../../components/error_content/error_content'

const CallbackPage = () => {
  const [queryParams, _setQueryParams] = useSearchParams()
  const [tokenValue, setTokenValue] = useState(null)
  const [error, setError] = useState(queryParams.error)

  useEffect(() => {
    if (!error) {
      const { status, data } = getCallback(queryParams)

      if (status >= 200 && status < 300) {
        setTokenValue(data.access_token)
      } else {
        setError(data.error)
      }
    }
  }, [error, setTokenValue, setError, queryParams])

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