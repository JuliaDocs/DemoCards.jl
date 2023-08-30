const nocoverlist_section_template = mt"""
{{{description}}}

```@raw html
<div class="list-card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const nocoverlist_card_template = mt"""
```@raw html
<div class="list-card">
<table>
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

function cardtheme(::Val{:nocoverlist})
    templates = Dict(
        "card" => nocoverlist_card_template,
        "section" => nocoverlist_section_template
    )
    return templates, abspath(@__DIR__, "style.css")
end
