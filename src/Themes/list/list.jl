const list_section_template = mt"""
```@raw html
<div class="card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const list_card_template = mt"""
```@raw html
<div class="card">
<table>
  <td valign="bottom"><div class="card-cover">
```
[![card-cover-image](covers/{{covername}})](@ref {{id}})
```@raw html
  </div></td>
  <td><div class="card-text">
```
[{{{title}}}](@ref {{id}})
```@raw html
</div>
    <div class="card-description">
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
    return (list_card_template, list_section_template), abspath(@__DIR__, "style.css")
end
