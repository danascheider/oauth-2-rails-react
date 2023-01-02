import PropTypes from 'prop-types'
import styles from './button_link.module.css'

const ButtonLink = ({ text, onClick }) => (
  <a className={styles.root} onClick={onClick}>
    {text}
  </a>
)

ButtonLink.propTypes = {
  text: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired
}

export default ButtonLink