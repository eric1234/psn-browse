<Filter bind:search={searchState} {minYear} facets={results.data.aggregations} />

<div class="d-flex justify-content-end fw-bolder mb-3">
  {results.data.items.length} results
</div>

<div class="row row-cols-1 row-cols-sm-2 row-cols-md-3 row-cols-lg-4 row-cols-xl-5">
  {#each results.data.items as result (result.id)}
    <Result {...result} />
  {/each}
</div>

<script>
import configureDB from 'itemsjs'

import SearchState from './search_state'
import Filter from './filter'
import Result from './result'

export let db

function sortings(flds) {
  return flds.reduce(function(acc, fld) {
    acc[fld] = { field: fld, order: 'desc' }
    return acc
  }, {})
}
function w(str) { return str.trim().split(/\s+/) }

let facets = {
  genres: { title: 'Genres', size: 15 },
  themes: { title: 'Themes', size: 15 },
  player_perspectives: { title: 'Player Perspectives', size: 10 },
  content_descriptions: { title: 'Age Related Content', size: 10 },
}

let engine = configureDB(db, {
  sortings: sortings(['rank', 'release_date']),
  aggregations: facets,
  searchableFields: w(`
    name storyline summary collection franchises genres
    keywords themes content_descriptions studio
  `),
})

const releaseYearFor = item => parseInt(item.release_date.slice(0, 4))
const withoutDummyDate = i => i.release_date != '1970-01-01'
const years = db.filter(withoutDummyDate).map(releaseYearFor)
let minYear = Math.min(...years)

let searchState = new SearchState(Object.keys(facets), minYear)
$: {
  if( searchState.targetQueryString() != searchState.currentQueryString() )
    history.pushState(searchState.state(), '', searchState.relativeUrl())
}
window.addEventListener('popstate', e => {
  searchState.setState(event.state)
  searchState = searchState // Force reactivity
})

function yearFilter(item) {
  // If release date not known (epoch) include it regardless of date filter.
  // It will be at the end of the list at least
  if( item.release_date == '1970-01-01' ) return true

  const year = releaseYearFor(item)
  return year >= searchState.yearStart && year <= searchState.yearEnd
}

let results
$: {
  // Access year params to ensure search is re-run when they change
  searchState.yearStart, searchState.yearEnd

  results = engine.search({
    query: searchState.query,
    sort: searchState.sort,
    filters: searchState.filters,
    not_filters: searchState.excludes,
    filter: yearFilter,
    per_page: db.length
  })
}
</script>
