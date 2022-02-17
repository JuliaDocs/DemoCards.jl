const grid_section_template = mt"""
{{{description}}}

```@raw html
<div class="grid-card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const grid_card_template = mt"""
```@raw html
<div class="card grid-card">
<div class="grid-card-cover">
<div class="grid-card-description">
```
{{description}}
```@raw html
</div>
```
[![card-cover-image]({{{coverpath}}})](@ref {{id}})
```@raw html
</div>
<div class="grid-card-text">
```

[{{title}}](@ref {{id}})

```@raw html
</div>
</div>
```

"""

function cardtheme(::Val{:grid})
    templates = Dict(
        "card" => grid_card_template,
        "section" => grid_section_template
    )
    return templates, abspath(@__DIR__, "style.css")
end
