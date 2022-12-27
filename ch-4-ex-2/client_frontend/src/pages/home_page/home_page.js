import { useState } from 'react'
import Nav from '../../components/nav/nav'
import HomePageContent from '../../components/home_page_content/home_page_content'
import ErrorContent from '../../components/error_content/error_content'
import PageBody from '../../components/page_body/page_body'

const HomePage = () => {
  const [accessToken, setAccessToken] = useState(null)
  const [refreshToken, setRefreshToken] = useState(null)
  const [scope, setScope] = useState(null)
  const [error, setError] = useState(null)

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