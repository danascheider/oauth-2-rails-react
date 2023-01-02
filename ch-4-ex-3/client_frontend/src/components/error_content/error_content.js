import PropTypes from 'prop-types'
import styles from './error_content.module.css'

const ErrorContent = ({ error }) => (
  <>
    <h2 className={styles.header}>Error</h2>
    <p>{error}</p>
  </>
)

ErrorContent.propTypes = {
  error: PropTypes.string.isRequired
}

export default ErrorContent