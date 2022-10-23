import { useNavigate } from 'react-router-dom'
import PropTypes from 'prop-types'
import paths from '../../routing/paths'
import { getAuthorize } from '../../utils/api'
import ButtonLink from '../button_link/button_link'
import Label from '../label/label'
import styles from './home_page_content.module.css'

const HomePageContent = ({ tokenValue }) => {
  const navigate = useNavigate()

  const goToResource = e => {
    e.preventDefault()

    navigate(paths.resource)
  }

  const authorize = (e, redirectPage = null) => {
    e.preventDefault()

    getAuthorize(redirectPage)
      .then(resp => {
        window.location.href = resp.url
      })
  }

  return(
    <>
      <p className={styles.text}>
        Access token value:&nbsp;
        {tokenValue ? <code className={styles.code}>{tokenValue}</code> :
          <Label color='red'>NONE</Label>}
      </p>
      <div>
        <span className={styles.buttonLeft}>
          <ButtonLink text='Get OAuth Token' onClick={authorize} />
        </span>
        <span>
          <ButtonLink text='Get Protected Resource' onClick={tokenValue ? goToResource : e => authorize(e, 'resource')} />
        </span>
      </div>
    </>
  )
}

HomePageContent.propTypes = {
  tokenValue: PropTypes.string
}

export default HomePageContent