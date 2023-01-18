import PropTypes from 'prop-types'
import styles from './label.module.css'

const Label = ({ color, children }) => (
  <span className={styles.root} style={{ '--background-color': color }}>
    {children}
  </span>
)

Label.propTypes = {
  color: PropTypes.string.isRequired,
  children: PropTypes.node
}

export default Label