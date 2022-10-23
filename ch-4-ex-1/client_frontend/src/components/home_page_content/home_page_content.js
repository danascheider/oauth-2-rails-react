import { PropTypes } from 'prop-types'
import ButtonLink from '../button_link/button_link'
import Label from '../label/label'
import styles from './home_page_content.module.css'

const HomePageContent = ({ accessToken, refreshToken, scope }) => {
  return(
    <>
      <p className={styles.text}>
        Access token value:&nbsp;
        <Label color='red'>{accessToken || 'NONE'}</Label>
      </p>
      <p className={styles.text}>
        Scope:&nbsp;
        <Label color='red'>{scope || 'NONE'}</Label>
      </p>
      <p className={styles.text}>
        Refresh token value:&nbsp;
        <Label color='red'>{refreshToken || 'NONE'}</Label>
      </p>
      <div className={styles.buttons}>
        <span className={styles.buttonLeft}>
          <ButtonLink text='Get OAuth Token' onClick={() => {}} />
        </span>
        <span>
          <ButtonLink text='Fetch Protected Resource' onClick={() => {}} />
        </span>
      </div>
    </>
  )
}

HomePageContent.propTypes = {
  accessToken: PropTypes.string,
  refreshToken: PropTypes.string,
  scope: PropTypes.string
}

export default HomePageContent