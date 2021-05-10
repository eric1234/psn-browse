import Search from './search.svelte'
import db from '../../data/search.json'

const app = new Search({
  target: document.getElementById('search'),
  props: { db },
})

export default app
