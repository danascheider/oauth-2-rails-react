import styles from './error_content.module.css'

const ErrorContent = ({ error }) => (
  <>
    <h2 className={styles.header}>Error</h2>
    <p>{error}</p>
  </>
)

export default ErrorContent