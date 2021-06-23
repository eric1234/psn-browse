import { parse, stringify } from 'qs'

const defaults = {
  query: '',
  sort: 'rank',
  yearStart: 2010,
  yearEnd: (new Date().getFullYear()),
}

// Provides storage for the search criteria as well as some utility functions
// for mapping this state to the browser history.
export default class {

  // Mostly self-contained the class just needs to know what facets exist
  constructor(facets, minYear) {
    this.facets = facets

    const current = parse(this.currentQueryString().substr(1))

    // We have general defaults but IF the initial querystring has a search
    // query then adjust those defaults to use the min year
    this.defaults = defaults
    if( current.query ) this.defaults.yearStart = minYear

    Object.assign(this, defaults, current)

    this.filters ||= {}
    this.excludes ||= {}
    this.facets.forEach(f => {
      this.filters[f] = this.filters[f] || []
      this.excludes[f] = this.excludes[f] || []
    })
  }

  // The current search state. This is everything being given to the search
  // engine EXCEPT the default values.
  state() {
    const state = { filters: {}, excludes: {} }
    for (let [fld, dft] of Object.entries(this.defaults))
      if( this[fld] != dft ) state[fld] = this[fld]

    this.facets.forEach(f => {
      if( this.filters[f].length > 0) state.filters[f] = this.filters[f]
      if( this.excludes[f].length > 0) state.excludes[f] = this.excludes[f]
    })
    if( Object.keys(state.filters).length == 0 ) delete state.filters
    if( Object.keys(state.excludes).length == 0 ) delete state.excludes

    return state
  }

  // A normalized version of the current querystring
  currentQueryString() {
    return `?${stringify(parse(window.location.search.substr(1)))}`
  }

  // What the querystring *should* be based on the state
  targetQueryString() {
    let qs = `?${stringify(this.state())}`
    if( qs == '?' ) qs = ''
    return qs
  }

  // What the URL should be set to based on the state
  relativeUrl() {
    if( this.targetQueryString() )
      return this.targetQueryString()
    else
      return window.location.pathname
  }

  // Update the state to the given state. If not given use default
  setState(state) {
    for (let [fld, dft] of Object.entries(this.defaults))
      this[fld] = state[fld] || dft

    this.filters = state.filters || {}
    this.excludes = state.excludes || {}
    this.facets.forEach(f => {
      this.filters[f] = this.filters[f] || []
      this.excludes[f] = this.excludes[f] || []
    })
  }
}
