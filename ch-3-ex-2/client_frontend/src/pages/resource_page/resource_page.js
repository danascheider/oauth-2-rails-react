import { useState, useEffect, useRef } from 'react'
import { getResource } from '../../utils/api'
import Nav from '../../components/nav/nav'
import PageBody from '../../components/page_body/page_body'
import ErrorContent from '../../components/error_content/error_content'
import styles from './resource_page.module.css'

const ResourcePage = () => {
  const [resource, setResource] = useState([])
  const [error, setError] = useState(null)
  const mountedRef = useRef(true)

  useEffect(() => {
    if (mountedRef.current) {
      getResource().then(resp => {
        resp.json().then(json => {
          json.resource ? setResource(json.resource) : setError(json.error)
        })
      })
    }

    return () => mountedRef.current = false
  }, [])

  return(
    <>
      <Nav />
      <PageBody>
        <h2 className={styles.header}>Data from protected resource:</h2>
        {error ? <ErrorContent error={error} /> :
          <div className={styles.data}>
            [
            <ul className={styles.resourceList}>
              {resource.map(element => (
                <li className={styles.listItem} key={element.id}>
                  &emsp;&emsp;&#123;
                  <ul className={styles.attributes}>
                    <li className={styles.itemText}>&emsp;&emsp;&emsp;&emsp;"name": "{element.name}",</li>
                    <li className={styles.itemText}>&emsp;&emsp;&emsp;&emsp;"description": "{element.description}"</li>
                  </ul>
                  &emsp;&emsp;&#125;{element === resource[resource.length - 1] ? '' : ','}
                </li>
              ))}
            </ul>
            ]
          </div>}
      </PageBody>
    </>
  )
}

export default ResourcePage