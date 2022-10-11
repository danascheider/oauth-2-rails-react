import styles from './label.module.css'

const COLORS = {
  blue: '#337ab7',
  red: '#d9534f'
}

const Label = ({ color, children }) => (
  <span className={styles.root} style={{ '--background-color': COLORS[color] }}>
    {children}
  </span>
)

export default Label