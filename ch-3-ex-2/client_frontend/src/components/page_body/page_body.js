import PropTypes from 'prop-types'
import styles from './page_body.module.css'

const PageBody = ({ children }) => (
  <main className={styles.root}>
    <div className={styles.container}>
      {children}
    </div>
  </main>
)

PageBody.propTypes = {
  children: PropTypes.node
}

export default PageBody