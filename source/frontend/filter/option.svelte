<div class="form-check" class:excluded={excludes.includes(bucket.key)}>
  <input class="form-check-input" type="checkbox" id={bucket.key}
    checked={included} value={bucket.key} on:input={toggleFilter}>
  <label class="form-check-label" for={bucket.key}>
    {bucket.key} ({bucket.doc_count})
  </label>
  <button class="btn text-danger p-0 border-0" on:click|stopPropagation={toggleExclude}>
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x" viewBox="0 0 16 16">
      <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z"/>
    </svg>
  </button>
</div>

<script>
export let bucket
export let filter
export let excludes

$: included = filter.includes(bucket.key)

function toggleFilter() {
  filter = toggle(filter, bucket.key)
  included = filter.includes(bucket.key)
}
function toggleExclude() { excludes = toggle(excludes, bucket.key) }
function toggle(list, val) {
  if( list.includes(val) )
    return list.filter(i => i != val)
  else
    return [...list, val]
}
</script>

<style>
.form-check button { display: none; line-height: 1 }
.form-check:hover button { display: inline-block }

.form-check.excluded label { text-decoration: line-through }
</style>
