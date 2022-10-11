import styles from './button_link.module.css'

const ButtonLink = ({ text, onClick }) => (
  <a className={styles.root} onClick={onClick}>
    {text}
  </a>
)

export default ButtonLink