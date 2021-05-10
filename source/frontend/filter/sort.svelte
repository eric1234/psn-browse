<label class="form-label" for="sort">Sort By</label>
<select class="form-select mb-3" id="sort" bind:value={sort}>
  <option value="rank">Rank</option>
  <option value="release_date">Release Date</option>
</select>

<script>
export let sort
</script>
