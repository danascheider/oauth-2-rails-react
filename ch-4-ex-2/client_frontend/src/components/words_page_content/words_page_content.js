import { useState } from 'react'
import { getWords, addWord, deleteWord, getAuthorize } from '../../utils/api'
import Card from '../card/card'
import ColorButton from '../color_button/color_button'
import styles from './words_page_content.module.css'

const FAILURE = 'Failure'
const SUCCESS = 'Success'

const WordsPageContent = () => {
  const [statusLeft, setStatusLeft] = useState(null)
  const [statusCenter, setStatusCenter] = useState(null)
  const [statusRight, setStatusRight] = useState(null)
  const [wordResponse, setWordResponse] = useState({})

  const fetchWords = e => {
    e.preventDefault()

    setStatusCenter(null)
    setStatusRight(null)

    getWords().then(resp => {
      if (resp.status >= 200 && resp.status < 300) {
        if (resp.redirected === true) {
          window.location.href = resp.url
        } else {
          setStatusLeft(SUCCESS)

          resp.json().then(json => {
            // console.log(json)
            setWordResponse(json)
          })
        }
      } else {
        setStatusLeft(FAILURE)
      }
    })
  }

  const submitForm = e => {
    e.preventDefault()

    setStatusLeft(null)
    setStatusRight(null)
    setWordResponse({})

    addWord(document.getElementById('wordInput').value)
      .then(resp => {
        if (resp.status >= 200 && resp.status < 300) {
          document.getElementById('wordInput').value = ''
          if (resp.redirected === true) {
            window.location.href = resp.url
          } else {
            setStatusCenter(SUCCESS)
          }
        } else {
          setStatusCenter(FAILURE)
        }
      })
  }

  const destroyWord = e => {
    e.preventDefault()

    setStatusLeft(null)
    setStatusCenter(null)
    setWordResponse({})

    deleteWord().then(resp => {
      if (resp.status >= 200 && resp.status < 300) {
        if (resp.redirected === true) {
          window.location.href = resp.url
        } else {
          setStatusRight(SUCCESS)
        }
      } else {
        setStatusRight(FAILURE)
      }
    })
  }

  return(
    <main className={styles.root}>
      <div className={styles.container}>
        <section className={styles.cards}>
          <div className={styles.card}>
            <Card header='Read the current value' status={statusLeft}>
              {Array.isArray(wordResponse.words) &&
                <>
                <p>Words: {wordResponse.words.join(' ')}</p>
                <p>Timestamp: {wordResponse.timestamp}</p>
                </>}
              <ColorButton
                colorScheme='teal'
                text='GET current value'
                onClick={fetchWords}
              />
            </Card>
          </div>
          <div className={styles.card}>
            <Card header='Add a word to the list' status={statusCenter}>
              <input id='wordInput' className={styles.input} placeholder='word' />
              <ColorButton
                colorScheme='yellow'
                text='POST a new word'
                onClick={submitForm}
              />
            </Card>
          </div>
          <div className={styles.card}>
            <Card header='Remove the last word from the list' status={statusRight}>
              <ColorButton
                colorScheme='red'
                text='DELETE the last word'
                onClick={destroyWord}
              />
            </Card>
          </div>
        </section>
      </div>
    </main>
  )
}

export default WordsPageContent