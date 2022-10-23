import { useNavigate } from 'react-router-dom'
import { PropTypes } from 'prop-types'
import { getAuthorize } from '../../utils/api'
import paths from '../../routing/paths'
import ButtonLink from '../button_link/button_link'
import Label from '../label/label'
import styles from './home_page_content.module.css'

const HomePageContent = ({ accessToken, refreshToken, scope }) => {
  const navigate = useNavigate()

  const authorize = e => {
    e.preventDefault()

    getAuthorize()
      .then(resp => {
        window.location.href = resp.url
      })
  }

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
          <ButtonLink text='Get OAuth Token' onClick={authorize} />
        </span>
        <span>
          <ButtonLink text='Fetch Protected Resource' onClick={() => navigate(paths.resource)} />
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