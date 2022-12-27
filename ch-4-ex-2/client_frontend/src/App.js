import { HelmetProvider } from 'react-helmet-async'
import { BrowserRouter as Router } from 'react-router-dom'
import PageRoutes from './routing/page_routes'

const App = () => (
  <Router basename={process.env.PUBLIC_URL}>
    <HelmetProvider>
      <PageRoutes />
    </HelmetProvider>
  </Router>
)

export default App
