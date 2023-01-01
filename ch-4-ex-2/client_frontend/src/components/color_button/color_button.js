import styles from './color_button.module.css'

const COLOR_SCHEMES = {
  teal: {
    background: '#5bc0de',
    border: '#46b8da'
  },
  yellow: {
    background: '#f0ad4e',
    border: '#eea236'
  },
  red: {
    background: '#d9534f',
    border: '#d43f3a'
  }
}

const ColorButton = ({ colorScheme, text, onClick }) => {
  const scheme = COLOR_SCHEMES[colorScheme]

  return(
    <a
      className={styles.root}
      role='button'
      onClick={onClick}
      style={{ '--background-color': scheme.background, '--border-color': scheme.border }}
    >
      {text}
    </a>
  )
}

export default ColorButton