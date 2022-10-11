import Nav from '../../components/nav/nav'
import PageBody from '../../components/page_body/page_body'
import HomePageContent from '../../components/home_page_content/home_page_content'

const HomePage = () => {
  return(
    <>
      <Nav />
      <PageBody>
        <HomePageContent accessToken='NONE' refreshToken='NONE' scope='NONE' />
      </PageBody>
    </>
  )
}

export default HomePage