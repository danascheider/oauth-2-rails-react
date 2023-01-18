import PropTypes from 'prop-types'
import Label from '../label/label'
import styles from './produce_page_content.module.css'

const ProduceSection = ({ title, contentsArray }) => {
  if (!contentsArray || !contentsArray.length) return

  return(
    <section className={styles.section}>
      <h3 className={styles.sectionHeader}>{title}</h3>
      <ul className={styles.list}>
        {contentsArray.map(item => <li className={styles.listItem} key={item}>{item}</li>)}
      </ul>
    </section>
  )
}

ProduceSection.propTypes = {
  title: PropTypes.string.isRequired,
  contentsArray: PropTypes.array
}

const ProducePageContent = ({
  scope,
  fruit = [],
  veggies = [],
  meats = []
}) => {
  return(
    <>
      <h2 className={styles.header}>Produce API</h2>
      <div className={styles.flexbox}>
        <h3 className={styles.inlineHeader}>Current Scope:</h3>
        <Label color='#5bc0de'>{scope || 'NONE'}</Label>
      </div>
      <ProduceSection title='Fruits:' contentsArray={fruit} />
      <ProduceSection title='Veggies:' contentsArray={veggies} />
      <ProduceSection title='Meats:' contentsArray={meats} />
    </>
  )
}

ProducePageContent.propTypes = {
  scope: PropTypes.string,
  fruit: PropTypes.array,
  veggies: PropTypes.array,
  meats: PropTypes.array
}

export default ProducePageContent