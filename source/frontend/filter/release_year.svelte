<label class="form-label" for="release_date">Released On</label>
<div class="mx-3 mb-5" bind:this={range}></div>

<script>
export let yearStart
export let yearEnd
export let minYear

import { onMount } from 'svelte'

import slider from 'nouislider'
import 'nouislider/distribute/nouislider.css';

let range

const maxYear = new Date().getFullYear()
const intFormat = { to: String, from: parseInt }

onMount(()=> {
  slider.create(range, {
    start: [yearStart, yearEnd],
    step: 1,
    connect: true,
    format: intFormat,
    tooltips: [true, true],
    range: { min: minYear, max: maxYear },
    pips: {
      mode: 'positions',
      values: [0, 25, 50, 75, 100],
      density: 4,
    }
  })
  range.noUiSlider.on('set', values => [yearStart, yearEnd] = values)
})

$: if( range && range.noUiSlider ) range.noUiSlider.set([yearStart, yearEnd])
</script>
