# FIXME: if rename everything with "grid-" prefix, description won't show up correctly
const grid_section_template = mt"""
{{{description}}}

```@raw html
<div class="card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const grid_card_template = mt"""
```@raw html
<div class="card">
<div class="card-cover">
<div class="card-description">
```
{{description}}
```@raw html
</div>
```
[![card-cover-image](covers/{{covername}})](@ref {{id}})
```@raw html
</div>
<div class="card-text">
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
