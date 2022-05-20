const bokeh_list_section_template = mt"""
{{{description}}}

```@raw html
<div class="bokeh-list-card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const bokeh_list_card_template = mt"""
```@raw html
<div class="bokeh-list-card">
<table>
  <td valign="bottom"><div class="bokeh-list-card-cover">
```
[![bokeh-list-card-cover-image]({{{coverpath}}})](@ref {{id}})
```@raw html
  </div></td>
  <td><div class="bokeh-list-card-text">
```
[{{{title}}}](@ref {{id}})
```@raw html
</div>
    <div class="bokeh-list-card-description">
```
{{{description}}}
```@raw html
    </div>
  </td>
</tbody></table>
</div>
```

"""

function cardtheme(::Val{:bokehlist})
    templates = Dict(
        "card" => bokeh_list_card_template,
        "section" => bokeh_list_section_template
    )
    return templates, abspath(@__DIR__, "style.css")
end
