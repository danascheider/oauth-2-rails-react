import { useState, useEffect } from 'react'
import { getResource } from '../../utils/api'
import Nav from '../../components/nav/nav'
import PageBody from '../../components/page_body/page_body'
import styles from './resource_page.module.css'
import ErrorContent from '../../components/error_content/error_content'

const ResourcePage = () => {
  const [resource, setResource] = useState([])
  const [error, setError] = useState(null)

  useEffect(() => {
    const { data } = getResource()

    data.resource ? setResource(data.resource) : setError(data.error)
  }, [setResource, setError])

  return(
    <>
      <Nav />
      <PageBody>
        <h2 className={styles.header}>Data from protected resource:</h2>
        <div className={styles.data}>
          {error ? <ErrorContent error={error} /> :
            <ul className={styles.list}>
              {resource.map(element => (
                <li className={styles.listItem}>
                  <ul className={styles.subList}>
                    <li className={styles.itemText}><strong>Name:</strong> {element.name}</li>
                    <li className={styles.itemText}><strong>Description:</strong> {element.description}</li>
                  </ul>
                </li>
              ))}
            </ul>}
        </div>
      </PageBody>
    </>
  )
}

export default ResourcePage