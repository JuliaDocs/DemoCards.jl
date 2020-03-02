const list_section_template = mt"""
{{{description}}}

```@raw html
<div class="list-card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const list_card_template = mt"""
```@raw html
<div class="list-card">
<table>
  <td valign="bottom"><div class="list-card-cover">
```
[![list-card-cover-image](covers/{{covername}})](@ref {{id}})
```@raw html
  </div></td>
  <td><div class="list-card-text">
```
[{{{title}}}](@ref {{id}})
```@raw html
</div>
    <div class="list-card-description">
```
{{{description}}}
```@raw html
    </div>
  </td>
</tbody></table>
</div>
```

"""

function cardtheme(::Val{:list})
    templates = Dict(
        "card" => list_card_template,
        "section" => list_section_template
    )
    return templates, abspath(@__DIR__, "style.css")
end
