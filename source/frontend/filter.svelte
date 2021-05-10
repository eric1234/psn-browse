<div class="offcanvas offcanvas-end" tabindex="-1" id="filter" aria-labelledby="filter-header">
  <div class="offcanvas-header">
    <h5 class="offcanvas-title" id="filter-header">Filter</h5>
    <button type="button" class="btn-close text-reset" data-bs-dismiss="offcanvas" aria-label="Close"></button>
  </div>
  <div class="offcanvas-body">
    <Search bind:query={search.query} />
    <Sort bind:sort={search.sort} />
    <ReleaseYear bind:yearStart={search.yearStart} bind:yearEnd={search.yearEnd} {minYear} />

    {#each Object.entries(facets) as [category, facet]}
      <Category facet={facet} bind:filter={search.filters[category]} bind:excludes={search.excludes[category]} />
    {/each}
  </div>
</div>

<script>
export let search
export let minYear
export let facets

import Search from './filter/search.svelte'
import Sort from './filter/sort.svelte'
import ReleaseYear from './filter/release_year.svelte'
import Category from './filter/category.svelte'
</script>
