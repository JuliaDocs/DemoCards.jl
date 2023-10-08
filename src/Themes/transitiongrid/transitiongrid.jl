const transition_grid_section_template = mt"""
{{{description}}}

```@raw html
<div class="transition-grid-card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const transition_grid_card_template = mt"""
```@raw html
<div class="card transition-grid-card">
<div class="transition-grid-card-cover" style="background-image: url({{{coverpath}}})">
<div class="transition-grid-card-description">
```
{{description}}
```@raw html
</div>
```
[](@ref {{id}})
```@raw html
</div>
<div class="transition-grid-card-text">
```

[{{title}}](@ref {{id}})

```@raw html
</div>
</div>
```

"""

function cardtheme(::Val{:transitiongrid})
    templates = Dict(
        "card" => transition_grid_card_template,
        "section" => transition_grid_section_template
    )
    return templates, abspath(@__DIR__, "style.css")
end
