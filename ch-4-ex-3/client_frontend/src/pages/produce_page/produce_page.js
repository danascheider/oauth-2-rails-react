import { useEffect, useRef, useState } from 'react'
import { getProduce } from '../../utils/api'
import Nav from '../../components/nav/nav'
import ErrorContent from '../../components/error_content/error_content'
import ProducePageContent from '../../components/produce_page_content/produce_page_content'

const ProducePage = () => {
  const [fruit, setFruit] = useState(null)
  const [veggies, setVeggies] = useState(null)
  const [meats, setMeats] = useState(null)
  const [scope, setScope] = useState([])
  const [error, setError] = useState(null)
  const mountedRef = useRef(true)

  useEffect(() => {
    getProduce()
      .then(resp => {
        resp.json()
          .then(json => {
            if (json.error) {
              setError(json.error)
            } else {
              if (json.produce?.length) {
                setFruit(json.produce.fruit)
                setVeggies(json.produce.veggies)
                setMeats(json.produce.meats)
              }

              if (json.scope) setScope(json.scope)
            }
          })
      })

    return () => mountedRef.current = false
  }, [])

  return(
    <>
      <Nav />
      {error ? <ErrorContent error={error} /> :
      <ProducePageContent fruit={fruit} veggies={veggies} meats={meats} scope={scope} />}
    </>
  )
}

export default ProducePage