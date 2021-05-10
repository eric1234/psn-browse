<div class="col mb-3">
  <div class="card">
    {#if cover}
      <img src="{imageUrl}" class="card-img-top">
    {/if}
    <div class="card-body">
      <h5 class="card-title text-truncate">{name}</h5>
      <a href="{id}.html" class="btn btn-primary d-block">View</a>
    </div>
  </div>
</div>

<script>
export let id, name, cover

$: imageUrl = `https://images.igdb.com/igdb/image/upload/t_cover_big/${cover}.jpg`
</script>
