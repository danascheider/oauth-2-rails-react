import { Route, Routes } from 'react-router-dom'
import { Helmet } from 'react-helmet-async'
import HomePage from '../pages/home_page/home_page'
import CallbackPage from '../pages/callback_page/callback_page'
import ResourcePage from '../pages/resource_page/resource_page'
import paths from './paths'

const pages = [
  {
    pageId: 'home',
    title: 'OAuth Client Home',
    description: 'Example OAuth 2.0 Client Frontend',
    jsx: <HomePage />,
    path: paths.home
  },
  {
    pageId: 'callback',
    title: 'OAuth Client Callback',
    description: 'Example OAuth 2.0 Client Frontend',
    jsx: <CallbackPage />,
    path: paths.callback
  },
  {
    pageId: 'resource',
    title: 'OAuth Client Protected Resource',
    description: 'Example OAuth 2.0 Protected Resource',
    jsx: <ResourcePage />,
    path: paths.resource
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