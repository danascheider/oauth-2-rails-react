import Card from '../card/card'
import styles from './words_page_content.module.css'

const WordsPageContent = () => (
  <main className={styles.root}>
    <div className={styles.container}>
      <section className={styles.cards}>
        <div className={styles.card}><Card header='Read the current value'></Card></div>
        <div className={styles.card}><Card header='Add a word to the list'></Card></div>
        <div className={styles.card}><Card header='Remove the last word from the list'></Card></div>
      </section>
    </div>
  </main>
)

export default WordsPageContent