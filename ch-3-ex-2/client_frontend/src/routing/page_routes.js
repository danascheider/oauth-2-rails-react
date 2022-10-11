import { Route, Routes } from 'react-router-dom'
import { Helmet } from 'react-helmet-async'
import HomePage from '../pages/home_page/home_page'
import paths from './paths'

const pages = [
  {
    pageId: 'home',
    title: 'OAuth Client Home',
    description: 'Example OAuth 2.0 Client Frontend',
    jsx: <HomePage />,
    path: paths.home
  }
]

const PageRoutes = () => (
  <Routes>
    {pages.map(({ pageId, title, description, jsx, path }) => {
      return(
        <Route
          exact
          path={path}
          key={pageId}
          element={<>
            <Helmet>
              <html lang='en' />
              <title>{title}</title>
              <meta name='description' content={description}></meta>
            </Helmet>
            {jsx}
          </>}
        />
      )
    })}
  </Routes>
)

export default PageRoutes