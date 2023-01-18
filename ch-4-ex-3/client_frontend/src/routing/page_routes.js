import { Route, Routes } from 'react-router-dom'
import { Helmet } from 'react-helmet-async'
import HomePage from '../pages/home_page/home_page'
import CallbackPage from '../pages/callback_page/callback_page'
import ProducePage from '../pages/produce_page/produce_page'
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
    pageId: 'produce',
    title: 'OAuth Client Resource Page',
    description: 'Example OAuth 2.0 Client Frontend',
    jsx: <ProducePage />,
    path: paths.produce
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