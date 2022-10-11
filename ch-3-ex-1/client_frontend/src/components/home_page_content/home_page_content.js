import { useNavigate } from 'react-router-dom'
import paths from '../../routing/paths'
import { getAuthorize } from '../../utils/api'
import ButtonLink from '../button_link/button_link'
import Label from '../label/label'
import styles from './home_page_content.module.css'

const HomePageContent = ({ tokenValue = 'NONE' }) => {
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
        {tokenValue === 'NONE' ?
          <Label color='red'>{tokenValue}</Label> :
          <code className={styles.code}>{tokenValue}</code>}
      </p>
      <div>
        <span className={styles.buttonLeft}>
          <ButtonLink text='Get OAuth Token' onClick={authorize} />
        </span>
        <span>
          <ButtonLink text='Get Protected Resource' onClick={() => navigate(paths.resource)} />
        </span>
      </div>
    </>
  )
}

export default HomePageContent