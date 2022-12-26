import { useState, useEffect, useRef } from 'react'
import { useSearchParams } from 'react-router-dom'
import { getAuthorize, getCallback, getResource } from '../../utils/api'
import Nav from '../../components/nav/nav'
import PageBody from '../../components/page_body/page_body'
import ErrorContent from '../../components/error_content/error_content'
import styles from './resource_page.module.css'

const ResourcePage = () => {
  const [queryParams, _setQueryParams] = useSearchParams()
  const [resource, setResource] = useState([])
  const [error, setError] = useState(null)
  const mountedRef = useRef(true)

  const authorize = () => {
    getAuthorize('resource')
      .then(resp => {
        window.location.href = resp.url
      })
  }

  useEffect(() => {
    if (mountedRef.current) {
      if (queryParams.get('code')) {
        getCallback(queryParams)
          .then(_res => {
            getResource().then(resp => {
              if (resp.status === 401) {
                authorize()
              } else {
                resp.json().then(json => {
                  json.resource ? setResource(json.resource) : setError(json.error)
                })
              }
            })
          })
      } else {
        getResource().then(resp => {
          if (resp.status === 401) {
            authorize()
          } else {
            resp.json().then(json => {
              json.resource ? setResource(json.resource) : setError(json.error)
            })
          }
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
            </div>
          </>}
      </PageBody>
    </>
  )
}

export default ResourcePage