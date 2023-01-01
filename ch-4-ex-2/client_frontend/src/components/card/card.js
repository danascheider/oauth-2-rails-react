import PropTypes from 'prop-types'
import Label from '../label/label'
import styles from './card.module.css'

const Card = ({ header, status, children }) => {
  return(
    <div className={styles.root}>
      <div className={styles.contents}>
        <h2 className={styles.header}>{header}</h2>
        {status && <div className={styles.status}><Label color={status === 'Success' ? 'green' : 'red'}>{status}</Label></div>}
        {children}
      </div>
    </div>
  )
}

Card.propTypes = {
  header: PropTypes.string.isRequired,
  status: PropTypes.oneOf(['Success', 'Failure']),
  children: PropTypes.node
}

export default Card