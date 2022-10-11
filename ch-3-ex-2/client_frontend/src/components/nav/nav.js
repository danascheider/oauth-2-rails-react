import Label from '../label/label'
import styles from './nav.module.css'

const Nav = () => (
  <header className={styles.root}>
    <nav className={styles.nav}>
      <h1 className={styles.title}>
        <a className={styles.link} href='/'>OAuth in Action:</a>
      </h1>
      <span className={styles.label}><Label color='blue'>OAuth Client</Label></span>
    </nav>
  </header>
)

export default Nav