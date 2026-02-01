#!/usr/bin/env bash

export POKE_START="<!--POKE_INFO_START-->"
export POKE_END="<!--POKE_INFO_END-->"

function generate_pokedex_entry() {
  cat <<EOF
$POKE_START
<div id="poke-info" align="center">
  <h3>
    If Kaitos' latest stable release was a Pokémon,
    <br>
    it would be...
  </h3>
  <img
    id="pokemon-img"
    src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/2.gif"
  />
  <br>
  <span id="pokemon-name"><b>Release #2: v0.0.2 - Ivysaur</b></span>
  <br>
  <img
    id="rust-runtime-coverage"
    src="https://img.shields.io/codecov/c/github/kernelle-soft/kaitos-toolchain?flag=rust&label=Runtime"
  />
  <img
    id="go-cli-coverage"
    src="https://img.shields.io/codecov/c/github/kernelle-soft/kaitos-toolchain?flag=go&label=CLI"
  />
  <br>
  <span>Base Stats</span>
  <table>
    <tr>
      <th>Lang</th>
      <th>Lines of Code</th>
      <th>Unit Test Coverage</th>
      <th>Coverage Type</th>
    </tr>
    <tr>
      <td>Go</td>
      <td>293</td>
      <td>11%</td>
      <td>Branch</td>
    </tr>
    <tr>
      <td>Rust</td>
      <td>31
      <td>11%</td>
      <td>Branch</td>
    </tr>
    <tr>
      <td>Bash</td>
      <td>2827</td>
      <td>0%</td>
      <td>Line</td>
    </tr>
  </table>
</div>
$POKE_END
EOF
}