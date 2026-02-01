#!/usr/bin/env bash

export POKE_START="<!--POKE_INFO_START-->"
export POKE_END="<!--POKE_INFO_END-->"

function generate_pokedex_entry() {
  local -n __poke_info__="$1"

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
    src="${__poke_info__[image]}"
  />
  <br>
  <span id="pokemon-name"><b>Release #${__poke_info__[release_number]}: ${__poke_info__[tag]} - ${__poke_info__[name]}</b></span>
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
  <table align="center">
    <tr>
      <th>Lang</th>
      <th>Lines of Code</th>
      <th>Unit Test Coverage</th>
      <th>Coverage Type</th>
    </tr>
    <tr>
      <td>Go</td>
      <td>${__poke_info__[go_loc]}</td>
      <td>${__poke_info__[go_unit_coverage]}</td>
      <td>Branch</td>
    </tr>
    <tr>
      <td>Rust</td>
      <td>${__poke_info__[rust_loc]}</td>
      <td>${__poke_info__[rust_unit_coverage]}</td>
      <td>Branch</td>
    </tr>
    <tr>
      <td>Bash</td>
      <td>${__poke_info__[bash_loc]}</td>
      <td>${__poke_info__[bash_unit_coverage]}</td>
      <td>Line</td>
    </tr>
  </table>
</div>
$POKE_END
EOF
}