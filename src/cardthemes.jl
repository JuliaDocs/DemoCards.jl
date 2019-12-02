# TODO: we can manage themes like TestImages.jl

const card_section_template = mt"""
```@raw html
<div class="card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const card_template = mt"""
```@raw html
<div class="card">
<div class="card-img">
<p class="card-description">{{description}}</p>
```

[![svd](covers/{{name}}.png)](@ref {{id}})

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

const max_coversize = (220, 200)
const theme_minimal = """
.card-section {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  align-content: space-between;
}

.card:hover{
  box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.4), 0 6px 20px 0 rgba(0, 0, 0, 0.1);
}

.card {
    width: 210px;
    max-height: 400px;
    margin: 10px 15px;
    box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
    transition: 0.3s;
    border-radius: 5px;
}

.card-text {
    padding: 0 15px;
}

.card-img {
    width: $(max_coversize[2])px;
    height: $(max_coversize[1])px;
    padding: 5px;
    box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2);
    transition: 0.3s;
    border-radius: 5px;
    display:block;
    margin:auto;
}

.card-img .card-description {
    opacity: 0;
    position: absolute;
    top: 25%;
    left: 50%;
    width: 100%;
    transform: translate(-50%, -50%);
    padding: 10px;
    border-radius: 5px;
    background: rgba(0, 0, 0, 0.6);
    color: #fff;
    text-align: center;
    font-size: 18px;
    transition: all 0.3s ease-in-out 0s;
}

.card-img:hover .card-description{
    opacity: 1;
}

"""

function read_cardtheme(theme::AbstractString)
    if theme == "minimal"
        return theme_minimal
    else
        throw(ArgumentError("no theme $(theme) found."))
    end
end
