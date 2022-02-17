const bulma_grid_section_template = mt"""
{{{description}}}

```@raw html
<div class="columns is-multiline bulma-grid-card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const bulma_grid_card_template = mt"""
```@raw html
<div class="column is-half">
    <div class="card bulma-grid-card">
        <div class="card-content">
            <h3 class="is-size-5 bulma-grid-card-text">
                {{{title}}}
            </h3>
            <p class="is-size-6 bulma-grid-card-description">
                {{{description}}}
            </p>
        </div>
        <div class="card-image bulma-grid-card-cover">
```
[![card image]({{{coverpath}}})](@ref {{id}})
```@raw html
        </div>
    </div>
</div>
```
"""

function cardtheme(::Val{:bulmagrid})
    templates = Dict(
        "card" => bulma_grid_card_template,
        "section" => bulma_grid_section_template
    )
    return templates, abspath(@__DIR__, "style.css")
end
