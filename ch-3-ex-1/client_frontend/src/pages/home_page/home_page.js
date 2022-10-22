import { useEffect, useRef, useState } from 'react'
import { getToken } from '../../utils/api'
import Nav from '../../components/nav/nav'
import PageBody from '../../components/page_body/page_body'
import HomePageContent from '../../components/home_page_content/home_page_content'
import ErrorContent from '../../components/error_content/error_content'

const HomePage = () => {
  const [tokenValue, setTokenValue] = useState(null)
  const [error, setError] = useState(null)
  const mountedRef = useRef(true)

  useEffect(() => {
    if (mountedRef.current) {
      getToken().then(resp => {
        resp.json().then(json => {
          if (!json) return

          if (json.error) {
            setError(json.error)
          } else {
            setTokenValue(json.access_token)
          }
        })
      })
    }

    return () => mountedRef.current = false
  }, [])

  return(
    <>
      <Nav />
      <PageBody>
        {error ? <ErrorContent error={error} /> :
          <HomePageContent tokenValue={tokenValue || 'NONE'} />}
      </PageBody>
    </>
  )
}

export default HomePage