<h5 class="mt-3">{facet.title}</h5>
<div>
  {#each facet.buckets as bucket (bucket.key)}
    {#if !excludes.includes(bucket.key)}
      <Option {bucket} bind:filter={filter} bind:excludes={excludes} />
    {/if}
  {/each}
  {#each excludes as excluded (excluded)}
    <Option bucket={{key: excluded, doc_count: 0}} bind:filter={filter} bind:excludes={excludes} />
  {/each}
</div>

<script>
import Option from './option.svelte'

export let facet
export let filter
export let excludes
</script>
