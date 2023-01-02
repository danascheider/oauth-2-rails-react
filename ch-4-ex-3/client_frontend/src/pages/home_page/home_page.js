import { useEffect, useRef, useState } from 'react'
// import { getToken } from '../../utils/api'
import Nav from '../../components/nav/nav'
import HomePageContent from '../../components/home_page_content/home_page_content'
import ErrorContent from '../../components/error_content/error_content'
import PageBody from '../../components/page_body/page_body'

const HomePage = () => {
  const [accessToken, setAccessToken] = useState(null)
  const [refreshToken, setRefreshToken] = useState(null)
  const [scope, setScope] = useState(null)
  const [error, setError] = useState(null)
  const mountedRef = useRef(true)

  // useEffect(() => {
  //   if (mountedRef.current) {
  //     getToken()
  //       .then(resp => {
  //         if (resp.status === 204) return

  //         resp.json()
  //           .then(json => {
  //             if (json.error) {
  //               setError(json.error)
  //             } else {
  //               setAccessToken(json.access_token)
  //               setRefreshToken(json.refresh_token)
  //               setScope(json.scope)
  //             }
  //           })
  //       })
  //   }

  //   return () => mountedRef.current = false
  // }, [])

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

export default HomePage