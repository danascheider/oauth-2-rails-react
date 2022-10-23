import { useState, useEffect, useRef } from 'react'
import { getResource, getAuthorize, getCallback } from '../../utils/api'
import { useSearchParams } from 'react-router-dom'
import Nav from '../../components/nav/nav'
import PageBody from '../../components/page_body/page_body'
import ErrorContent from '../../components/error_content/error_content'
import styles from './resource_page.module.css'

const ResourcePage = () => {
  const [resource, setResource] = useState([])
  const [error, setError] = useState(null)
  const [queryParams, setQueryParams] = useSearchParams()
  const mountedRef = useRef(true)

  const authorize = () => {
    getAuthorize('resource')
      .then(resp => {
        window.location.href = resp.url
      })
  }

  const setValues = (status, json) => {
    if (json.error) {
      if (status === 401) {
        authorize()
      } else {
        setError(json.error)
      }
    } else {
      setResource(json.resource)
    }
  }

  useEffect(() => {
    if (mountedRef.current) {
      if (queryParams.get('code')) {
        getCallback(queryParams.toString())
          .then(_res => {
            getResource().then(resp => {
              resp.json().then(json => {
                setValues(resp.status, json)
              })
            })
          })
      } else {
        getResource()
          .then(resp => {
            resp.json().then(json => {
              setValues(resp.status, json)
            })
          })
      }
    }

    return () => mountedRef.current = false
  }, [queryParams])

  return(
    <>
      <Nav />
      <PageBody>
        {error ? <ErrorContent error={error} /> :
          <>
            <h2 className={styles.header}>Data from protected resource:</h2>
            <div className={styles.data}>
              [
              <ul className={styles.resourceList}>
                {resource.map(element => (
                  <li className={styles.listItem} key={element.name}>
                    &emsp;&emsp;&#123;
                    <ul className={styles.attributes}>
                      <li className={styles.itemText} key='name'>&emsp;&emsp;&emsp;&emsp;"name": "{element.name}",</li>
                      <li className={styles.itemText} key='description'>&emsp;&emsp;&emsp;&emsp;"description": "{element.description}"</li>
                    </ul>
                    &emsp;&emsp;&#125;{element === resource[resource.length - 1] ? '' : ','}
                  </li>
                ))}
              </ul>
              ]
            </div>
          </>}
      </PageBody>
    </>
  )
}

export default ResourcePage