grid_section_template = mt"""
{{{description}}}

```@raw html
<div class="card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

grid_card_template = mt"""
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
    return (grid_card_template, grid_section_template), abspath(@__DIR__, "style.css")
end
