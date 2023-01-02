import PropTypes from 'prop-types'
import styles from './label.module.css'

const COLORS = {
  blue: '#337ab7',
  red: '#d9534f',
  green: '#5cb85c'
}

const Label = ({ color, children }) => (
  <span className={styles.root} style={{ '--background-color': COLORS[color] }}>
    {children}
  </span>
)

Label.propTypes = {
  color: PropTypes.oneOf(['blue', 'red', 'green']).isRequired,
  children: PropTypes.node
}

export default Label