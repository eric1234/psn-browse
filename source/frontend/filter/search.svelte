<label class="form-label" for="query">Search</label>
<input type="search" class="form-control mb-3" id="query" value={query} on:input={e => debouncedSetQuery(e.target.value)}>

<script>
import debounce from 'debounce'

export let query

function setQuery(value) { query = value }
const debouncedSetQuery = debounce(setQuery, 500)
</script>
